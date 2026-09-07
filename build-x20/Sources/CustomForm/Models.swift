import Foundation

enum FormElementKind: String, Codable, CaseIterable, Identifiable {
    case text
    case textField
    case checkbox
    case radio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .text: "Static Text"
        case .textField: "Text Field"
        case .checkbox: "Checkbox"
        case .radio: "Radio Selection"
        }
    }
}

struct FormElement: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var kind: FormElementKind

    /// Static text content, or the visible prompt for an interactive control.
    var label: String = ""

    /// The text to place into an export when a checkbox is checked.
    var selectedOutput: String = ""

    /// Each non-empty entry is one selectable radio choice.
    var options: [String] = []

    var isValid: Bool {
        switch kind {
        case .checkbox:
            return !label.trimmed.isEmpty && !selectedOutput.trimmed.isEmpty
        case .radio:
            return !label.trimmed.isEmpty && options.contains { !$0.trimmed.isEmpty }
        case .text, .textField:
            return true
        }
    }
}

struct FormTemplate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = "Untitled Form"
    var elements: [FormElement] = []
    var modifiedAt: Date = .now

    var canSave: Bool {
        !title.trimmed.isEmpty && elements.allSatisfy(\.isValid)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
