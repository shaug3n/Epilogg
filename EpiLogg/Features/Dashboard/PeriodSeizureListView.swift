import SwiftUI
import SwiftData

struct PeriodSeizureListView: View {
    @Query(sort: \SeizureRecord.occurredAt, order: .reverse) private var allRecords: [SeizureRecord]
    let range: DiaryDateRange
    let type: SeizureType?
    let selectedDay: Date?

    private var records: [SeizureRecord] {
        allRecords.filter { record in
            let matchesDay = selectedDay.map {
                Calendar.autoupdatingCurrent.isDate(record.occurredAt, inSameDayAs: $0)
            } ?? true
            return record.occurredAt >= range.startDate &&
                record.occurredAt < range.endExclusiveDate &&
                (type == nil || record.type == type) &&
                matchesDay
        }
    }

    private var byMonth: [(date: Date, records: [SeizureRecord])] {
        let calendar = Calendar.autoupdatingCurrent
        let grouped = Dictionary(grouping: records) {
            calendar.dateInterval(of: .month, for: $0.occurredAt)?.start ?? calendar.startOfDay(for: $0.occurredAt)
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0, default: []]) }
    }

    private var pageTitle: String {
        if let selectedDay {
            return selectedDay.formatted(.dateTime.day().month(.wide).year())
        }
        return "\(range.startDate.formatted(.dateTime.day().month(.abbreviated))) – \(range.endDate.formatted(.dateTime.day().month(.abbreviated).year()))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageTitle(
                    eyebrow: selectedDay == nil ? "Valgt periode · \(records.count) registreringer" : "Valgt dag · \(records.count) registreringer",
                    title: selectedDay == nil ? "Anfall i perioden" : "Anfall denne dagen",
                    subtitle: pageTitle
                )
                if let type {
                    Label("Typefilter: \(type.rawValue)", systemImage: "line.3.horizontal.decrease")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppStyle.accent)
                }
                if records.isEmpty {
                    Card {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(AppStyle.accent)
                            .frame(maxWidth: .infinity)
                        Text("Ingen registreringer i denne perioden")
                            .font(.headline)
                            .foregroundStyle(AppStyle.ink)
                            .frame(maxWidth: .infinity)
                        Text("Det betyr ikke nødvendigvis at dagene var anfallsfrie.")
                            .font(.subheadline)
                            .foregroundStyle(AppStyle.muted)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ForEach(byMonth, id: \.date) { month in
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: month.date.formatted(.dateTime.month(.wide).year()))
                            Card {
                                ForEach(month.records) { record in
                                    NavigationLink {
                                        SeizureDetailView(recordID: record.id)
                                    } label: {
                                        SeizureRow(record: record)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("seizure.row")
                                    if record.id != month.records.last?.id { Divider() }
                                }
                            }
                        }
                    }
                }
            }
            .padding(22)
            .padding(.bottom, 32)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(AppStyle.canvas)
    }
}
