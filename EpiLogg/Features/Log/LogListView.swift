import SwiftUI
import SwiftData

struct LogListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SeizureRecord.occurredAt, order: .reverse) private var records: [SeizureRecord]
    @State private var showingLogger = false

    private var byMonth: [(date: Date, records: [SeizureRecord])] {
        let calendar = Calendar.autoupdatingCurrent
        let grouped = Dictionary(grouping: records) { calendar.dateInterval(of: .month, for: $0.occurredAt)?.start ?? calendar.startOfDay(for: $0.occurredAt) }
        return grouped.keys.sorted(by: >).map { date in
            (date, grouped[date, default: []].sorted { $0.occurredAt > $1.occurredAt })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageTitle(eyebrow: "Din dagbok", title: "Anfallslogg", subtitle: "Observasjonene dine, sortert etter dato.")
                    if records.isEmpty {
                        Card {
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundStyle(AppStyle.accent)
                                .frame(maxWidth: .infinity)
                            Text("Loggen din starter her")
                                .font(.headline)
                                .foregroundStyle(AppStyle.ink)
                                .frame(maxWidth: .infinity)
                            Text("Når det passer for deg, registrer en observasjon. Du kan gjøre det med én gang eller fylle inn detaljer senere.")
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
                                        NavigationLink(value: record.id) {
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
                    Text("En manglende registrering betyr ikke nødvendigvis en anfallsfri dag.")
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(AppStyle.canvas)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLogger = true
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Registrer et anfall")
                    .accessibilityIdentifier("seizure.add")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                SeizureDetailView(recordID: id)
            }
            .sheet(isPresented: $showingLogger) {
                SeizureFormView()
            }
        }
    }
}
