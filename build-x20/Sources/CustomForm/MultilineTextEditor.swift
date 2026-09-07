import AppKit
import SwiftUI

/// A native NSTextView that grows with wrapped lines and returns plain text.
/// NSTextView keeps the usual macOS copy, cut, paste, undo, and spell-checking behavior.
struct MultilineTextEditor: NSViewRepresentable {
    @Binding var text: String
    var minimumHeight: CGFloat = 56

    func makeNSView(context: Context) -> AutoGrowingTextView {
        let view = AutoGrowingTextView(minimumHeight: minimumHeight)
        view.textView.delegate = context.coordinator
        view.textView.string = text
        return view
    }

    func updateNSView(_ nsView: AutoGrowingTextView, context: Context) {
        context.coordinator.parent = self
        if nsView.textView.string != text {
            nsView.textView.string = text
        }
        nsView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultilineTextEditor

        init(parent: MultilineTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            textView.superview?.invalidateIntrinsicContentSize()
        }
    }
}

final class AutoGrowingTextView: NSView {
    let textView = NSTextView()
    private let minimumHeight: CGFloat

    init(minimumHeight: CGFloat) {
        self.minimumHeight = minimumHeight
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = NSSize(width: 7, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true

        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return NSSize(width: NSView.noIntrinsicMetric, height: minimumHeight)
        }
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = ceil(layoutManager.usedRect(for: textContainer).height)
        let height = max(minimumHeight, usedHeight + textView.textContainerInset.height * 2)
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }
}
