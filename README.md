# CustomForm

CustomForm is a native, offline macOS application for building reusable forms and completing them in a consistent format. It supports nested template sections and form elements such as static text, text fields, checkboxes, radio selections, dividers, and read-only code blocks.

Use **Build** mode to create or update templates, arrange elements, and configure their export behavior. Use **Fill Out** mode to enter values and copy a completed form to the clipboard. Templates can be saved locally, imported or exported as JSON, and preserved together through complete workspace snapshots.

The application does not need a web server, account, Node.js, or any external download to run. Launch the bundled `CustomForm.app` from `build-x20/outputs/`; for source development, open the Swift package in `build-x20/` and build it with Xcode or Swift 6 on macOS 14 or later.

The `Json/` directory contains shareable workspace snapshots for the team. The included `custom-form-workspace-2.json` is a complete snapshot with templates, sections, ordering, and the selected template; import it through the app's workspace load option to restore it as authored.