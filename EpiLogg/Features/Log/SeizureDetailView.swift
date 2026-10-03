import SwiftUI
import SwiftData

struct SeizureDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    @Query private var records: [SeizureRecord]
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(recordID: UUID) {
        self.recordID = recordID
        let id = recordID
        _records = Query(filter: #Predicate<SeizureRecord> { $0.id == id })
    }

    private var record: SeizureRecord? { records.first }

    var body: some View {
        Group {
            if let record {
                detail(record)
            } else {
                ContentUnavailableView("Registreringen finnes ikke", systemImage: "doc.questionmark")
            }
        }
        .background(AppStyle.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditor) {
            if let record { SeizureFormView(editing: record) }
        }
        .confirmationDialog("Slette denne registreringen?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Slett registrering", role: .destructive) {
                if let record {
                    do {
                        try DiaryStore(context: context).deleteSeizure(record)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
            Button("Avbryt", role: .cancel) {}
        }
        .alert("Kunne ikke slette", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    private func detail(_ record: SeizureRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageTitle(
                    eyebrow: record.occurredAt.formatted(.dateTime.weekday(.wide).day().month(.wide).year()),
                    title: record.type.rawValue,
                    subtitle: record.occurredAt.formatted(.dateTime.hour().minute())
                )
                Card {
                    SectionTitle(title: "Om anfallet")
                    detailLine("Varighet", DiaryFormat.duration(record.durationSeconds))
                    if let locationName = record.locationName {
                        detailLine("Sted", locationName)
                    }
                    if let locationType = record.locationType {
                        detailLine("Inne / ute", locationType)
                    }
                    if !record.triggers.isEmpty { detailLine("Mulige triggere", record.triggers.joined(separator: ", ")) }
                    if !record.symptoms.isEmpty { detailLine("Symptomer", record.symptoms.joined(separator: ", ")) }
                    detailLine("Skade", record.injury ? "Ja" : "Nei")
                    if !record.recovery.isEmpty { detailLine("Etterpå", record.recovery) }
                    if !record.rescueMedication.isEmpty { detailLine("Akuttmedisin notert", record.rescueMedication) }
                    if !record.notes.isEmpty { detailLine("Notater", record.notes) }
                }
                Card {
                    SectionTitle(title: "Medisin på registreringstidspunktet")
                    if record.medicationSnapshot.isEmpty {
                        Text("Ingen medisin var registrert på dette tidspunktet.")
                            .font(.subheadline)
                            .foregroundStyle(AppStyle.muted)
                    } else {
                        ForEach(record.medicationSnapshot, id: \.self) { item in
                            Label(item, systemImage: "pills")
                                .font(.subheadline)
                                .foregroundStyle(AppStyle.ink)
                        }
                    }
                }
                Text("Etterregistrering er velkommen. Opplysningene dine er egne observasjoner, ikke en medisinsk vurdering.")
                    .font(.caption)
                    .foregroundStyle(AppStyle.muted)
            }
            .padding(22)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Endre registrering", systemImage: "pencil") { showingEditor = true }
                        .accessibilityIdentifier("seizure.edit")
                    Button("Slett registrering", systemImage: "trash", role: .destructive) { showingDeleteConfirmation = true }
                        .accessibilityIdentifier("seizure.delete")
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
                .accessibilityLabel("Flere valg")
                .accessibilityIdentifier("seizure.more")
            }
        }
    }

    private func detailLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.subheadline).foregroundStyle(AppStyle.muted)
            Spacer(minLength: 10)
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(AppStyle.ink).multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("seizure.detail.\(title)")
    }
}
