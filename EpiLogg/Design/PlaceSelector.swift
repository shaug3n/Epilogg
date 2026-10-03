import SwiftUI

struct PlaceSelector: View {
    let places: [String]
    @Binding var selection: String
    @Binding var newPlaces: [String]
    @Binding var entry: String

    private var options: [String] {
        NamedOptionCatalog.normalized(places + newPlaces + [selection])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if options.isEmpty {
                Text("Du kan legge til et sted her, eller senere under Profil.")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.muted)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let selected = selection.localizedCaseInsensitiveCompare(option) == .orderedSame
                        OptionChip(title: option, isSelected: selected) {
                            selection = selected ? "" : option
                        }
                        .accessibilityIdentifier("place.option.\(option)")
                    }
                }
            }
            NamedOptionEntry(placeholder: "Eget sted", identifier: "place", entry: $entry) {
                guard let value = NamedOptionCatalog.normalize(entry) else { return }
                selection = value
                newPlaces = NamedOptionCatalog.normalized(newPlaces + [value])
                entry = ""
            }
        }
    }
}
