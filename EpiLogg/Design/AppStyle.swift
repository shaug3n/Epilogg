import SwiftUI

enum AppStyle {
    static let ink = Color(red: 0.12, green: 0.19, blue: 0.28)
    static let muted = Color(red: 0.40, green: 0.46, blue: 0.54)
    static let canvas = Color(red: 0.96, green: 0.96, blue: 0.94)
    static let card = Color.white
    static let accent = Color(red: 0.16, green: 0.43, blue: 0.40)
    static let accentLight = Color(red: 0.88, green: 0.94, blue: 0.91)
    static let peach = Color(red: 0.96, green: 0.84, blue: 0.75)
    static let radius: CGFloat = 24
}

struct PageTitle: View {
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(AppStyle.accent)
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-1)
                .foregroundStyle(AppStyle.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct SectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title).font(.headline.weight(.semibold)).foregroundStyle(AppStyle.ink)
            Spacer()
            if let trailing {
                Text(trailing).font(.caption).foregroundStyle(AppStyle.muted)
            }
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.card, in: RoundedRectangle(cornerRadius: AppStyle.radius))
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String?
    var identifier: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon).font(.body.weight(.semibold))
                }
                Text(title).font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(AppStyle.accent, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier ?? "")
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + (x == 0 ? 0 : spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct OptionChips: View {
    let options: [String]
    @Binding var selection: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = selection.contains { $0.localizedCaseInsensitiveCompare(option) == .orderedSame }
                OptionChip(title: option, isSelected: selected) {
                    if selected {
                        selection.removeAll { $0.localizedCaseInsensitiveCompare(option) == .orderedSame }
                    } else {
                        selection.append(option)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OptionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected { Image(systemName: "checkmark").font(.caption.bold()) }
                Text(title).font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? AppStyle.accent : AppStyle.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? AppStyle.accentLight : AppStyle.canvas, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? AppStyle.accent.opacity(0.25) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct NamedOptionEntry: View {
    let placeholder: String
    let identifier: String
    @Binding var entry: String
    let onAdd: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: $entry)
                .focused($isFocused)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit(add)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("\(identifier).entry")
            Button(action: add) {
                Label("Legg til", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.bordered)
            .tint(AppStyle.accent)
            .disabled(NamedOptionCatalog.normalize(entry) == nil)
            .accessibilityIdentifier("\(identifier).add")
        }
    }

    private func add() {
        onAdd()
        isFocused = false
    }
}

struct TriggerSelector: View {
    let customTriggers: [String]
    @Binding var selection: [String]
    var onAddCustom: (String) -> Void = { _ in }
    @State private var entry = ""

    private var availableTriggers: [String] {
        NamedOptionCatalog.normalized(HealthOptions.triggers + customTriggers + selection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OptionChips(options: availableTriggers, selection: $selection)
            NamedOptionEntry(placeholder: "Egen trigger", identifier: "trigger", entry: $entry, onAdd: addTrigger)
        }
    }

    private func addTrigger() {
        guard let value = NamedOptionCatalog.normalize(entry) else { return }
        let alreadyAvailable = availableTriggers.contains {
            $0.localizedCaseInsensitiveCompare(value) == .orderedSame
        }
        if !selection.contains(where: { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }) {
            selection.append(value)
        }
        if !alreadyAvailable,
           !HealthOptions.triggers.contains(where: { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }) {
            onAddCustom(value)
        }
        entry = ""
    }
}
