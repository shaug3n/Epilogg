import Foundation
import SwiftData

@MainActor
struct DiaryStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        context.autosaveEnabled = false
    }

    func saveProfile(_ draft: ProfileDraft, editing profile: UserProfile? = nil) throws {
        for medicine in draft.medications { try medicine.validate() }
        let profile = profile ?? UserProfile()
        if profile.modelContext == nil { context.insert(profile) }
        profile.preferredName = draft.preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.diagnosis = draft.diagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.triggers = NamedOptionCatalog.normalized(draft.triggers)
        profile.places = NamedOptionCatalog.normalized(draft.places)
        profile.warningSigns = draft.warningSigns.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.onboardingCompleted = true
        for draft in draft.medications {
            context.insert(medication(from: draft))
        }
        try commit()
    }

    func savePlaces(_ places: [String], for profile: UserProfile) throws {
        profile.places = NamedOptionCatalog.normalized(places)
        try commit()
    }

    @discardableResult
    func addMedication(_ draft: MedicationDraft) throws -> Medication {
        try draft.validate()
        let medicine = medication(from: draft)
        context.insert(medicine)
        try commit()
        return medicine
    }

    func endMedication(_ medicine: Medication, at date: Date = Date()) throws {
        guard date >= medicine.startedAt else { throw DiaryValidationError.medicationEndBeforeStart }
        guard date <= Date() else { throw DiaryValidationError.futureDate }
        medicine.endedAt = date
        try commit()
    }

    @discardableResult
    func saveSeizure(_ draft: SeizureDraft, editing record: SeizureRecord? = nil, now: Date = Date()) throws -> SeizureRecord {
        guard draft.occurredAt <= now else { throw DiaryValidationError.futureDate }
        let duration = try draft.validatedDuration()
        let medicines = try context.fetch(FetchDescriptor<Medication>())
        let newCustomTriggers = NamedOptionCatalog.normalized(draft.newCustomTriggers)
        let newPlaces = NamedOptionCatalog.normalized(draft.newPlaces)
        if !newCustomTriggers.isEmpty || !newPlaces.isEmpty,
           let profile = try context.fetch(FetchDescriptor<UserProfile>()).first {
            profile.triggers = NamedOptionCatalog.normalized(profile.triggers + newCustomTriggers)
            profile.places = NamedOptionCatalog.normalized((profile.places ?? []) + newPlaces)
        }
        let record = record ?? SeizureRecord()
        if record.modelContext == nil {
            record.medicationSnapshot = medicines
                .filter { $0.startedAt <= draft.occurredAt && ($0.endedAt == nil || $0.endedAt! > draft.occurredAt) }
                .sorted { $0.name < $1.name }
                .map(\.summary)
            context.insert(record)
        }
        record.occurredAt = draft.occurredAt
        record.type = draft.type
        record.durationSeconds = duration
        record.triggers = NamedOptionCatalog.normalized(draft.triggers)
        record.symptoms = Array(Set(draft.symptoms)).sorted()
        record.recovery = draft.recovery.trimmingCharacters(in: .whitespacesAndNewlines)
        record.injury = draft.injury
        record.rescueMedication = draft.rescueMedication.trimmingCharacters(in: .whitespacesAndNewlines)
        record.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        record.locationName = NamedOptionCatalog.normalize(draft.locationName)
        record.locationType = draft.environment == .unknown ? nil : draft.environment.rawValue
        try commit()
        return record
    }

    func deleteSeizure(_ record: SeizureRecord) throws {
        context.delete(record)
        try commit()
    }

    func deleteAll() throws {
        let seizures = try context.fetch(FetchDescriptor<SeizureRecord>())
        let medicines = try context.fetch(FetchDescriptor<Medication>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        seizures.forEach { context.delete($0) }
        medicines.forEach { context.delete($0) }
        profiles.forEach { context.delete($0) }
        try commit()
    }

    func exportData() throws -> Data {
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let medicines = try context.fetch(FetchDescriptor<Medication>(sortBy: [SortDescriptor(\.startedAt)]))
        let seizures = try context.fetch(FetchDescriptor<SeizureRecord>(sortBy: [SortDescriptor(\.occurredAt)]))
        let archive = DiaryArchive(
            profile: profiles.first.map(ProfileExport.init),
            medications: medicines.map(MedicationExport.init),
            seizures: seizures.map(SeizureExport.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(archive)
    }

    private func medication(from draft: MedicationDraft) -> Medication {
        Medication(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            dose: draft.dose.trimmingCharacters(in: .whitespacesAndNewlines),
            schedule: draft.schedule.trimmingCharacters(in: .whitespacesAndNewlines),
            startedAt: draft.startedAt
        )
    }

    private func commit() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
