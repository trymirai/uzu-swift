import Foundation
import uzu_plusFFI

extension ParsedText {
    public func structuredResponse<T: Decodable>() -> T? {
        guard let response = self.response else {
            return nil
        }

        let decoder = JSONDecoder()
        let jsonData = Data(response.utf8)
        let entity = try? decoder.decode(T.self, from: jsonData)
        return entity
    }
}
