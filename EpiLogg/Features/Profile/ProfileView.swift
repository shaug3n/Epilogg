import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \Medication.startedAt, order: .reverse) private var medications: [Medication]
    @State private var draft = ProfileDraft()
    @State private var placeEntry = ""
    @State private var loadedPlaces: [String] = []
    @State private var selectedTriggers: [String] = []
    @State private var loadedProfileID: UUID?
    @State private var showingMedicineForm = false
    @State private var medicineToEnd: Medication?
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var showingExport = false
    @State private var exportDocument: DiaryJSONDocument?
    @State private var errorMessage = ""

    private var profile: UserProfile? { profiles.first }
    private var activeMedications: [Medication] { medications.filter(\.isActive) }
    private var inactiveMedications: [Medication] { medications.filter { !$0.isActive } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageTitle(eyebrow: "Ditt overblikk", title: "Profil", subtitle: "Du bestemmer selv hva du vil registrere.")
                    personalDetails
                    placesCard
                    medicineList
                    privacyCard
                    dataActions
                    Text("EpiLogg gir ikke medisinske råd, analyserer ikke årsaker og varsler ikke andre.")
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(22)
                .padding(.bottom, 32)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(AppStyle.canvas)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingMedicineForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Legg til medisin")
                    .accessibilityIdentifier("medicine.add")
                }
            }
            .sheet(isPresented: $showingMedicineForm) { MedicationFormView() }
            .confirmationDialog("Avslutte denne medisinen?", isPresented: Binding(
                get: { medicineToEnd != nil },
                set: { if !$0 { medicineToEnd = nil } }
            ), titleVisibility: .visible) {
                Button("Marker som avsluttet") {
                    if let medicine = medicineToEnd {
                        do {
                            try DiaryStore(context: context).endMedication(medicine)
                        } catch {
                            present(error)
                        }
                    }
                    medicineToEnd = nil
                }
                Button("Avbryt", role: .cancel) { medicineToEnd = nil }
            }
            .confirmationDialog("Slett alle opplysningene dine?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Slett alle data", role: .destructive) {
                    do {
                        try DiaryStore(context: context).deleteAll()
                        loadedProfileID = nil
                    } catch {
                        present(error)
                    }
                }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Profil, medisiner og alle anfallsregistreringer slettes fra denne enheten. Dette kan ikke angres.")
            }
            .fileExporter(
                isPresented: $showingExport,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "epilogg-eksport"
            ) { result in
                if case .failure(let error) = result {
                    present(error)
                }
                exportDocument = nil
            }
            .alert("Kunne ikke fullføre", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear(perform: loadProfile)
            .onChange(of: profile?.id) { _, _ in loadProfile() }
            .onChange(of: profile?.places) { _, _ in loadProfile() }
        }
    }

    private var personalDetails: some View {
        Card {
            SectionTitle(title: "Om deg")
            TextField("Navn eller kallenavn (valgfritt)", text: $draft.preferredName)
                .textContentType(.nickname)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 9) {
                Text("Diagnose (valgfritt)").font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.ink)
                ForEach(HealthOptions.diagnoses, id: \.self) { option in
                    Button {
                        draft.diagnosis = draft.diagnosis == option ? "" : option
                        customDiagnosis = ""
                    } label: {
                        HStack {
                            Text(option).font(.subheadline)
                            Spacer()
                            Image(systemName: draft.diagnosis == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(draft.diagnosis == option ? AppStyle.accent : AppStyle.muted.opacity(0.5))
                        }
                        .foregroundStyle(AppStyle.ink)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    draft.diagnosis = "Annen: \(customDiagnosis)"
                } label: {
                    HStack {
                        Text("Annen diagnose / egen beskrivelse").font(.subheadline)
                        Spacer()
                        Image(systemName: draft.diagnosis.hasPrefix("Annen:") ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(draft.diagnosis.hasPrefix("Annen:") ? AppStyle.accent : AppStyle.muted.opacity(0.5))
                    }
                    .foregroundStyle(AppStyle.ink)
                }
                .buttonStyle(.plain)
                TextField("Eller skriv en egen beskrivelse", text: $customDiagnosis)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: customDiagnosis) { _, value in
                        if draft.diagnosis.hasPrefix("Annen:") {
                            draft.diagnosis = value.isEmpty ? "Annen:" : "Annen: \(value)"
                        }
                    }
            }
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Mulige triggere")
                TriggerSelector(customTriggers: draft.triggers, selection: $draft.triggers)
            }
            TextField("Varselsymptomer (valgfritt)", text: $draft.warningSigns, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            TextField("Andre opplysninger (valgfritt)", text: $draft.notes, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            PrimaryButton(title: "Lagre profil", icon: "checkmark", identifier: "profile.saveChanges", action: saveProfile)
        }
    }

    private var placesCard: some View {
        Card {
            SectionTitle(title: "Dine steder")
            Text("Velg hvilke steder som skal være tilgjengelige når du registrerer et anfall.")
                .font(.subheadline)
                .foregroundStyle(AppStyle.muted)
            SavedPlacesEditor(places: $draft.places, entry: $placeEntry)
            Text("Fjerning fra denne listen endrer ikke stedet i tidligere anfallsregistreringer.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
            if let profile {
                PrimaryButton(title: "Lagre steder", icon: "checkmark", identifier: "profile.savePlaces") {
                    savePlaces(for: profile)
                }
            }
        }
    }

    @State private var customDiagnosis = ""
    private var medicineList: some View {
        Card {
            HStack {
                SectionTitle(title: "Medisiner")
                Spacer()
                Button { showingMedicineForm = true } label: {
                    Label("Legg til", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppStyle.accent)
                }
            }
            if medications.isEmpty {
                Text("Du har ikke lagt til medisiner. Dette er helt valgfritt.")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.muted)
            }
            ForEach(activeMedications) { medicine in
                medicineRow(medicine, isActive: true)
                if medicine.id != activeMedications.last?.id { Divider() }
            }
            if !inactiveMedications.isEmpty {
                Text("Tidligere medisiner")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppStyle.muted)
                    .padding(.top, 4)
                ForEach(inactiveMedications) { medicine in
                    medicineRow(medicine, isActive: false)
                }
            }
            Text("Registreringene beholder et øyeblikksbilde av medisiner som var aktive på registreringstidspunktet.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
        }
    }

    private func medicineRow(_ medicine: Medication, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pills.fill").foregroundStyle(AppStyle.accent).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.ink)
                if !medicine.dose.isEmpty {
                    Text(medicine.dose).font(.caption).foregroundStyle(AppStyle.muted)
                }
                if !medicine.schedule.isEmpty {
                    Text(medicine.schedule).font(.caption).foregroundStyle(AppStyle.muted)
                }
                if let endedAt = medicine.endedAt {
                    Text("Avsluttet \(endedAt.formatted(.dateTime.day().month(.abbreviated).year()))")
                        .font(.caption2)
                        .foregroundStyle(AppStyle.muted)
                }
            }
            Spacer()
            if isActive {
                Button("Avslutt") { medicineToEnd = medicine }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppStyle.accent)
                    .accessibilityLabel("Marker \(medicine.name) som avsluttet")
            }
        }
        .padding(.vertical, 5)
    }

    private var privacyCard: some View {
        Card {
            SectionTitle(title: "Dine opplysninger")
            Label("Lagres lokalt på enheten din.", systemImage: "iphone")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppStyle.ink)
            Label("Appen sender ikke data til en server.", systemImage: "network.slash")
                .font(.subheadline)
                .foregroundStyle(AppStyle.ink)
            Label("Eksporter eller slett når du vil.", systemImage: "square.and.arrow.up")
                .font(.subheadline)
                .foregroundStyle(AppStyle.ink)
            Text("Hvis du bruker Apples enhetsbackup, kan lokale appdata være med i sikkerhetskopien avhengig av innstillingene dine.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
        }
    }

    private var dataActions: some View {
        Card {
            SectionTitle(title: "Eksporter eller slett")
            Text("Eksporten er en JSON-fil med profilen, medisinene og anfallsregistreringene.")
                .font(.caption)
                .foregroundStyle(AppStyle.muted)
            Button(action: exportData) {
                Label("Eksporter data (JSON)", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .tint(AppStyle.accent)
            .accessibilityIdentifier("profile.export")
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Slett alle data", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("profile.deleteAll")
        }
    }

    private func loadProfile() {
        guard let profile else {
            draft = ProfileDraft()
            loadedProfileID = nil
            loadedPlaces = []
            return
        }
        let places = profile.places ?? []
        if loadedProfileID == profile.id {
            let additions = places.filter { !loadedPlaces.contains($0) }
            let removals = loadedPlaces.filter { !places.contains($0) }
            draft.places = NamedOptionCatalog.normalized((draft.places + additions).filter { !removals.contains($0) })
            loadedPlaces = places
            return
        }
        draft = ProfileDraft(profile: profile)
        loadedPlaces = places
        customDiagnosis = profile.diagnosis.hasPrefix("Annen: ") ? String(profile.diagnosis.dropFirst(7)) : ""
        loadedProfileID = profile.id
    }

    private func saveProfile() {
        includePendingPlace()
        if draft.diagnosis.hasPrefix("Annen:"),
           !customDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.diagnosis = "Annen: \(customDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        do {
            try DiaryStore(context: context).saveProfile(draft, editing: profile)
            loadedProfileID = profile?.id
        } catch {
            present(error)
        }
    }

    private func savePlaces(for profile: UserProfile) {
        includePendingPlace()
        do {
            try DiaryStore(context: context).savePlaces(draft.places, for: profile)
        } catch {
            present(error)
        }
    }

    private func includePendingPlace() {
        if let place = NamedOptionCatalog.normalize(placeEntry) {
            draft.places = NamedOptionCatalog.normalized(draft.places + [place])
            placeEntry = ""
        }
    }

    private func exportData() {
        do {
            exportDocument = DiaryJSONDocument(data: try DiaryStore(context: context).exportData())
            showingExport = true
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}
