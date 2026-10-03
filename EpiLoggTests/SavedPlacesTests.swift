import XCTest
import SwiftData
@testable import EpiLogg

@MainActor
final class SavedPlacesTests: XCTestCase {
    func testOnboardingPlacesAreNormalizedAndExported() throws {
        let container = try LocalStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        var draft = ProfileDraft()
        draft.places = [" Hjemme ", "hjemme", "Jobb", "", "  ", "Hos familie"]
        try DiaryStore(context: context).saveProfile(draft)

        let profile = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<UserProfile>()).first)
        XCTAssertEqual(profile.places, ["Hjemme", "Jobb", "Hos familie"])
        XCTAssertEqual(ProfileDraft(profile: profile).places, ["Hjemme", "Jobb", "Hos familie"])
        let root = try XCTUnwrap(
            JSONSerialization.jsonObject(with: DiaryStore(context: context).exportData()) as? [String: Any]
        )
        let exported = try XCTUnwrap(root["profile"] as? [String: Any])
        XCTAssertEqual(exported["places"] as? [String], ["Hjemme", "Jobb", "Hos familie"])
    }

    func testNewPlaceIsSavedWithSeizureWithoutDuplicatingExistingPlace() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        var profile = ProfileDraft()
        profile.places = ["Hjemme"]
        try store.saveProfile(profile)
        var draft = SeizureDraft()
        draft.locationName = "  Parken "
        draft.newPlaces = ["Parken", " parken ", "hjemme"]
        draft.environment = .outdoors
        let record = try store.saveSeizure(draft)

        XCTAssertEqual(record.locationName, "Parken")
        XCTAssertEqual(record.locationType, "Ute")
        XCTAssertEqual(try context.fetch(FetchDescriptor<UserProfile>()).first?.places, ["Hjemme", "Parken"])
    }

    func testInvalidSeizureDoesNotSaveNewPlace() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        try store.saveProfile(ProfileDraft())
        let now = Date()
        var draft = SeizureDraft(occurredAt: now.addingTimeInterval(60))
        draft.newPlaces = ["Skole"]
        XCTAssertThrowsError(try store.saveSeizure(draft, now: now))
        XCTAssertEqual(try context.fetch(FetchDescriptor<UserProfile>()).first?.places, [])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeizureRecord>()), 0)
    }

    func testRemovingSavedPlaceDoesNotChangeHistoricLocation() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        var profileDraft = ProfileDraft()
        profileDraft.places = ["Hjemme", "Jobb"]
        try store.saveProfile(profileDraft)
        var seizureDraft = SeizureDraft()
        seizureDraft.locationName = "Jobb"
        seizureDraft.environment = .indoors
        let record = try store.saveSeizure(seizureDraft)
        let profile = try XCTUnwrap(context.fetch(FetchDescriptor<UserProfile>()).first)
        try store.savePlaces(["Hjemme"], for: profile)

        XCTAssertEqual(profile.places, ["Hjemme"])
        XCTAssertEqual(record.locationName, "Jobb")
        XCTAssertEqual(record.locationType, "Inne")
        var edited = SeizureDraft(record: record)
        edited.notes = "Et notat"
        try store.saveSeizure(edited, editing: record)
        XCTAssertEqual(record.locationName, "Jobb")
        XCTAssertEqual(profile.places, ["Hjemme"])
    }

    func testSavingPlacesPreservesOtherProfileFields() throws {
        let container = try LocalStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let store = DiaryStore(context: context)
        var draft = ProfileDraft()
        draft.preferredName = "Ola"
        draft.diagnosis = "Fokal epilepsi"
        draft.triggers = ["Stress"]
        draft.warningSigns = "Aura"
        draft.notes = "Eksisterende opplysninger"
        try store.saveProfile(draft)
        let profile = try XCTUnwrap(context.fetch(FetchDescriptor<UserProfile>()).first)

        try store.savePlaces([" Jobb ", "jobb", "", "Hjemme"], for: profile)

        let saved = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<UserProfile>()).first)
        XCTAssertEqual(saved.places, ["Jobb", "Hjemme"])
        XCTAssertEqual(saved.preferredName, "Ola")
        XCTAssertEqual(saved.diagnosis, "Fokal epilepsi")
        XCTAssertEqual(saved.triggers, ["Stress"])
        XCTAssertEqual(saved.warningSigns, "Aura")
        XCTAssertEqual(saved.notes, "Eksisterende opplysninger")
        XCTAssertTrue(saved.onboardingCompleted)
    }

    func testSavedPlacesDoNotPreselectPlaceOrEnvironmentForNewSeizure() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        var profile = ProfileDraft()
        profile.places = ["Hjemme", "Skole"]
        let store = DiaryStore(context: context)
        try store.saveProfile(profile)
        let record = try store.saveSeizure(SeizureDraft())
        XCTAssertNil(record.locationName)
        XCTAssertNil(record.locationType)
    }

    func testExistingStoreMigratesWithoutLosingProfileOrHistoricPlace() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.store")
        let profileID: UUID
        let recordID: UUID
        do {
            let oldSchema = Schema([BeforeSavedPlaces.UserProfile.self, Medication.self, SeizureRecord.self])
            let configuration = ModelConfiguration(schema: oldSchema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: oldSchema, configurations: [configuration])
            let context = ModelContext(container)
            let profile = BeforeSavedPlaces.UserProfile()
            let record = SeizureRecord()
            record.locationName = "Tidligere sted"
            record.locationType = "Inne"
            profileID = profile.id
            recordID = record.id
            context.insert(profile)
            context.insert(record)
            try context.save()
        }
        let upgraded = try LocalStore.makeContainer(url: url)
        let context = ModelContext(upgraded)
        let profile = try XCTUnwrap(context.fetch(FetchDescriptor<UserProfile>()).first)
        let record = try XCTUnwrap(context.fetch(FetchDescriptor<SeizureRecord>()).first)
        XCTAssertEqual(profile.id, profileID)
        XCTAssertEqual(profile.preferredName, "Eksisterende bruker")
        XCTAssertTrue(profile.onboardingCompleted)
        XCTAssertEqual(ProfileDraft(profile: profile).places, [])
        XCTAssertEqual(record.id, recordID)
        XCTAssertEqual(record.locationName, "Tidligere sted")
        XCTAssertEqual(record.locationType, "Inne")
        var draft = ProfileDraft(profile: profile)
        draft.places = ["Hjemme"]
        try DiaryStore(context: context).saveProfile(draft, editing: profile)
        XCTAssertEqual(profile.places, ["Hjemme"])
        XCTAssertEqual(record.locationName, "Tidligere sted")
    }
}

private enum BeforeSavedPlaces {
    @Model
    final class UserProfile {
        @Attribute(.unique) var id: UUID
        var preferredName: String
        var diagnosis: String
        var triggers: [String]
        var warningSigns: String
        var notes: String
        var onboardingCompleted: Bool
        var createdAt: Date

        init() {
            id = UUID()
            preferredName = "Eksisterende bruker"
            diagnosis = "Fokal epilepsi"
            triggers = ["Stress"]
            warningSigns = ""
            notes = ""
            onboardingCompleted = true
            createdAt = Date()
        }
    }
}
