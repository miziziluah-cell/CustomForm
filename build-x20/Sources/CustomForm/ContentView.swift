import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = TemplateStore()
    @State private var isShowingSettings = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $store.selectedTemplateID) {
                ForEach(store.templates) { template in
                    Text(template.title.trimmed.isEmpty ? "Untitled Form" : template.title)
                        .lineLimit(1)
                        .tag(template.id)
                }
            }
            .navigationTitle("Templates")
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button(action: store.addTemplate) {
                        Label("Add Template", systemImage: "plus")
                    }
                    .help("Create a new template")

                    Button(role: .destructive, action: store.deleteSelectedTemplate) {
                        Label("Delete Selected Template", systemImage: "trash")
                    }
                    .disabled(store.selectedTemplateID == nil)
                    .help("Delete the selected template")
                }
                .buttonStyle(.borderless)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 340)
        } detail: {
            if let index = store.selectedTemplateIndex {
                FormWorkspace(
                    template: $store.templates[index],
                    saveTemplate: saveTemplates,
                    openSettings: { isShowingSettings = true },
                    showMessage: { alertMessage = $0 }
                )
            } else {
                ContentUnavailableView(
                    "No Template Selected",
                    systemImage: "rectangle.and.pencil.and.ellipsis",
                    description: Text("Create a template to start building a custom form.")
                )
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(store: store, alertMessage: $alertMessage)
        }
        .alert("Custom Form", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func saveTemplates() {
        do {
            try store.save()
            alertMessage = "Templates saved on this Mac."
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

private enum EditorMode: String, CaseIterable, Identifiable {
    case build = "Build"
    case fillOut = "Fill Out"

    var id: String { rawValue }
}

private struct FormWorkspace: View {
    @Binding var template: FormTemplate
    let saveTemplate: () -> Void
    let openSettings: () -> Void
    let showMessage: (String) -> Void

    @State private var mode: EditorMode = .build
    @State private var textValues: [UUID: String] = [:]
    @State private var checkedValues: Set<UUID> = []
    @State private var radioValues: [UUID: String] = [:]
    @State private var includePromptsInExport = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(template.title.trimmed.isEmpty ? "Untitled Form" : template.title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Picker("Mode", selection: $mode) {
                    ForEach(EditorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 180)

                Button("Save", action: saveCurrentTemplate)
                Button(action: openSettings) {
                    Image(systemName: "gearshape")
                }
                .help("Settings: save, import, or export templates")
            }
            .padding()
            .background(.bar)

            Divider()

            Group {
                if mode == .build {
                    FormBuilder(template: $template)
                } else {
                    FormFiller(
                        template: template,
                        textValues: $textValues,
                        checkedValues: $checkedValues,
                        radioValues: $radioValues,
                        includePromptsInExport: $includePromptsInExport,
                        showMessage: showMessage
                    )
                }
            }
        }
        .onChange(of: template.id) { _, _ in clearAll() }
    }

    private func saveCurrentTemplate() {
        guard template.canSave else {
            showMessage("Before saving, give every checkbox both a label and the text that should export when it is selected. Radio selections need a label and at least one choice.")
            return
        }
        saveTemplate()
    }

    private func clearAll() {
        textValues = [:]
        checkedValues = []
        radioValues = [:]
    }
}

private struct FormBuilder: View {
    @Binding var template: FormTemplate

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Form Name")
                        .font(.headline)
                    MultilineTextEditor(text: $template.title, minimumHeight: 42)
                    Text("All text areas accept typed, pasted, and copied text. They wrap and grow as you add lines.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Form Elements")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    addElementMenu
                }

                if template.elements.isEmpty {
                    ContentUnavailableView(
                        "No Elements Yet",
                        systemImage: "plus.rectangle.on.rectangle",
                        description: Text("Use Add Element to add text, a text field, a checkbox, or radio selections."))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 35)
                } else {
                    ForEach($template.elements) { $element in
                        let elementID = element.wrappedValue.id
                        ElementEditor(element: $element) {
                            template.elements.removeAll { $0.id == elementID }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 850, alignment: .leading)
        }
    }

    private var addElementMenu: some View {
        Menu {
            ForEach(FormElementKind.allCases) { kind in
                Button(kind.displayName) {
                    template.elements.append(newElement(of: kind))
                }
            }
        } label: {
            Label("Add Element", systemImage: "plus")
        }
    }

    private func newElement(of kind: FormElementKind) -> FormElement {
        switch kind {
        case .text:
            FormElement(kind: .text, label: "Add your text here")
        case .textField:
            FormElement(kind: .textField, label: "Question or field label")
        case .checkbox:
            FormElement(kind: .checkbox, label: "", selectedOutput: "")
        case .radio:
            FormElement(kind: .radio, label: "Radio selection label", options: ["First choice"])
        }
    }
}

private struct ElementEditor: View {
    @Binding var element: FormElement
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(element.kind.displayName, systemImage: iconName)
                    .font(.headline)
                Spacer()
                Button(role: .destructive, action: delete) {
                    Label("Remove", systemImage: "trash")
                }
                .labelStyle(.iconOnly)
                .help("Remove this element")
            }

            switch element.kind {
            case .text:
                InputCaption("Text shown on the form")
                MultilineTextEditor(text: $element.label, minimumHeight: 70)

            case .textField:
                InputCaption("Field label shown to the person filling out the form")
                MultilineTextEditor(text: $element.label, minimumHeight: 52)

            case .checkbox:
                InputCaption("Checkbox label *")
                MultilineTextEditor(text: $element.label, minimumHeight: 52)
                InputCaption("Text to export when this checkbox is selected *")
                MultilineTextEditor(text: $element.selectedOutput, minimumHeight: 52)
                if !element.isValid {
                    Text("Both fields are required before this template can be saved.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

            case .radio:
                InputCaption("Radio selection label *")
                MultilineTextEditor(text: $element.label, minimumHeight: 52)
                InputCaption("Choices *")
                ForEach(element.options.indices, id: \.self) { index in
                    HStack(alignment: .top) {
                        MultilineTextEditor(text: optionBinding(at: index), minimumHeight: 42)
                        Button(role: .destructive) {
                            element.options.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .disabled(element.options.count == 1)
                        .help("Remove this choice")
                    }
                }
                Button {
                    element.options.append("New choice")
                } label: {
                    Label("Add Choice", systemImage: "plus.circle")
                }
                if !element.isValid {
                    Text("A radio selection needs a label and at least one non-empty choice.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var iconName: String {
        switch element.kind {
        case .text: "text.alignleft"
        case .textField: "text.cursor"
        case .checkbox: "checkmark.square"
        case .radio: "largecircle.fill.circle"
        }
    }

    private func optionBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { element.options.indices.contains(index) ? element.options[index] : "" },
            set: { newValue in
                guard element.options.indices.contains(index) else { return }
                element.options[index] = newValue
            }
        )
    }
}

private struct InputCaption: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
    }
}

private struct FormFiller: View {
    let template: FormTemplate
    @Binding var textValues: [UUID: String]
    @Binding var checkedValues: Set<UUID>
    @Binding var radioValues: [UUID: String]
    @Binding var includePromptsInExport: Bool
    let showMessage: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(template.title.trimmed.isEmpty ? "Untitled Form" : template.title)
                    .font(.largeTitle.weight(.bold))

                ForEach(template.elements) { element in
                    fillControl(for: element)
                }

                Divider()
                    .padding(.top, 8)

                Toggle("Include field labels and selected-checkbox output text in clipboard export", isOn: $includePromptsInExport)
                    .toggleStyle(.checkbox)

                HStack {
                    Button(action: exportToClipboard) {
                        Label("Export to Clipboard", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("e", modifiers: [.command])

                    Button(role: .destructive, action: clearAll) {
                        Label("Clear All", systemImage: "eraser")
                    }
                    Spacer()
                }
                .padding(.bottom, 18)
            }
            .padding(24)
            .frame(maxWidth: 850, alignment: .leading)
        }
    }

    @ViewBuilder
    private func fillControl(for element: FormElement) -> some View {
        switch element.kind {
        case .text:
            Text(element.label)
                .fixedSize(horizontal: false, vertical: true)

        case .textField:
            VStack(alignment: .leading, spacing: 7) {
                Text(element.label)
                    .font(.headline)
                MultilineTextEditor(text: textBinding(for: element.id), minimumHeight: 72)
            }

        case .checkbox:
            Toggle(element.label, isOn: checkboxBinding(for: element.id))
                .toggleStyle(.checkbox)

        case .radio:
            VStack(alignment: .leading, spacing: 7) {
                Text(element.label)
                    .font(.headline)
                Picker(element.label, selection: radioBinding(for: element.id)) {
                    Text("No selection").tag("")
                    ForEach(element.options.filter { !$0.trimmed.isEmpty }, id: \.self) { choice in
                        Text(choice).tag(choice)
                    }
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }
        }
    }

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding(get: { textValues[id, default: ""] }, set: { textValues[id] = $0 })
    }

    private func checkboxBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { checkedValues.contains(id) },
            set: { isChecked in
                if isChecked {
                    checkedValues.insert(id)
                } else {
                    checkedValues.remove(id)
                }
            }
        )
    }

    private func radioBinding(for id: UUID) -> Binding<String> {
        Binding(get: { radioValues[id, default: ""] }, set: { radioValues[id] = $0 })
    }

    private func exportToClipboard() {
        let lines = template.elements.compactMap { element -> String? in
            switch element.kind {
            case .text:
                nil
            case .textField:
                let value = textValues[element.id, default: ""].trimmed
                guard !value.isEmpty else { return nil }
                return includePromptsInExport ? "\(element.label.trimmed)\n\(value)\n" : "\(value)\n"
            case .checkbox:
                guard checkedValues.contains(element.id) else { return nil }
                return includePromptsInExport ? "\(element.label.trimmed): \(element.selectedOutput.trimmed)" : element.selectedOutput.trimmed
            case .radio:
                let value = radioValues[element.id, default: ""].trimmed
                guard !value.isEmpty else { return nil }
                return includePromptsInExport ? "\(element.label.trimmed): \(value)" : value
            }
        }

        guard !lines.isEmpty else {
            showMessage("There is no filled-out information to export yet.")
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
        showMessage("Copied \(lines.count) item\(lines.count == 1 ? "" : "s") to the clipboard.")
    }

    private func clearAll() {
        textValues = [:]
        checkedValues = []
        radioValues = [:]
    }
}

private struct SettingsView: View {
    @ObservedObject var store: TemplateStore
    @Binding var alertMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.title2.weight(.bold))
            Text("Save templates locally, export them as a shareable JSON file, or import templates that someone else exported.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Button("Save Templates on This Mac", action: save)
            Button("Export Templates…", action: exportTemplates)
                .disabled(store.templates.isEmpty)
            Button("Import Templates…", action: importTemplates)

            Spacer()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500, height: 280)
    }

    private func save() {
        do {
            try store.save()
            dismiss()
            alertMessage = "Templates saved on this Mac."
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func exportTemplates() {
        let panel = NSSavePanel()
        panel.title = "Export Form Templates"
        panel.nameFieldStringValue = "custom-form-templates.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.exportTemplates(to: url)
            dismiss()
            alertMessage = "Templates exported successfully."
        } catch {
            alertMessage = "Unable to export templates: \(error.localizedDescription)"
        }
    }

    private func importTemplates() {
        let panel = NSOpenPanel()
        panel.title = "Import Form Templates"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.importTemplates(from: url)
            try store.save()
            dismiss()
            alertMessage = "Templates imported and saved on this Mac."
        } catch {
            alertMessage = "Unable to import templates: \(error.localizedDescription)"
        }
    }
}
