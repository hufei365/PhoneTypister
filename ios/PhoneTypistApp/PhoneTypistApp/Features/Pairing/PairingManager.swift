import Foundation

class PairingManager {
    static let shared = PairingManager()
    
    private let pairedDevicesKey = "pairedDevices"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func savePairedDevice(_ device: PairedDevice) {
        var devices = loadPairedDevices()
        
        // Remove existing device with same IP
        devices.removeAll { $0.ipAddress == device.ipAddress }
        
        // Add new device
        devices.append(device)
        
        // Save to UserDefaults
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(devices) {
            defaults.set(data, forKey: pairedDevicesKey)
        }
    }
    
    func loadPairedDevices() -> [PairedDevice] {
        guard let data = defaults.data(forKey: pairedDevicesKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return (try? decoder.decode([PairedDevice].self, from: data)) ?? []
    }
    
    func getMostRecentDevice() -> PairedDevice? {
        let devices = loadPairedDevices()
        return devices.sorted { $0.pairedAt > $1.pairedAt }.first
    }
    
    func removePairedDevice(_ device: PairedDevice) {
        var devices = loadPairedDevices()
        devices.removeAll { $0.ipAddress == device.ipAddress }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(devices) {
            defaults.set(data, forKey: pairedDevicesKey)
        }
    }
    
    func clearAllPairedDevices() {
        defaults.removeObject(forKey: pairedDevicesKey)
    }
    
    func hasPairedDevice() -> Bool {
        return loadPairedDevices().count > 0
    }
}