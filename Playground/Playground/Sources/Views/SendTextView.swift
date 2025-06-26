import SwiftUI
#if os(iOS)
import UIKit

    struct SendTextView: UIViewRepresentable {
        @Binding var text: String
        var onSend: () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> UITextView {
            let tv = UITextView()
            tv.delegate = context.coordinator
            tv.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
            tv.isScrollEnabled = false
            tv.returnKeyType = .send
            tv.backgroundColor = .clear
            tv.textContainerInset = .zero
            tv.textContainer.lineFragmentPadding = 0
            tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return tv
        }

        func updateUIView(_ uiView: UITextView, context: Context) {
            if uiView.text != text {
                uiView.text = text
            }
            uiView.isEditable = !context.environment.isEnabled ? false : true
        }

        class Coordinator: NSObject, UITextViewDelegate {
            var parent: SendTextView
            init(parent: SendTextView) { self.parent = parent }

            func textView(
                _ textView: UITextView, shouldChangeTextIn range: NSRange,
                replacementText text: String
            ) -> Bool {
                if text == "\n" {
                    parent.onSend()
                    return false
                }
                return true
            }

            func textViewDidChange(_ textView: UITextView) {
                parent.text = textView.text
            }
        }
    }
#endif
