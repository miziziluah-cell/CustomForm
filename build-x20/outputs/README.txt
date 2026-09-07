Custom Form — offline macOS app

Open CustomForm.app to launch the bundled native window. No web server,
account, Node.js, or download is used.

Use the Templates sidebar to create and rename templates or nested sections,
then move the selected template in or out of a section. Use Build mode to add
static text, multiline text fields, checkboxes, and radio selections. Use Save
to keep templates on this Mac. In Build mode, drag an element's ⠿ handle to
move it above or below another element. A Break element displays a divider and
can export any chosen character 1–60 times, with a blank line above, below, or
neither.

Each Static Text element has an optional “Include this static text in clipboard
export” setting in Build mode; it is off by default.

A Code element displays read-only, formatted code in Fill Out mode and provides
a Copy Code button to its left. It also has an optional clipboard-export setting.

Each Text Field can export its entered text after two spaces on the label line,
either with or without a blank line after it, or on a new line directly
underneath the label. “Question or field label” is Build-mode placeholder text,
not text shown to the person filling out the form.

The starter text for Static Text, Code, and Radio selections is likewise
Build-mode placeholder text only.

Build mode keeps the boxed Form Name and Form Elements toolbar pinned above the
element cards while you scroll.

Text Fields can also show optional custom placeholder text in Fill Out mode;
the placeholder disappears as soon as the person types.

Each Checkbox can optionally add a blank line after its selected export text.

When the window is narrow, use the ☰ menu at the top left to open and close
the Templates sidebar.

Save writes the selected template as JSON to
~/Library/Application Support/Custom Form/Saved Templates. Load opens that
folder first, then lets you choose any JSON template file to import.

Save All writes a complete workspace snapshot—every section, template, order,
and current template selection. Loading that snapshot restores the workspace
exactly rather than merging it with the current one.
Settings includes JSON export/import to share templates.

Use Fill Out mode to enter information, copy it with Export to Clipboard, and
start again with Clear All.
