import Foundation
import uzu_plusFFI

extension Message {
    public init(role: Role, content: String) {
        self.init(role: role, content: content, reasoningContent: nil)
    }
}
