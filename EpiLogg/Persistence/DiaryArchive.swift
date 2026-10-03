import Foundation

struct DiaryArchive: Encodable {
    let schemaVersion = 1
    let exportedAt = Date()
    let profile: ProfileExport?
    let medications: [MedicationExport]
    let seizures: [SeizureExport]
}

struct ProfileExport: Encodable {
    let id: UUID
    let preferredName: String
    let diagnosis: String
    let triggers: [String]
    let places: [String]
    let warningSigns: String
    let notes: String
    let createdAt: Date

    init(_ profile: UserProfile) {
        id = profile.id
        preferredName = profile.preferredName
        diagnosis = profile.diagnosis
        triggers = profile.triggers
        places = profile.places ?? []
        warningSigns = profile.warningSigns
        notes = profile.notes
        createdAt = profile.createdAt
    }
}

struct MedicationExport: Encodable {
    let id: UUID
    let name: String
    let dose: String
    let schedule: String
    let startedAt: Date
    let endedAt: Date?

    init(_ medication: Medication) {
        id = medication.id
        name = medication.name
        dose = medication.dose
        schedule = medication.schedule
        startedAt = medication.startedAt
        endedAt = medication.endedAt
    }
}

struct SeizureExport: Encodable {
    let id: UUID
    let occurredAt: Date
    let type: SeizureType
    let durationSeconds: Double?
    let triggers: [String]
    let symptoms: [String]
    let recovery: String
    let injury: Bool
    let rescueMedication: String
    let notes: String
    let locationName: String?
    let locationType: String?
    let medicationSnapshot: [String]
    let createdAt: Date

    init(_ record: SeizureRecord) {
        id = record.id
        occurredAt = record.occurredAt
        type = record.type
        durationSeconds = record.durationSeconds
        triggers = record.triggers
        symptoms = record.symptoms
        recovery = record.recovery
        injury = record.injury
        rescueMedication = record.rescueMedication
        notes = record.notes
        locationName = record.locationName
        locationType = record.locationType
        medicationSnapshot = record.medicationSnapshot
        createdAt = record.createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, occurredAt, type, durationSeconds, triggers, symptoms
        case recovery, injury, rescueMedication, notes, locationName, locationType, medicationSnapshot, createdAt
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(occurredAt, forKey: .occurredAt)
        try values.encode(type, forKey: .type)
        try values.encode(durationSeconds, forKey: .durationSeconds)
        try values.encode(triggers, forKey: .triggers)
        try values.encode(symptoms, forKey: .symptoms)
        try values.encode(recovery, forKey: .recovery)
        try values.encode(injury, forKey: .injury)
        try values.encode(rescueMedication, forKey: .rescueMedication)
        try values.encode(notes, forKey: .notes)
        try values.encode(locationName, forKey: .locationName)
        try values.encode(locationType, forKey: .locationType)
        try values.encode(medicationSnapshot, forKey: .medicationSnapshot)
        try values.encode(createdAt, forKey: .createdAt)
    }
}
