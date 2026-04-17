import Foundation

struct TextMessage: Codable {
    let type: String
    let content: String
    let timestamp: Int64
    
    init(content: String) {
        self.type = "text"
        self.content = content
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}