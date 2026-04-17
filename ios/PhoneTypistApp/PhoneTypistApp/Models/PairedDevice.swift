import Foundation

struct PairedDevice: Codable {
    let name: String
    let ipAddress: String
    let port: Int
    let pairedAt: Date
    
    init(name: String, ipAddress: String, port: Int) {
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.pairedAt = Date()
    }
    
    var connectionString: String {
        return "\(ipAddress):\(port)"
    }
}