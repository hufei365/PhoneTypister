import Foundation
import Speech
import AVFoundation

protocol SpeechRecognitionDelegate: AnyObject {
    func speechRecognitionDidUpdate(_ text: String, isFinal: Bool)
    func speechRecognitionDidFail(error: Error)
    func speechRecognitionDidStop()
    func speechRecognitionAvailabilityChanged(_ available: Bool)
}

class SpeechRecognitionManager: NSObject {
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var recordingStartTime: Date?
    private let minimumRecordingDuration: TimeInterval = 0.5
    
    weak var delegate: SpeechRecognitionDelegate?
    
    private(set) var isListening = false
    private(set) var isAvailable = true
    
    private func isIgnorableSpeechError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        if nsError.domain == "kLSRErrorDomain" {
            switch nsError.code {
            case 201, 203, 301, 302, 303, 1110:
                return true
            default:
                break
            }
        }
        
        if nsError.domain == "AVFoundationErrorDomain" {
            if nsError.code == -11800 || nsError.code == -11819 {
                return true
            }
        }
        
        let description = error.localizedDescription.lowercased()
        if description.contains("no speech") || 
           description.contains("speech detected") ||
           description.contains("audio") ||
           description.contains("silence") {
            return true
        }
        
        return false
    }
    
    private func shouldReportError(_ error: Error) -> Bool {
        if isIgnorableSpeechError(error) {
            return false
        }
        
        if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            if duration < minimumRecordingDuration {
                return false
            }
        }
        
        return true
    }
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        
        // Check initial availability
        isAvailable = speechRecognizer?.isAvailable ?? false
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission(completionHandler: { micStatus in
                    DispatchQueue.main.async {
                        completion(speechStatus == .authorized && micStatus)
                    }
                })
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { micStatus in
                    DispatchQueue.main.async {
                        completion(speechStatus == .authorized && micStatus)
                    }
                }
            }
        }
    }
    
    func startListening() throws {
        if isListening { return }
        
        guard isAvailable else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not available"])
        }
        
        stopListening()
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recordingStartTime = Date()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                
                self.delegate?.speechRecognitionDidUpdate(text, isFinal: isFinal)
                
                if isFinal {
                    self.stopListening()
                }
            }
            
            if let error = error {
                if self.shouldReportError(error) {
                    self.delegate?.speechRecognitionDidFail(error: error)
                }
                self.stopListening()
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.connect(inputNode, to: audioEngine.mainMixerNode, format: recordingFormat)
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
    }
    
    func stopListening() {
        if !isListening { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        isListening = false
        delegate?.speechRecognitionDidStop()
    }
    
    func changeLocale(to locale: Locale) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        speechRecognizer?.delegate = self
        isAvailable = speechRecognizer?.isAvailable ?? false
    }
}

// SFSpeechRecognizerDelegate
extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ recognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isAvailable = available
        delegate?.speechRecognitionAvailabilityChanged(available)
    }
}