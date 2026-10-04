import SwiftUI
import SwiftData

struct SeizureFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    let editing: SeizureRecord?

    @State private var draft: SeizureDraft
    @State private var detailsExpanded: Bool
    @State private var placeEntry = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    init(editing: SeizureRecord? = nil) {
        self.editing = editing
        _draft = State(initialValue: editing.map(SeizureDraft.init(record:)) ?? SeizureDraft())
        _detailsExpanded = State(initialValue: editing != nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageTitle(
                        eyebrow: editing == nil ? "Din dagbok" : "Oppdater loggen",
                        title: editing == nil ? "Registrer anfall" : "Endre registrering",
                        subtitle: "Registrer når det passer. Det er helt greit å fylle inn det du husker senere."
                    )
                    Card {
                        DatePicker(
                            "Dato og tidspunkt",
                            selection: $draft.occurredAt,
                            in: ...Date.now,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("seizure.date")
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type anfall").font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.ink)
                            Picker("Type anfall", selection: $draft.type) {
                                ForEach(SeizureType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("seizure.type")
                        }
                        Divider()
                        Toggle("Jeg vet omtrent hvor lenge det varte", isOn: $draft.durationKnown)
                            .font(.subheadline.weight(.medium))
                            .tint(AppStyle.accent)
                        if draft.durationKnown {
                            HStack(spacing: 12) {
                                durationInput(title: "Minutter", value: $draft.minutes, accessibilityID: "seizure.minutes")
                                Text(":").font(.title2.weight(.semibold)).foregroundStyle(AppStyle.muted)
                                durationInput(title: "Sekunder", value: $draft.seconds, accessibilityID: "seizure.seconds")
                            }
                        } else {
                            Text("Varighet er valgfritt. Ukjent betyr ikke null.")
                                .font(.caption)
                                .foregroundStyle(AppStyle.muted)
                        }
                    }

                    Card {
                        Label("Hvor skjedde det?", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                            .foregroundStyle(AppStyle.ink)
                        PlaceSelector(
                            places: profiles.first?.places ?? [],
                            selection: $draft.locationName,
                            newPlaces: $draft.newPlaces,
                            entry: $placeEntry
                        )
                        Text("Var du inne eller ute?")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppStyle.ink)
                        FlowLayout(spacing: 8) {
                            ForEach(SeizureEnvironment.allCases) { environment in
                                OptionChip(title: environment.rawValue, isSelected: draft.environment == environment) {
                                    draft.environment = environment
                                }
                                .accessibilityIdentifier("seizure.environment.\(environment.rawValue)")
                            }
                        }
                        Text("Valgfritt. Velg ett sted, eller la det stå ukjent. Nye steder blir lagret når du lagrer anfallet.")
                            .font(.caption)
                            .foregroundStyle(AppStyle.muted)
                    }

                    Card {
                        SectionTitle(title: "Mulige triggere")
                        Text("Valgfritt. Sammenfall betyr ikke nødvendigvis at noe er årsaken.")
                            .font(.caption)
                            .foregroundStyle(AppStyle.muted)
                        TriggerSelector(
                            customTriggers: profiles.first?.triggers ?? [],
                            selection: $draft.triggers,
                            onAddCustom: { draft.newCustomTriggers.append($0) }
                        )
                    }

                    DisclosureGroup(isExpanded: $detailsExpanded) {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(title: "Symptomer")
                                OptionChips(options: HealthOptions.symptoms, selection: $draft.symptoms)
                            }
                            Toggle("Det oppstod en skade", isOn: $draft.injury)
                                .tint(AppStyle.accent)
                            TextField("Hvordan var det etterpå? (valgfritt)", text: $draft.recovery, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                            TextField("Akuttmedisin du brukte (valgfritt)", text: $draft.rescueMedication)
                                .textFieldStyle(.roundedBorder)
                            TextField("Notater (valgfritt)", text: $draft.notes, axis: .vertical)
                                .lineLimit(3...6)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.top, 18)
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3").foregroundStyle(AppStyle.accent)
                            Text("Legg til detaljer (valgfritt)")
                                .font(.headline)
                                .foregroundStyle(AppStyle.ink)
                        }
                    }
                    .padding(20)
                    .background(.white, in: RoundedRectangle(cornerRadius: AppStyle.radius))

                    Text("Ved akutt fare: kontakt nødetatene. Appen varsler ikke pårørende eller helsepersonell.")
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                }
                .padding(22)
                .padding(.bottom, 20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(AppStyle.canvas)
            .navigationTitle(editing == nil ? "Ny registrering" : "Rediger registrering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre", action: save)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("seizure.save")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .alert("Registreringen ble ikke lagret", isPresented: $showingError) {
            Button("Prøv igjen", action: save)
            Button("Lukk", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func durationInput(title: String, value: Binding<String>, accessibilityID: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(AppStyle.muted)
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .font(.title3.weight(.semibold).monospacedDigit())
                .accessibilityLabel(title)
                .accessibilityIdentifier(accessibilityID)
                .padding(12)
                .background(AppStyle.canvas, in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        if let place = NamedOptionCatalog.normalize(placeEntry) {
            draft.locationName = place
            draft.newPlaces = NamedOptionCatalog.normalized(draft.newPlaces + [place])
            placeEntry = ""
        }
        do {
            try DiaryStore(context: context).saveSeizure(draft, editing: editing)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
