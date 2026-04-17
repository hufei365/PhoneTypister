import UIKit
import AVFoundation

protocol QRScannerDelegate: AnyObject {
    func qrScannerDidFindPairingInfo(_ ipAddress: String, port: Int)
    func qrScannerDidFail(error: Error)
    func qrScannerDidCancel()
}

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    weak var delegate: QRScannerDelegate?
    
    private var captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var qrCodeFrameView: UIView?
    
    private let scanAreaSize: CGFloat = 200
    
    // MARK: - UI Elements
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Scan QR code on Windows PC"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scanAreaView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.systemGreen.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 10
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer.frame = view.layer.bounds
        print("🔍 viewDidLayoutSubviews, frame: \(videoPreviewLayer.frame)")
    }
    
    // MARK: - Setup
private func setupScanner() {
        print("🔍 setupScanner called")
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("🔍 Camera not available")
            delegate?.qrScannerDidFail(error: NSError(domain: "QRScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera not available"]))
            return
        }
        
        print("🔍 Got camera device: \(videoCaptureDevice.localizedName)")
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            print("🔍 Failed to create video input")
            delegate?.qrScannerDidFail(error: NSError(domain: "QRScanner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to setup camera input"]))
            return
        }
        
        print("🔍 Created video input")
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            print("🔍 Added video input to session")
        } else {
            print("🔍 Cannot add video input")
            delegate?.qrScannerDidFail(error: NSError(domain: "QRScanner", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to add camera input"]))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        print("🔍 Created metadataOutput")
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            print("🔍 Added metadataOutput to session")
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            print("🔍 Set delegate and metadataObjectTypes to [.qr]")
        } else {
            print("🔍 Cannot add metadata output")
            delegate?.qrScannerDidFail(error: NSError(domain: "QRScanner", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to add metadata output"]))
            return
        }
        
        print("🔍 setupScanner completed successfully")
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        view.addSubview(scanAreaView)
        view.addSubview(instructionLabel)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            scanAreaView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanAreaView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanAreaView.widthAnchor.constraint(equalToConstant: scanAreaSize),
            scanAreaView.heightAnchor.constraint(equalToConstant: scanAreaSize),
            
            instructionLabel.topAnchor.constraint(equalTo: scanAreaView.bottomAnchor, constant: 30),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func calculateRectOfInterest() -> CGRect {
        let centerX = view.bounds.midX
        let centerY = view.bounds.midY
        return CGRect(
            x: centerX - scanAreaSize / 2,
            y: centerY - scanAreaSize / 2,
            width: scanAreaSize,
            height: scanAreaSize
        )
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        delegate?.qrScannerDidCancel()
        dismiss(animated: true)
    }
    
    private func startScanning() {
        print("🔍 startScanning called, captureSession.running: \(captureSession.isRunning)")
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    print("🔍 After startRunning, isRunning: \(self.captureSession.isRunning)")
                    print("🔍 captureSession inputs: \(self.captureSession.inputs.count)")
                    print("🔍 captureSession outputs: \(self.captureSession.outputs.count)")
                    if let output = self.captureSession.outputs.first as? AVCaptureMetadataOutput {
                        print("🔍 metadataObjectTypes: \(String(describing: output.metadataObjectTypes))")
                    }
                }
            }
        }
    }
    
    private func stopScanning() {
        captureSession.stopRunning()
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print("🔍 metadataOutput called, objects: \(metadataObjects.count)")
        
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObj.type == .qr,
              let stringValue = metadataObj.stringValue else {
            print("🔍 No QR code found")
            return
        }
        
        print("🔍 QR code found: \(stringValue)")
        parsePairingInfo(stringValue)
    }
    
    private func parsePairingInfo(_ qrContent: String) {
        print("🔍 parsePairingInfo: \(qrContent)")
        
        let content = qrContent.lowercased()
        print("🔍 content lowercased: \(content)")
        
        if content.hasPrefix("phonetypist://") {
            let urlString = content.replacingOccurrences(of: "phonetypist://", with: "")
            print("🔍 urlString after removing prefix: \(urlString)")
            if let parsed = parseIPAndPort(urlString) {
                print("🔍 Parsed with scheme: ip=\(parsed.ip), port=\(parsed.port)")
                delegate?.qrScannerDidFindPairingInfo(parsed.ip, port: parsed.port)
                stopScanning()
                dismiss(animated: true)
                return
            }
        }
        
        if let parsed = parseIPAndPort(content) {
            print("🔍 Parsed directly: ip=\(parsed.ip), port=\(parsed.port)")
            delegate?.qrScannerDidFindPairingInfo(parsed.ip, port: parsed.port)
            stopScanning()
            dismiss(animated: true)
            return
        }
        
        print("🔍 Failed to parse QR content")
        delegate?.qrScannerDidFail(error: NSError(domain: "QRScanner", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid QR code format"]))
    }
    
    private func parseIPAndPort(_ string: String) -> (ip: String, port: Int)? {
        let parts = string.split(separator: ":")
        print("🔍 parseIPAndPort parts: \(parts)")
        
        guard parts.count == 2,
              let port = Int(parts[1]),
              port > 0 && port < 65536 else {
            print("🔍 parseIPAndPort: port validation failed")
            return nil
        }
        
        let ip = String(parts[0])
        let ipParts = ip.split(separator: ".")
        print("🔍 IP parts: \(ipParts)")
        
        guard ipParts.count == 4 else {
            print("🔍 parseIPAndPort: not 4 IP parts")
            return nil
        }
        
        for part in ipParts {
            guard let num = Int(part), num >= 0 && num <= 255 else {
                print("🔍 parseIPAndPort: IP part invalid: \(part)")
                return nil
            }
        }
        
        print("🔍 parseIPAndPort success: ip=\(ip), port=\(port)")
        return (ip, port)
    }
}