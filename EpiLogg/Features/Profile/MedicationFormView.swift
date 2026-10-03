import SwiftUI
import SwiftData

struct MedicationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var draft = MedicationDraft()
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Medisin") {
                    TextField("Navn", text: $draft.name)
                        .accessibilityIdentifier("medicine.name")
                    TextField("Dose, for eksempel 100 mg", text: $draft.dose)
                    TextField("Når tar du den? (valgfritt)", text: $draft.schedule)
                    DatePicker("Startdato", selection: $draft.startedAt, in: ...Date.now, displayedComponents: .date)
                }
                Section {
                    Text("Oppgi medisinen slik den er forskrevet. Appen gir ikke medisinske råd eller påminnelser.")
                        .font(.footnote)
                        .foregroundStyle(AppStyle.muted)
                }
            }
            .navigationTitle("Legg til medisin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") { save() }
                        .accessibilityIdentifier("medicine.save")
                }
            }
        }
        .alert("Kunne ikke lagre medisinen", isPresented: $showingError) {
            Button("Prøv igjen") { save() }
            Button("Lukk", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    private func save() {
        do {
            try DiaryStore(context: context).addMedication(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
