import Foundation

struct DailyCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct TriggerCount: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

struct DiaryDateRange: Hashable {
    let startDate: Date
    let endDate: Date
    let endExclusiveDate: Date

    init(startDate: Date, endDate: Date, now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) throws {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { throw DiaryValidationError.invalidDateRange }
        guard end <= calendar.startOfDay(for: now) else { throw DiaryValidationError.futureDate }
        guard let endExclusive = calendar.date(byAdding: .day, value: 1, to: end) else {
            throw DiaryValidationError.invalidDateRange
        }
        self.startDate = start
        self.endDate = end
        endExclusiveDate = endExclusive
    }

    func dayCount(in calendar: Calendar = .autoupdatingCurrent) -> Int {
        (calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
    }
}

struct DiarySummary {
    let records: [SeizureRecord]
    let dailyCounts: [DailyCount]
    let triggerCounts: [TriggerCount]
    let averageDuration: Double?
    let knownDurationCount: Int
    let startDate: Date
    let endDate: Date
    let endExclusiveDate: Date

    init(records: [SeizureRecord], days: Int, type: SeizureType? = nil, now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) {
        precondition([7, 30, 90].contains(days), "Unsupported dashboard period")
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: today)!
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: today)!
        self.init(
            records: records,
            startDate: start,
            endDate: today,
            endExclusiveDate: endExclusive,
            dayCount: days,
            type: type,
            now: now,
            calendar: calendar
        )
    }

    init(records: [SeizureRecord], range: DiaryDateRange, type: SeizureType? = nil, now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) {
        self.init(
            records: records,
            startDate: range.startDate,
            endDate: range.endDate,
            endExclusiveDate: range.endExclusiveDate,
            dayCount: range.dayCount(in: calendar),
            type: type,
            now: now,
            calendar: calendar
        )
    }

    private init(records: [SeizureRecord], startDate: Date, endDate: Date, endExclusiveDate: Date, dayCount: Int, type: SeizureType?, now: Date, calendar: Calendar) {
        self.startDate = startDate
        self.endDate = endDate
        self.endExclusiveDate = endExclusiveDate
        let filtered = records.filter {
            $0.occurredAt >= startDate && $0.occurredAt < endExclusiveDate && $0.occurredAt <= now && (type == nil || $0.type == type)
        }.sorted { $0.occurredAt > $1.occurredAt }
        self.records = filtered
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.occurredAt) }
        dailyCounts = (0..<dayCount).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startDate)!
            return DailyCount(date: day, count: grouped[day]?.count ?? 0)
        }
        let durations = filtered.compactMap(\.durationSeconds)
        knownDurationCount = durations.count
        averageDuration = durations.isEmpty ? nil : durations.reduce(0, +) / Double(durations.count)
        var triggers: [String: Int] = [:]
        for record in filtered {
            for trigger in Set(record.triggers) {
                triggers[trigger, default: 0] += 1
            }
        }
        triggerCounts = triggers.map { TriggerCount(name: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }
}

enum DiaryFormat {
    static func duration(_ seconds: Double?) -> String {
        guard let seconds else { return "Ukjent varighet" }
        let total = Int(seconds.rounded())
        if total < 60 { return "\(total) sek" }
        let remainder = total % 60
        return remainder == 0 ? "\(total / 60) min" : "\(total / 60) min \(remainder) sek"
    }
}
