import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Medication.startedAt, order: .reverse) private var existingMedications: [Medication]
    let onFinished: () -> Void

    @State private var step = -1
    @State private var draft = ProfileDraft()
    @State private var customDiagnosis = ""
    @State private var placeEntry = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var diagnosisOptions: [String] {
        HealthOptions.diagnoses + ["Annen diagnose / egen beskrivelse"]
    }

    var body: some View {
        VStack(spacing: 0) {
            if step >= 0 {
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? AppStyle.accent : AppStyle.ink.opacity(0.08))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    stepContent
                }
                .padding(.horizontal, 24)
                .padding(.top, 34)
                .padding(.bottom, 30)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            VStack(spacing: 10) {
                PrimaryButton(
                    title: step < 0 ? "Kom i gang" : step == 4 ? "Gå til oversikten" : "Fortsett",
                    icon: step == 4 ? "checkmark" : "arrow.right",
                    identifier: step < 0 ? "onboarding.start" : step == 4 ? "onboarding.finish" : "onboarding.next",
                    action: advance
                )
                if step > 0 {
                    HStack {
                        Button {
                            step -= 1
                        } label: {
                            Label("Tilbake", systemImage: "chevron.left")
                        }
                        .accessibilityIdentifier("onboarding.back")
                        Spacer()
                        if step < 4 {
                            Button("Hopp over dette steget", action: advance)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppStyle.muted)
                    .frame(minHeight: 38)
                }
                if step >= 0 {
                    Text("Du kan endre dette senere under Profil.")
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
        .background(AppStyle.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: step)
        .alert(step == 4 ? "Kunne ikke lagre opplysningene" : "Kontroller opplysningene", isPresented: $showingError) {
            if step == 4 {
                Button("Prøv igjen", action: saveOnboarding)
                Button("Lukk", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        if step < 0 {
            welcome
        } else if step == 0 {
            diagnosis
        } else if step == 1 {
            medication
        } else if step == 2 {
            triggers
        } else if step == 3 {
            places
        } else {
            finish
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 32).fill(AppStyle.accentLight)
                Image(systemName: "waveform.path")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(AppStyle.accent)
            }
            .frame(height: 200)
            .padding(.bottom, 34)
            PageTitle(eyebrow: "Velkommen til EpiLogg", title: "Din helse. Ditt overblikk.", subtitle: "Et trygt sted å loggføre anfall og legge merke til mønstre, i ditt eget tempo.")
                .padding(.bottom, 26)
            Card {
                Label("Opplysningene dine lagres lokalt på denne enheten.", systemImage: "lock.shield")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppStyle.ink)
                Text("Ingen konto. Ingen helseopplysninger sendes til en server. Du bestemmer selv hva du vil registrere.")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.muted)
            }
        }
    }

    private var diagnosis: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(eyebrow: "Steg 1 av 5", title: "Litt om epilepsien din", subtitle: "Skriv bare det du vet. Det går helt fint å være usikker.")
            Card {
                Text("Hvordan er diagnosen din beskrevet?")
                    .font(.headline)
                    .foregroundStyle(AppStyle.ink)
                Text("Dette er diagnosen, ikke nødvendigvis typen anfall.")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.muted)
                VStack(spacing: 8) {
                    ForEach(diagnosisOptions, id: \.self) { option in
                        choiceRow(option, selected: diagnosisMatches(option)) {
                            draft.diagnosis = option == "Annen diagnose / egen beskrivelse" ? "Annen: \(customDiagnosis)" : option
                        }
                    }
                }
                if draft.diagnosis.hasPrefix("Annen:") || draft.diagnosis.isEmpty {
                    TextField("Egen beskrivelse (valgfritt)", text: $customDiagnosis)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: customDiagnosis) { _, value in
                            if draft.diagnosis.hasPrefix("Annen:") || draft.diagnosis.isEmpty {
                                draft.diagnosis = value.isEmpty ? "" : "Annen: \(value)"
                            }
                        }
                }
                TextField("Navn eller kallenavn (valgfritt)", text: $draft.preferredName)
                    .textContentType(.nickname)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var medication: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(eyebrow: "Steg 2 av 5", title: "Medisinene dine", subtitle: "Hold oversikt over det du tar. Dette erstatter ikke legens eller apotekets råd.")
            Card {
                ForEach(Array(draft.medications.indices), id: \.self) { index in
                    medicationFields(at: index)
                }
                Button {
                    draft.medications.append(MedicationDraft())
                } label: {
                    Label("Legg til medisin", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppStyle.accent)
                }
                if draft.medications.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "pills.fill").foregroundStyle(AppStyle.accent)
                        Text("Medisiner er valgfrie. Du kan legge dem til eller oppdatere dem senere.")
                            .font(.subheadline)
                            .foregroundStyle(AppStyle.muted)
                    }
                }
            }
        }
    }

    private var triggers: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(eyebrow: "Steg 3 av 5", title: "Mulige triggere", subtitle: "Velg ting du har lagt merke til. Sammenfall betyr ikke nødvendigvis at noe er årsaken.")
            Card {
                Text("Hva vil du følge med på?")
                    .font(.headline)
                    .foregroundStyle(AppStyle.ink)
                TriggerSelector(customTriggers: draft.triggers, selection: $draft.triggers)
            }
            Card {
                Text("Annet du vil huske")
                    .font(.headline)
                    .foregroundStyle(AppStyle.ink)
                TextField("Varselsymptomer", text: $draft.warningSigns, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                TextField("Andre opplysninger (valgfritt)", text: $draft.notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var places: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(eyebrow: "Steg 4 av 5", title: "Dine steder", subtitle: "Velg steder du vil ha lett tilgjengelig når du registrerer et anfall.")
            Card {
                Text("Hvor er du i hverdagen?")
                    .font(.headline)
                    .foregroundStyle(AppStyle.ink)
                SavedPlacesEditor(places: $draft.places, entry: $placeEntry)
                Text("Stedene er valgfrie. Du velger sted og inne eller ute for hvert anfall, og kan endre listen under Profil.")
                    .font(.caption)
                    .foregroundStyle(AppStyle.muted)
            }
        }
    }

    private var finish: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(eyebrow: "Steg 5 av 5", title: "Dette er din plass", subtitle: "Du har kontrollen — legg til, endre eller slett opplysninger når du vil.")
            Card {
                Label("Profilen kan redigeres under Profil.", systemImage: "person.crop.circle")
                    .foregroundStyle(AppStyle.accent)
                Label("Loggføringene og oversikten blir værende på enheten.", systemImage: "iphone")
                    .foregroundStyle(AppStyle.accent)
                Text("EpiLogg er en dagbok for egne observasjoner, ikke et verktøy for medisinsk rådgivning eller diagnostisering.")
                    .font(.footnote)
                    .foregroundStyle(AppStyle.muted)
            }
        }
    }

    private func medicationFields(at index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Medisin \(index + 1)").font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive) {
                    draft.medications.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Fjern medisin \(index + 1)")
            }
            TextField("Navn på medisin", text: $draft.medications[index].name)
                .textFieldStyle(.roundedBorder)
            TextField("Dose (valgfritt)", text: $draft.medications[index].dose)
                .textFieldStyle(.roundedBorder)
            TextField("Tidspunkt, for eksempel morgen og kveld", text: $draft.medications[index].schedule)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 4)
    }

    private func choiceRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? AppStyle.accent : AppStyle.muted.opacity(0.55))
            }
            .foregroundStyle(AppStyle.ink)
            .padding(14)
            .background(selected ? AppStyle.accentLight : AppStyle.canvas, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func diagnosisMatches(_ option: String) -> Bool {
        option == "Annen diagnose / egen beskrivelse" ? draft.diagnosis.hasPrefix("Annen:") : draft.diagnosis == option
    }

    private func advance() {
        if step == 1 {
            do {
                for medicine in draft.medications {
                    try medicine.validate()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                return
            }
        }
        if step == 3, let place = NamedOptionCatalog.normalize(placeEntry) {
            draft.places = NamedOptionCatalog.normalized(draft.places + [place])
            placeEntry = ""
        }
        if step >= 4 {
            saveOnboarding()
        } else {
            step += 1
        }
    }

    private func saveOnboarding() {
        do {
            var completeDraft = draft
            completeDraft.medications = existingMedications.map {
                MedicationDraft(name: $0.name, dose: $0.dose, schedule: $0.schedule, startedAt: $0.startedAt)
            } + draft.medications
            try DiaryStore(context: context).saveProfile(completeDraft)
            onFinished()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
