import Foundation

enum DiaryValidationError: LocalizedError {
    case invalidDuration
    case futureDate
    case invalidDateRange
    case medicationNameRequired
    case medicationEndBeforeStart

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Oppgi hele minutter og sekunder fra 0 til 59. Varigheten må være mer enn 0 sekunder, eller velg ukjent varighet."
        case .futureDate:
            return "Tidspunktet kan ikke være i fremtiden."
        case .invalidDateRange:
            return "Sluttdatoen må være samme dag som eller etter startdatoen."
        case .medicationNameRequired:
            return "Skriv navnet på medisinen, eller fjern den tomme medisinen."
        case .medicationEndBeforeStart:
            return "Sluttdatoen kan ikke være før startdatoen."
        }
    }
}

struct MedicationDraft: Identifiable {
    var id = UUID()
    var name = ""
    var dose = ""
    var schedule = ""
    var startedAt = Date()

    func validate(now: Date = Date()) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DiaryValidationError.medicationNameRequired
        }
        guard startedAt <= now else { throw DiaryValidationError.futureDate }
    }
}

struct ProfileDraft {
    var preferredName = ""
    var diagnosis = ""
    var triggers: [String] = []
    var places: [String] = []
    var warningSigns = ""
    var notes = ""
    var medications: [MedicationDraft] = []

    init() {}

    init(profile: UserProfile) {
        preferredName = profile.preferredName
        diagnosis = profile.diagnosis
        triggers = profile.triggers
        places = profile.places ?? []
        warningSigns = profile.warningSigns
        notes = profile.notes
    }
}

struct SeizureDraft {
    var occurredAt = Date()
    var type: SeizureType = .unknown
    var durationKnown = false
    var minutes = ""
    var seconds = ""
    var triggers: [String] = []
    var symptoms: [String] = []
    var recovery = ""
    var injury = false
    var rescueMedication = ""
    var notes = ""
    var locationName = ""
    var environment: SeizureEnvironment = .unknown
    var newCustomTriggers: [String] = []
    var newPlaces: [String] = []

    init(occurredAt: Date = Date()) {
        self.occurredAt = occurredAt
    }

    init(record: SeizureRecord) {
        occurredAt = record.occurredAt
        type = record.type
        if let duration = record.durationSeconds {
            durationKnown = true
            minutes = String(Int(duration) / 60)
            seconds = String(Int(duration) % 60)
        }
        triggers = record.triggers
        symptoms = record.symptoms
        recovery = record.recovery
        injury = record.injury
        rescueMedication = record.rescueMedication
        notes = record.notes
        locationName = record.locationName ?? ""
        environment = record.locationType.flatMap(SeizureEnvironment.init(rawValue:)) ?? .unknown
    }

    func validatedDuration() throws -> Double? {
        guard durationKnown else { return nil }
        let minuteText = minutes.trimmingCharacters(in: .whitespaces)
        let secondText = seconds.trimmingCharacters(in: .whitespaces)
        guard let minuteValue = Int(minuteText.isEmpty ? "0" : minuteText),
              let secondValue = Int(secondText.isEmpty ? "0" : secondText),
              minuteValue >= 0, (0...59).contains(secondValue) else {
            throw DiaryValidationError.invalidDuration
        }
        let duration = Double(minuteValue) * 60 + Double(secondValue)
        guard duration > 0, duration.isFinite, duration <= Double(Int.max) else {
            throw DiaryValidationError.invalidDuration
        }
        return duration
    }
}
