import AppKit
import Foundation

@MainActor
final class TemplateStore: ObservableObject {
    @Published var templates: [FormTemplate] = []
    @Published var selectedTemplateID: FormTemplate.ID?

    private let defaultsKey = "CustomForm.templates.v1"

    init() {
        load()
    }

    var selectedTemplateIndex: Int? {
        guard let selectedTemplateID else { return nil }
        return templates.firstIndex(where: { $0.id == selectedTemplateID })
    }

    func addTemplate() {
        let template = FormTemplate(title: nextUntitledName())
        templates.append(template)
        selectedTemplateID = template.id
    }

    func deleteSelectedTemplate() {
        guard let selectedTemplateIndex else { return }
        templates.remove(at: selectedTemplateIndex)
        selectedTemplateID = templates.first?.id
    }

    func save() throws {
        templates.indices.forEach { templates[$0].modifiedAt = .now }
        let data = try JSONEncoder.pretty.encode(templates)
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func exportTemplates(to url: URL) throws {
        let data = try JSONEncoder.pretty.encode(templates)
        try data.write(to: url, options: .atomic)
    }

    func importTemplates(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let incoming = try JSONDecoder.pretty.decode([FormTemplate].self, from: data)
        guard !incoming.isEmpty else { throw TemplateError.emptyImport }

        var existingIDs = Set(templates.map(\.id))
        var imported = incoming.map { template -> FormTemplate in
            var copy = template
            if existingIDs.contains(copy.id) { copy.id = UUID() }
            existingIDs.insert(copy.id)
            copy.modifiedAt = .now
            return copy
        }
        templates.append(contentsOf: imported)
        selectedTemplateID = imported.last?.id
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            templates = try JSONDecoder().decode([FormTemplate].self, from: data)
            selectedTemplateID = templates.first?.id
        } catch {
            // A corrupt local cache should never prevent the app from opening.
            templates = []
        }
    }

    private func nextUntitledName() -> String {
        let number = templates.filter { $0.title.hasPrefix("Untitled Form") }.count + 1
        return "Untitled Form \(number)"
    }
}

private enum TemplateError: LocalizedError {
    case emptyImport

    var errorDescription: String? {
        switch self {
        case .emptyImport: "The selected file does not contain any templates."
        }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var pretty: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
