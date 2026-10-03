import Foundation
import SwiftData

enum SeizureType: String, CaseIterable, Codable, Identifiable {
    case unknown = "Ukjent"
    case focal = "Fokalt"
    case generalized = "Generalisert"
    case absence = "Absens"
    case other = "Annen type"

    var id: String { rawValue }
}

enum SeizureEnvironment: String, CaseIterable, Identifiable {
    case unknown = "Ukjent"
    case indoors = "Inne"
    case outdoors = "Ute"

    var id: String { rawValue }
}

enum HealthOptions {
    static let diagnoses = [
        "Fokal epilepsi",
        "Generalisert epilepsi",
        "Kombinert generalisert og fokal epilepsi",
        "Ukjent / ikke avklart"
    ]
    static let triggers = ["Lite søvn", "Stress", "Glemt medisin", "Alkohol", "Sykdom", "Menstruasjon", "Lys / visuelle mønstre"]
    static let symptoms = ["Endret bevissthet", "Rykninger", "Stivhet", "Sanseopplevelser", "Forvirring"]
    static let places = ["Hjemme", "Jobb", "Skole"]
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var preferredName: String
    var diagnosis: String
    var triggers: [String]
    var places: [String]?
    var warningSigns: String
    var notes: String
    var onboardingCompleted: Bool
    var createdAt: Date

    init(preferredName: String = "", diagnosis: String = "", triggers: [String] = [], warningSigns: String = "", notes: String = "") {
        id = UUID()
        self.preferredName = preferredName
        self.diagnosis = diagnosis
        self.triggers = triggers
        places = []
        self.warningSigns = warningSigns
        self.notes = notes
        onboardingCompleted = true
        createdAt = Date()
    }
}

@Model
final class Medication {
    @Attribute(.unique) var id: UUID
    var name: String
    var dose: String
    var schedule: String
    var startedAt: Date
    var endedAt: Date?

    var isActive: Bool { endedAt == nil }
    var summary: String { dose.isEmpty ? name : "\(name) · \(dose)" }

    init(name: String, dose: String = "", schedule: String = "", startedAt: Date = Date()) {
        id = UUID()
        self.name = name
        self.dose = dose
        self.schedule = schedule
        self.startedAt = startedAt
    }
}

@Model
final class SeizureRecord {
    @Attribute(.unique) var id: UUID
    var occurredAt: Date
    var type: SeizureType
    var durationSeconds: Double?
    var triggers: [String]
    var symptoms: [String]
    var recovery: String
    var injury: Bool
    var rescueMedication: String
    var notes: String
    var locationName: String?
    var locationType: String?
    var medicationSnapshot: [String]
    var createdAt: Date

    init(occurredAt: Date = Date(), type: SeizureType = .unknown, durationSeconds: Double? = nil, triggers: [String] = []) {
        id = UUID()
        self.occurredAt = occurredAt
        self.type = type
        self.durationSeconds = durationSeconds
        self.triggers = triggers
        symptoms = []
        recovery = ""
        injury = false
        rescueMedication = ""
        notes = ""
        locationName = nil
        locationType = nil
        medicationSnapshot = []
        createdAt = Date()
    }
}
