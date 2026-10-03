import SwiftUI

struct DateRangePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date
    @State private var endDate: Date
    let onApply: (Date, Date) -> Void

    init(startDate: Date, endDate: Date, onApply: @escaping (Date, Date) -> Void) {
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Fra", selection: $startDate, in: ...endDate, displayedComponents: .date)
                        .accessibilityIdentifier("dashboard.rangeStart")
                    DatePicker("Til", selection: $endDate, in: startDate...Date.now, displayedComponents: .date)
                        .accessibilityIdentifier("dashboard.rangeEnd")
                } header: {
                    Text("Velg kalenderdager")
                } footer: {
                    Text("Begge datoene blir tatt med. Sluttdatoen kan ikke være senere enn i dag.")
                }
                Section {
                    Text("Visninger og statistikk bruker samme periode. Dager uten registrering betyr ikke nødvendigvis at du ikke har hatt anfall.")
                        .font(.footnote)
                        .foregroundStyle(AppStyle.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppStyle.canvas)
            .navigationTitle("Velg periode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bruk periode") {
                        onApply(startDate, endDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("dashboard.applyRange")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
