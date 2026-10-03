import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \SeizureRecord.occurredAt, order: .reverse) private var allRecords: [SeizureRecord]
    @Query private var profiles: [UserProfile]
    @Query(sort: \Medication.startedAt, order: .reverse) private var medications: [Medication]
    @State private var days = 30
    @State private var customPeriod: DiaryDateRange?
    @State private var showingRangePicker = false
    @State private var showingPeriodList = false
    @State private var periodListRange: DiaryDateRange?
    @State private var periodListType: SeizureType?
    @State private var periodListDay: Date?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedType: SeizureType?
    @State private var selectedDate: Date?
    @State private var showingLogger = false

    private var summary: DiarySummary {
        if let customPeriod {
            return DiarySummary(records: allRecords, range: customPeriod, type: selectedType)
        }
        return DiarySummary(records: allRecords, days: days, type: selectedType)
    }

    private var periodLabel: String {
        guard let customPeriod else { return "Siste \(days) dager" }
        let start = customPeriod.startDate.formatted(.dateTime.day().month(.abbreviated))
        let end = customPeriod.endDate.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(start) – \(end)"
    }

    private var chartDateDomain: ClosedRange<Date> {
        let calendar = Calendar.autoupdatingCurrent
        guard calendar.isDate(summary.startDate, inSameDayAs: summary.endDate) else {
            return summary.startDate...summary.endDate
        }
        let lower = calendar.date(byAdding: .hour, value: -12, to: summary.startDate)
            ?? summary.startDate.addingTimeInterval(-12 * 60 * 60)
        let upper = calendar.date(byAdding: .hour, value: 12, to: summary.endDate)
            ?? summary.endDate.addingTimeInterval(12 * 60 * 60)
        return lower...upper
    }

    private var greeting: String {
        let name = profiles.first?.preferredName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Hei, godt å se deg." : "Hei, \(name)."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                quickLogCard
                periodSelector
                chartCard
                if !summary.records.isEmpty {
                    overviewCard
                    if !summary.triggerCounts.isEmpty { triggerCard }
                    recentCard
                }
                medicationCard
                disclaimer
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 30)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(AppStyle.canvas)
        .sheet(isPresented: $showingLogger) {
            SeizureFormView()
        }
        .sheet(isPresented: $showingRangePicker) {
            let start = customPeriod?.startDate ?? Calendar.autoupdatingCurrent.date(byAdding: .day, value: -29, to: Calendar.autoupdatingCurrent.startOfDay(for: .now)) ?? .now
            let end = customPeriod?.endDate ?? .now
            DateRangePickerView(startDate: start, endDate: end, onApply: applyRange)
        }
        .navigationDestination(isPresented: $showingPeriodList) {
            if let periodListRange {
                PeriodSeizureListView(range: periodListRange, type: periodListType, selectedDay: periodListDay)
            }
        }
        .navigationDestination(for: UUID.self) { id in
            SeizureDetailView(recordID: id)
        }
        .alert("Kunne ikke bruke perioden", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
        .onChange(of: selectedType) { _, _ in selectedDate = nil }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            PageTitle(eyebrow: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)), title: greeting, subtitle: "En enkel oversikt, på dine premisser.")
            ZStack {
                Circle().fill(AppStyle.accentLight).frame(width: 48, height: 48)
                Image(systemName: "waveform.path").font(.title3.weight(.semibold)).foregroundStyle(AppStyle.accent)
            }
            .accessibilityHidden(true)
        }
    }

    private var quickLogCard: some View {
        Button { showingLogger = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: "plus").font(.title2.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registrer et anfall").font(.headline.weight(.semibold))
                    Text("Legg inn en observasjon").font(.subheadline).foregroundStyle(.white.opacity(0.78))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.headline)
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(AppStyle.accent, in: RoundedRectangle(cornerRadius: AppStyle.radius))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("seizure.add")
    }

    private var periodSelector: some View {
        HStack(alignment: .center) {
            Text("Din oversikt").font(.title3.weight(.bold)).foregroundStyle(AppStyle.ink)
            Spacer()
            Menu {
                Button("Siste 7 dager") { selectPreset(7) }
                Button("Siste 30 dager") { selectPreset(30) }
                Button("Siste 90 dager") { selectPreset(90) }
                Divider()
                Button("Velg periode …", systemImage: "calendar") { showingRangePicker = true }
                    .accessibilityIdentifier("dashboard.chooseCustomRange")
            } label: {
                Label(periodLabel, systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppStyle.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppStyle.accentLight, in: Capsule())
            }
            .accessibilityIdentifier("dashboard.period")
        }
    }

    private var chartCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registrerte anfall").font(.subheadline.weight(.medium)).foregroundStyle(AppStyle.muted)
                    Text("\(summary.records.count)").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(AppStyle.ink)
                }
                Spacer()
                Menu {
                    Button("Alle typer", systemImage: "line.3.horizontal.decrease") { selectedType = nil }
                    ForEach(SeizureType.allCases) { type in
                        Button(type.rawValue) { selectedType = type }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(selectedType?.rawValue ?? "Alle typer")
                            .lineLimit(1)
                        Image(systemName: "chevron.down").font(.caption.bold())
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppStyle.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(AppStyle.accentLight, in: Capsule())
                }
                .accessibilityIdentifier("dashboard.typeFilter")
            }
            .accessibilityElement(children: .contain)
            if summary.records.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(AppStyle.accentLight).frame(width: 76, height: 76)
                        Image(systemName: "chart.bar.xaxis").font(.system(size: 28)).foregroundStyle(AppStyle.accent)
                    }
                    Text("Ingen registreringer ennå")
                        .font(.headline)
                        .foregroundStyle(AppStyle.ink)
                    Text("Når du legger inn en observasjon, vises den her. En dag uten registrering betyr ikke nødvendigvis at du ikke har hatt anfall.")
                        .font(.subheadline)
                        .foregroundStyle(AppStyle.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                Chart(summary.dailyCounts) { item in
                    BarMark(
                        x: .value("Dag", item.date, unit: .day),
                        y: .value("Registrerte anfall", item.count),
                        width: .ratio(0.58)
                    )
                    .foregroundStyle(AppStyle.accent.gradient)
                    .cornerRadius(5)
                }
                .chartXScale(domain: chartDateDomain)
                .chartYScale(domain: 0...(max(Double(summary.dailyCounts.map(\.count).max() ?? 0) + 0.4, 1)))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: summary.dailyCounts.count <= 7 ? summary.dailyCounts.count : 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3])).foregroundStyle(AppStyle.ink.opacity(0.12))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(days == 7 ? .dateTime.weekday(.narrow) : .dateTime.day()))
                                    .font(.caption2)
                                    .foregroundStyle(AppStyle.muted)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine().foregroundStyle(AppStyle.ink.opacity(0.08))
                        AxisValueLabel().foregroundStyle(AppStyle.muted)
                    }
                }
                .chartXSelection(value: $selectedDate)
                .frame(height: 184)
                .accessibilityLabel("\(summary.records.count) registrerte anfall over \(days) dager. Trykk på en søyle for å velge en dato.")
                if let selectedDate, let day = summary.dailyCounts.first(where: { Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: selectedDate) }) {
                    HStack(spacing: 7) {
                        Image(systemName: "calendar").foregroundStyle(AppStyle.accent)
                        Text(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if day.count > 0 {
                            Button("Se \(day.count) anfall") { openPeriodRecords(on: day.date) }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppStyle.accent)
                                .accessibilityIdentifier("dashboard.selectedDayResults")
                        } else {
                            Text("Ingen registreringer").font(.subheadline).foregroundStyle(AppStyle.muted)
                        }
                    }
                    .foregroundStyle(AppStyle.ink)
                } else {
                    Text("Trykk på diagrammet for å se én dag.")
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                }
            }
            if !summary.records.isEmpty {
                Button {
                    openPeriodRecords()
                } label: {
                    Label("Se alle \(summary.records.count) anfall i perioden", systemImage: "list.bullet.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(AppStyle.accent)
                .accessibilityIdentifier("dashboard.periodResults")
            }
            if let selectedType {
                Button("Fjern filter · \(selectedType.rawValue)") { self.selectedType = nil }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppStyle.accent)
            }
        }
    }

    private var overviewCard: some View {
        Card {
            SectionTitle(title: "Litt å legge merke til")
            HStack(spacing: 12) {
                statisticTile(
                    title: "Varighet i snitt",
                    value: summary.averageDuration.map { DiaryFormat.duration($0) } ?? "Ukjent",
                    detail: summary.averageDuration == nil ? "Ingen kjente varigheter" : "Av \(summary.knownDurationCount) registreringer"
                )
                statisticTile(
                    title: "Registrert",
                    value: "\(summary.records.count)",
                    detail: customPeriod == nil ? "siste \(days) dager" : "i valgt periode"
                )
            }
            Text("Dette beskriver bare det du har registrert, og er ikke en medisinsk vurdering.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
        }
    }

    private func statisticTile(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(AppStyle.muted)
            Text(value).font(.title3.weight(.bold)).foregroundStyle(AppStyle.ink).lineLimit(1).minimumScaleFactor(0.8)
            Text(detail).font(.caption2).foregroundStyle(AppStyle.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppStyle.canvas, in: RoundedRectangle(cornerRadius: 16))
    }

    private var triggerCard: some View {
        Card {
            SectionTitle(title: "Noterte mulige triggere")
            Text("Ting som er registrert samtidig. Dette betyr ikke nødvendigvis at de er årsaken.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
            ForEach(summary.triggerCounts.prefix(4)) { item in
                HStack {
                    Text(item.name).font(.subheadline.weight(.medium)).foregroundStyle(AppStyle.ink)
                    Spacer()
                    Text("\(item.count) registrering\(item.count == 1 ? "" : "er")")
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                }
                if item.id != summary.triggerCounts.prefix(4).last?.id {
                    Divider()
                }
            }
        }
    }

    private var recentCard: some View {
        Card {
            HStack {
                SectionTitle(title: "Siste registrering")
                Spacer()
                Button("Se alle i perioden") { openPeriodRecords() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppStyle.accent)
            }
            ForEach(Array(summary.records.prefix(3))) { record in
                NavigationLink(value: record.id) {
                    SeizureRow(record: record, compact: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectPreset(_ value: Int) {
        days = value
        customPeriod = nil
        selectedDate = nil
    }

    private func applyRange(startDate: Date, endDate: Date) {
        do {
            customPeriod = try DiaryDateRange(startDate: startDate, endDate: endDate)
            selectedDate = nil
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func openPeriodRecords(on day: Date? = nil) {
        do {
            periodListRange = try DiaryDateRange(startDate: summary.startDate, endDate: summary.endDate)
            periodListType = selectedType
            periodListDay = day.map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }
            showingPeriodList = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private var medicationCard: some View {
        Card {
            SectionTitle(title: "Medisinoversikt")
            let active = medications.filter(\.isActive)
            if active.isEmpty {
                Label("Du har ikke lagt til medisiner.", systemImage: "pills")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.muted)
            } else {
                ForEach(active) { medicine in
                    HStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(AppStyle.accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(medicine.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.ink)
                            if !medicine.dose.isEmpty {
                                Text(medicine.dose).font(.caption).foregroundStyle(AppStyle.muted)
                            }
                        }
                    }
                }
            }
            Text("Dette er en oversikt, ikke en påminnelse om å ta medisiner.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
        }
    }

    private var disclaimer: some View {
        Text("EpiLogg er en dagbok for egne observasjoner. Snakk med helsepersonell om medisinske spørsmål.")
            .font(.caption)
            .foregroundStyle(AppStyle.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
    }
}
