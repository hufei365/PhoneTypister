import UIKit

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .error:
            return "Error"
        }
    }
    
    var statusColor: UIColor {
        switch self {
        case .disconnected:
            return .systemGray
        case .connecting:
            return .systemOrange
        case .connected:
            return .systemGreen
        case .error:
            return .systemRed
        }
    }
}