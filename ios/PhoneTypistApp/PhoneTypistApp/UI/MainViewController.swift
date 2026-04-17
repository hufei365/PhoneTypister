import UIKit
import Speech

class MainViewController: UIViewController {
    
    private var webSocketClient: PhoneTypistWebSocket!
    private var speechManager: SpeechRecognitionManager!
    private var currentTranscript: String = ""
    private var isRecording = false
    
    private let statusIndicator = UIView()
    private let statusLabel = UILabel()
    private let transcriptTextView = UITextView()
    private let micButton = UIButton()
    private let sendButton = UIButton()
    private let pairButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 MainViewController viewDidLoad")
        setupUI()
        setupWebSocket()
        setupSpeechRecognition()
        setupKeyboardHandling()
        checkAndAutoConnect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 MainViewController viewDidAppear - subviews: \(view.subviews.count)")
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "PhoneTypist"
        
        statusIndicator.backgroundColor = .systemGray
        statusIndicator.layer.cornerRadius = 8
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusIndicator)
        
        statusLabel.text = "Disconnected"
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.addSubview(statusLabel)
        
        transcriptTextView.font = .systemFont(ofSize: 18)
        transcriptTextView.layer.borderWidth = 1
        transcriptTextView.layer.borderColor = UIColor.systemGray4.cgColor
        transcriptTextView.layer.cornerRadius = 8
        transcriptTextView.isEditable = true
        transcriptTextView.text = "Tap microphone to start speaking..."
        transcriptTextView.textColor = .systemGray
        transcriptTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transcriptTextView)
        
        let micConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .medium)
        micButton.setImage(UIImage(systemName: "mic.circle.fill", withConfiguration: micConfig), for: .normal)
        micButton.tintColor = .systemBlue
        micButton.backgroundColor = .systemGray6
        micButton.layer.cornerRadius = 60
        micButton.clipsToBounds = true
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.addTarget(self, action: #selector(micButtonTouchedDown), for: .touchDown)
        micButton.addTarget(self, action: #selector(micButtonTouchedUp), for: [.touchUpInside, .touchUpOutside])
        view.addSubview(micButton)
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 8
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        view.addSubview(sendButton)
        
        pairButton.setTitle("Connect", for: .normal)
        pairButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        pairButton.setTitleColor(.systemBlue, for: .normal)
        pairButton.translatesAutoresizingMaskIntoConstraints = false
        pairButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        view.addSubview(pairButton)
        
        NSLayoutConstraint.activate([
            statusIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusIndicator.heightAnchor.constraint(equalToConstant: 40),
            
            statusLabel.centerXAnchor.constraint(equalTo: statusIndicator.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusIndicator.centerYAnchor),
            
            transcriptTextView.topAnchor.constraint(equalTo: statusIndicator.bottomAnchor, constant: 20),
            transcriptTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            transcriptTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            transcriptTextView.heightAnchor.constraint(equalToConstant: 200),
            
            micButton.topAnchor.constraint(equalTo: transcriptTextView.bottomAnchor, constant: 30),
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 120),
            micButton.heightAnchor.constraint(equalToConstant: 120),
            
            sendButton.topAnchor.constraint(equalTo: micButton.bottomAnchor, constant: 30),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 120),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            
            pairButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20),
            pairButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupWebSocket() {
        webSocketClient = PhoneTypistWebSocket()
        webSocketClient.delegate = self
    }
    
    private func setupSpeechRecognition() {
        speechManager = SpeechRecognitionManager()
        speechManager.delegate = self
        
        speechManager.requestPermissions { granted in
            if !granted {
                self.showAlert(title: "Permission Required", message: "Please grant microphone and speech recognition permissions")
            }
        }
    }
    
    private func checkAndAutoConnect() {
        if let device = PairingManager.shared.getMostRecentDevice() {
            updateStatus(.connecting, "Connecting to \(device.name)...")
            webSocketClient.connect(to: device)
        } else {
            updateStatus(.disconnected, "No paired device")
        }
    }
    
    private func updateStatus(_ state: ConnectionState, _ text: String? = nil) {
        statusIndicator.backgroundColor = state.statusColor
        statusLabel.text = text ?? state.displayText
        
        sendButton.isEnabled = state == .connected
        sendButton.backgroundColor = state == .connected ? .systemBlue : .systemGray
    }
    
    @objc private func micButtonTouchedDown() {
        transcriptTextView.textColor = .label
        transcriptTextView.text = ""
        currentTranscript = ""
        
        do {
            try speechManager.startListening()
            let micConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .semibold)
            micButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: micConfig), for: .normal)
            micButton.tintColor = .white
            micButton.backgroundColor = .systemRed
            startRecordingAnimation()
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    @objc private func micButtonTouchedUp() {
        speechManager.stopListening()
        stopRecordingAnimation()
        let micConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .medium)
        micButton.setImage(UIImage(systemName: "mic.circle.fill", withConfiguration: micConfig), for: .normal)
        micButton.tintColor = .systemBlue
        micButton.backgroundColor = .systemGray6
    }
    
    @objc private func sendButtonTapped() {
        dismissKeyboard()
        
        let text = transcriptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, webSocketClient.connectionState == .connected else { return }
        
        webSocketClient.sendText(text)
        
        showSendSuccess()
        transcriptTextView.text = ""
        currentTranscript = ""
    }
    
    @objc private func connectButtonTapped() {
        let alert = UIAlertController(title: "Connect to PC", message: "Enter Windows PC IP address and port", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "IP Address (e.g. 192.168.1.100)"
            textField.keyboardType = .numbersAndPunctuation
            textField.autocorrectionType = .no
            if let savedDevice = PairingManager.shared.getMostRecentDevice() {
                textField.text = savedDevice.ipAddress
            }
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Port (default: 8765)"
            textField.keyboardType = .numberPad
            textField.text = "8765"
        }
        
        alert.addAction(UIAlertAction(title: "Scan QR", style: .default) { _ in
            self.pairButtonTapped()
        })
        
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            let ipTextField = alert.textFields![0]
            let portTextField = alert.textFields![1]
            
            let ipAddress = ipTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let portString = portTextField.text?.trimmingCharacters(in: .whitespaces) ?? "8765"
            let port = Int(portString) ?? 8765
            
            guard !ipAddress.isEmpty else {
                self.showAlert(title: "Error", message: "Please enter IP address")
                return
            }
            
            print("📱 Manual connect: ip=\(ipAddress), port=\(port)")
            let device = PairedDevice(name: "PC", ipAddress: ipAddress, port: port)
            PairingManager.shared.savePairedDevice(device)
            
            self.updateStatus(.connecting, "Connecting to \(ipAddress)...")
            self.webSocketClient.connect(to: device)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func pairButtonTapped() {
        let scanner = QRScannerController()
        scanner.delegate = self
        present(scanner, animated: true)
    }
    
    private func startRecordingAnimation() {
        isRecording = true
        micButton.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.micButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.micButton.alpha = 0.9
        })
    }
    
    private func stopRecordingAnimation() {
        isRecording = false
        micButton.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2, animations: {
            self.micButton.transform = .identity
            self.micButton.alpha = 1.0
        })
    }
    
    private func showSendSuccess() {
        let successView = UIView()
        successView.backgroundColor = .systemGreen
        successView.layer.cornerRadius = 8
        successView.alpha = 0
        successView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Sent!"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        successView.addSubview(label)
        view.addSubview(successView)
        
        NSLayoutConstraint.activate([
            successView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20),
            successView.widthAnchor.constraint(equalToConstant: 80),
            successView.heightAnchor.constraint(equalToConstant: 40),
            label.centerXAnchor.constraint(equalTo: successView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: successView.centerYAnchor)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            successView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1, animations: {
                successView.alpha = 0
            }) { _ in
                successView.removeFromSuperview()
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension MainViewController: WebSocketClientDelegate {
    func webSocketDidConnect() {
        updateStatus(.connected)
    }
    
    func webSocketDidDisconnect(error: Error?) {
        updateStatus(.disconnected, error?.localizedDescription ?? "Disconnected")
    }
    
    func webSocketDidReceiveMessage(_ message: String) {}
    
    func webSocketDidChangeState(_ state: ConnectionState) {
        updateStatus(state)
    }
}

extension MainViewController: SpeechRecognitionDelegate {
    func speechRecognitionDidUpdate(_ text: String, isFinal: Bool) {
        currentTranscript = text
        transcriptTextView.text = text
        transcriptTextView.textColor = .label
    }
    
    func speechRecognitionDidFail(error: Error) {
        showAlert(title: "Recognition Error", message: error.localizedDescription)
        stopRecordingAnimation()
        let micConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .medium)
        micButton.setImage(UIImage(systemName: "mic.circle.fill", withConfiguration: micConfig), for: .normal)
        micButton.tintColor = .systemBlue
        micButton.backgroundColor = .systemGray6
    }
    
    func speechRecognitionDidStop() {}
    
    func speechRecognitionAvailabilityChanged(_ available: Bool) {
        micButton.isEnabled = available
        micButton.tintColor = available ? .systemBlue : .systemGray
        micButton.backgroundColor = available ? .systemGray6 : .systemGray5
    }
}

extension MainViewController: QRScannerDelegate {
    func qrScannerDidFindPairingInfo(_ ipAddress: String, port: Int) {
        print("📱 qrScannerDidFindPairingInfo: ip=\(ipAddress), port=\(port)")
        let device = PairedDevice(name: "PC", ipAddress: ipAddress, port: port)
        PairingManager.shared.savePairedDevice(device)
        
        updateStatus(.connecting, "Connecting...")
        webSocketClient.connect(to: device)
    }
    
    func qrScannerDidFail(error: Error) {
        print("📱 qrScannerDidFail: \(error.localizedDescription)")
        showAlert(title: "Scan Error", message: error.localizedDescription)
    }
    
    func qrScannerDidCancel() {
        print("📱 qrScannerDidCancel")
    }
}