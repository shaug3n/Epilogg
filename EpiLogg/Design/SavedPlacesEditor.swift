import SwiftUI

struct SavedPlacesEditor: View {
    @Binding var places: [String]
    @Binding var entry: String

    private var options: [String] {
        NamedOptionCatalog.normalized(HealthOptions.places + places)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OptionChips(options: options, selection: $places)
            NamedOptionEntry(placeholder: "Eget sted", identifier: "place", entry: $entry) {
                guard let value = NamedOptionCatalog.normalize(entry) else { return }
                places = NamedOptionCatalog.normalized(places + [value])
                entry = ""
            }
        }
    }
}
