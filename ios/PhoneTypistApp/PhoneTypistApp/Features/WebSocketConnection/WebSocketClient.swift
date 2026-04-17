import Foundation
import Starscream

protocol WebSocketClientDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: Error?)
    func webSocketDidReceiveMessage(_ message: String)
    func webSocketDidChangeState(_ state: ConnectionState)
}

class PhoneTypistWebSocket: WebSocketDelegate {
    private var socket: WebSocket?
    private var urlString: String?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    private var isConnected = false
    
    weak var delegate: WebSocketClientDelegate?
    
    var connectionState: ConnectionState = .disconnected
    
    func connect(to device: PairedDevice) {
        urlString = "ws://\(device.ipAddress):\(device.port)"
        connect()
    }
    
    func connect(to urlString: String) {
        self.urlString = urlString
        connect()
    }
    
    private func connect() {
        guard let urlString = urlString else { return }
        
        connectionState = .connecting
        delegate?.webSocketDidChangeState(.connecting)
        
        guard let url = URL(string: urlString) else {
            connectionState = .error
            delegate?.webSocketDidChangeState(.error)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func disconnect() {
        stopReconnectTimer()
        socket?.disconnect()
        socket = nil
        connectionState = .disconnected
        delegate?.webSocketDidChangeState(.disconnected)
    }
    
    func sendText(_ text: String) {
        let message = TextMessage(content: text)
        guard let jsonString = message.toJSONString() else {
            print("Failed to encode message")
            return
        }
        
        socket?.write(string: jsonString)
    }
    
    // WebSocketDelegate methods
    func didReceive(event: WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected:
            print("WebSocket connected")
            isConnected = true
            reconnectAttempts = 0
            connectionState = .connected
            delegate?.webSocketDidConnect()
            delegate?.webSocketDidChangeState(.connected)
            
        case .disconnected(let reason, let code):
            print("WebSocket disconnected: \(reason) (code: \(code))")
            isConnected = false
            connectionState = .disconnected
            delegate?.webSocketDidDisconnect(error: nil)
            delegate?.webSocketDidChangeState(.disconnected)
            attemptReconnect()
            
        case .text(let text):
            print("Received: \(text)")
            delegate?.webSocketDidReceiveMessage(text)
            
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "unknown")")
            isConnected = false
            connectionState = .error
            delegate?.webSocketDidDisconnect(error: error)
            delegate?.webSocketDidChangeState(.error)
            attemptReconnect()
            
        case .cancelled:
            print("WebSocket cancelled")
            isConnected = false
            connectionState = .disconnected
            delegate?.webSocketDidDisconnect(error: nil)
            delegate?.webSocketDidChangeState(.disconnected)
            
        default:
            break
        }
    }
    
    private func attemptReconnect() {
        if reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            let delay = min(2.0 * Double(reconnectAttempts), 10.0)
            
            print("Attempting reconnect in \(delay) seconds (attempt \(reconnectAttempts))")
            
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.connect()
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}