import XCTest
import SwiftData
@testable import EpiLogg

@MainActor
final class DiaryTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        return calendar
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    func testUnknownDurationIsNilNotZero() throws {
        let draft = SeizureDraft(occurredAt: date("2026-10-03T10:00:00Z"))
        XCTAssertNil(try draft.validatedDuration())
    }

    func testKnownDurationCombinesMinutesAndSeconds() throws {
        var draft = SeizureDraft()
        draft.durationKnown = true
        draft.minutes = "2"
        draft.seconds = "15"
        XCTAssertEqual(try draft.validatedDuration(), 135)
    }

    func testInvalidDurationsAreRejected() {
        for (minutes, seconds) in [("0", "0"), ("-1", "0"), ("1", "60"), ("abc", "0"), ("1.5", "0")] {
            var draft = SeizureDraft()
            draft.durationKnown = true
            draft.minutes = minutes
            draft.seconds = seconds
            XCTAssertThrowsError(try draft.validatedDuration(), "\(minutes):\(seconds)")
        }
    }

    func testFutureSeizureIsRejectedWithoutInsertingRecord() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        let now = date("2026-10-03T10:00:00Z")
        let draft = SeizureDraft(occurredAt: now.addingTimeInterval(60))
        XCTAssertThrowsError(try store.saveSeizure(draft, now: now))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeizureRecord>()), 0)
    }

    func testOptionalOnboardingPersistsAndCompletes() throws {
        let container = try LocalStore.makeContainer(inMemory: true)
        let store = DiaryStore(context: ModelContext(container))
        try store.saveProfile(ProfileDraft())
        let profiles = try ModelContext(container).fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertTrue(profiles[0].onboardingCompleted)
        XCTAssertEqual(profiles[0].diagnosis, "")
    }

    func testBlankMedicineNameIsRejectedWithoutSavingProfile() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        var draft = ProfileDraft()
        draft.medications = [MedicationDraft(name: "   ")]
        XCTAssertThrowsError(try DiaryStore(context: context).saveProfile(draft))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UserProfile>()), 0)
    }

    func testSeizureCanBeSavedEditedAndDeleted() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        var draft = SeizureDraft(occurredAt: date("2026-10-03T10:00:00Z"))
        let record = try store.saveSeizure(draft, now: date("2026-10-03T12:00:00Z"))
        XCTAssertNil(record.durationSeconds)
        draft.notes = "Etter hvile"
        draft.type = .focal
        try store.saveSeizure(draft, editing: record, now: date("2026-10-03T12:00:00Z"))
        let records = try context.fetch(FetchDescriptor<SeizureRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].notes, "Etter hvile")
        XCTAssertEqual(records[0].type, .focal)
        try store.deleteSeizure(record)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeizureRecord>()), 0)
    }

    func testMedicationHistoryAndSeizureSnapshotArePreserved() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        let start = date("2026-10-01T10:00:00Z")
        let end = date("2026-10-02T10:00:00Z")
        let medicine = try store.addMedication(MedicationDraft(name: "Registrert medisin", dose: "100 mg", startedAt: start))
        let record = try store.saveSeizure(SeizureDraft(occurredAt: start), now: end)
        try store.endMedication(medicine, at: end)
        XCTAssertFalse(medicine.isActive)
        XCTAssertEqual(record.medicationSnapshot, ["Registrert medisin · 100 mg"])
        var edited = SeizureDraft(record: record)
        edited.notes = "Oppdatert notat"
        try store.saveSeizure(edited, editing: record, now: end)
        XCTAssertEqual(record.medicationSnapshot, ["Registrert medisin · 100 mg"])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Medication>()), 1)
    }

    func testSevenDayRangeIncludesTodayAndExcludesOlderOrFutureRecords() {
        let now = date("2026-10-03T12:00:00Z")
        let records = [
            SeizureRecord(occurredAt: date("2026-09-27T08:00:00Z")),
            SeizureRecord(occurredAt: date("2026-10-03T11:00:00Z")),
            SeizureRecord(occurredAt: date("2026-09-26T20:00:00Z")),
            SeizureRecord(occurredAt: date("2026-10-03T13:00:00Z"))
        ]
        let summary = DiarySummary(records: records, days: 7, now: now, calendar: calendar)
        XCTAssertEqual(summary.records.count, 2)
        XCTAssertEqual(summary.dailyCounts.count, 7)
        XCTAssertEqual(summary.dailyCounts.map(\.count).reduce(0, +), 2)
    }

    func testDateBucketsFollowCalendarAcrossDaylightSaving() {
        let now = date("2026-03-30T12:00:00Z")
        let summary = DiarySummary(records: [], days: 7, now: now, calendar: calendar)
        XCTAssertEqual(summary.dailyCounts.count, 7)
        XCTAssertEqual(Set(summary.dailyCounts.map(\.date)).count, 7)
        XCTAssertTrue(summary.dailyCounts.allSatisfy { calendar.component(.hour, from: $0.date) == 0 })
    }

    func testTypeFilterAppliesToAllStatistics() {
        let now = date("2026-10-03T12:00:00Z")
        let focal = SeizureRecord(occurredAt: now, type: .focal, triggers: ["Stress"])
        let unknown = SeizureRecord(occurredAt: now, type: .unknown, triggers: ["Lite søvn"])
        let summary = DiarySummary(records: [focal, unknown], days: 30, type: .focal, now: now, calendar: calendar)
        XCTAssertEqual(summary.records.count, 1)
        XCTAssertEqual(summary.triggerCounts.map(\.name), ["Stress"])
        XCTAssertEqual(summary.dailyCounts.map(\.count).reduce(0, +), 1)
    }

    func testAverageDurationExcludesUnknownDurations() {
        let now = date("2026-10-03T12:00:00Z")
        let records = [
            SeizureRecord(occurredAt: now, durationSeconds: nil),
            SeizureRecord(occurredAt: now, durationSeconds: 60),
            SeizureRecord(occurredAt: now, durationSeconds: 120)
        ]
        let summary = DiarySummary(records: records, days: 7, now: now, calendar: calendar)
        XCTAssertEqual(summary.averageDuration, 90)
        XCTAssertEqual(summary.knownDurationCount, 2)
    }

    func testEmptySummaryHasNoInventedStatistics() {
        let summary = DiarySummary(records: [], days: 90)
        XCTAssertNil(summary.averageDuration)
        XCTAssertTrue(summary.triggerCounts.isEmpty)
        XCTAssertEqual(summary.dailyCounts.count, 90)
    }

    func testTriggerIsCountedOnlyOncePerRecord() {
        let now = date("2026-10-03T12:00:00Z")
        let record = SeizureRecord(occurredAt: now, triggers: ["Stress", "Stress"])
        let summary = DiarySummary(records: [record], days: 7, now: now)
        XCTAssertEqual(summary.triggerCounts.first?.count, 1)
    }

    func testTriggerCatalogTrimsAndDeduplicatesCaseInsensitively() {
        XCTAssertEqual(
            NamedOptionCatalog.normalized(["  Lite søvn ", "Stress", "stress", "", "   ", "Skjermtid"]),
            ["Lite søvn", "Stress", "Skjermtid"]
        )
        XCTAssertNil(NamedOptionCatalog.normalize(" \n "))
    }

    func testNewCustomTriggerIsSavedToProfileAndSeizure() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        try store.saveProfile(ProfileDraft())
        var draft = SeizureDraft(occurredAt: date("2026-10-03T10:00:00Z"))
        draft.triggers = ["Nattarbeid"]
        draft.newCustomTriggers = [" Nattarbeid ", "nattarbeid"]
        let record = try store.saveSeizure(draft, now: date("2026-10-03T12:00:00Z"))
        XCTAssertEqual(record.triggers, ["Nattarbeid"])
        XCTAssertEqual(try XCTUnwrap(context.fetch(FetchDescriptor<UserProfile>()).first).triggers, ["Nattarbeid"])
    }

    func testLocationPersistsThroughEditAndIsIncludedInExport() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        var draft = SeizureDraft(occurredAt: date("2026-10-03T10:00:00Z"))
        draft.locationName = "  Stua  "
        draft.environment = .indoors
        let record = try store.saveSeizure(draft, now: date("2026-10-03T12:00:00Z"))
        XCTAssertEqual(record.locationName, "Stua")
        XCTAssertEqual(record.locationType, SeizureEnvironment.indoors.rawValue)
        var edited = SeizureDraft(record: record)
        XCTAssertEqual(edited.locationName, "Stua")
        XCTAssertEqual(edited.environment, .indoors)
        edited.environment = .outdoors
        try store.saveSeizure(edited, editing: record, now: date("2026-10-03T12:00:00Z"))
        XCTAssertEqual(record.locationType, SeizureEnvironment.outdoors.rawValue)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: store.exportData()) as? [String: Any])
        let seizures = try XCTUnwrap(root["seizures"] as? [[String: Any]])
        XCTAssertEqual(seizures[0]["locationName"] as? String, "Stua")
        XCTAssertEqual(seizures[0]["locationType"] as? String, "Ute")
    }

    func testUnknownLocationRemainsUnspecifiedRatherThanInvented() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let record = try DiaryStore(context: context).saveSeizure(SeizureDraft())
        XCTAssertNil(record.locationName)
        XCTAssertNil(record.locationType)
        XCTAssertEqual(SeizureDraft(record: record).environment, .unknown)
    }

    func testCustomRangeIncludesBothFullCalendarDaysAndTypeFilter() throws {
        let now = date("2026-10-10T12:00:00Z")
        let range = try DiaryDateRange(
            startDate: date("2026-10-02T17:00:00Z"),
            endDate: date("2026-10-04T08:00:00Z"),
            now: now,
            calendar: calendar
        )
        let records = [
            SeizureRecord(occurredAt: date("2026-10-01T21:59:00Z"), type: .focal),
            SeizureRecord(occurredAt: date("2026-10-01T22:00:00Z"), type: .focal),
            SeizureRecord(occurredAt: date("2026-10-04T21:59:59Z"), type: .focal),
            SeizureRecord(occurredAt: date("2026-10-04T22:00:00Z"), type: .focal),
            SeizureRecord(occurredAt: date("2026-10-03T11:00:00Z"), type: .unknown)
        ]
        let summary = DiarySummary(records: records, range: range, type: .focal, now: now, calendar: calendar)
        XCTAssertEqual(summary.records.map(\.occurredAt), [
            date("2026-10-04T21:59:59Z"),
            date("2026-10-01T22:00:00Z")
        ])
        XCTAssertEqual(summary.dailyCounts.count, 3)
        XCTAssertEqual(summary.dailyCounts.map(\.count), [1, 0, 1])
        XCTAssertEqual(summary.dailyCounts.map(\.count).reduce(0, +), summary.records.count)
    }

    func testCustomRangeRejectsReversedOrFutureDates() {
        let now = date("2026-10-03T10:00:00Z")
        XCTAssertThrowsError(try DiaryDateRange(
            startDate: date("2026-10-02T00:00:00Z"),
            endDate: date("2026-10-01T00:00:00Z"),
            now: now,
            calendar: calendar
        ))
        XCTAssertThrowsError(try DiaryDateRange(
            startDate: date("2026-10-02T00:00:00Z"),
            endDate: date("2026-10-04T00:00:00Z"),
            now: now,
            calendar: calendar
        ))
    }

    func testCustomRangeUsesCalendarDaysAcrossDaylightSaving() throws {
        let range = try DiaryDateRange(
            startDate: date("2026-03-28T12:00:00Z"),
            endDate: date("2026-03-30T12:00:00Z"),
            now: date("2026-03-30T12:00:00Z"),
            calendar: calendar
        )
        XCTAssertEqual(range.dayCount(in: calendar), 3)
        XCTAssertEqual(range.endExclusiveDate.timeIntervalSince(range.startDate), 71 * 60 * 60)
    }

    func testOneDayCustomRangeCreatesSingleDayBucket() throws {
        let now = date("2026-10-10T12:00:00Z")
        let range = try DiaryDateRange(
            startDate: date("2026-10-10T04:00:00Z"),
            endDate: date("2026-10-10T08:00:00Z"),
            now: now,
            calendar: calendar
        )
        let record = SeizureRecord(occurredAt: date("2026-10-09T22:00:00Z"))
        let summary = DiarySummary(records: [record], range: range, now: now, calendar: calendar)
        XCTAssertEqual(range.dayCount(in: calendar), 1)
        XCTAssertEqual(summary.dailyCounts.count, 1)
        XCTAssertEqual(summary.dailyCounts[0].count, 1)
        XCTAssertEqual(summary.records.count, 1)
    }

    func testExportContainsProfileMedicinesAndUnknownDuration() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        try store.saveProfile(ProfileDraft())
        try store.addMedication(MedicationDraft(name: "Min medisin"))
        try store.saveSeizure(SeizureDraft())
        let data = try store.exportData()
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(root["schemaVersion"] as? Int, 1)
        XCTAssertNotNil(root["profile"])
        XCTAssertEqual((root["medications"] as? [[String: Any]])?.count, 1)
        let records = try XCTUnwrap(root["seizures"] as? [[String: Any]])
        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(records[0]["durationSeconds"] is NSNull)
        XCTAssertTrue(records[0]["locationName"] is NSNull)
        XCTAssertTrue(records[0]["locationType"] is NSNull)
    }

    func testDeleteAllRemovesEveryModel() throws {
        let context = ModelContext(try LocalStore.makeContainer(inMemory: true))
        let store = DiaryStore(context: context)
        try store.saveProfile(ProfileDraft())
        try store.addMedication(MedicationDraft(name: "Min medisin"))
        try store.saveSeizure(SeizureDraft())
        try store.deleteAll()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UserProfile>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Medication>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SeizureRecord>()), 0)
    }

    func testDiskStoreSurvivesContainerRecreation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        do {
            let container = try LocalStore.makeContainer(url: url)
            try DiaryStore(context: ModelContext(container)).saveProfile(ProfileDraft())
        }
        let reopened = try LocalStore.makeContainer(url: url)
        let profiles = try ModelContext(reopened).fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertTrue(profiles[0].onboardingCompleted)
    }
}
