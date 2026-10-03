import Foundation

enum NamedOptionCatalog {
    static func normalize(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    static func normalized(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap(normalize).filter { seen.insert($0.lowercased()).inserted }
    }
}
