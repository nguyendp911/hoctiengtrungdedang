import AVFoundation

/// Cài đặt giọng đọc, lưu trong App Group để app, widget và Siri dùng chung một giọng.
enum SpeechSettings {
    static let voiceKey = "speechVoiceID"
    static let rateKey = "speechRate"
    /// Tốc độ mặc định (thang 0...1 của AVSpeechUtterance, mặc định hệ thống là 0,5)
    static let defaultRate: Float = 0.42
    static let rateRange: ClosedRange<Float> = 0.30...0.55
    /// Câu nghe thử
    static let sampleText = "你好，欢迎学习中文。"

    static var store: UserDefaults {
        UserDefaults(suiteName: ProgressStore.groupID) ?? .standard
    }

    static var rate: Float {
        let value = store.object(forKey: rateKey) as? Double
        return value.map { clampedRate(Float($0)) } ?? defaultRate
    }

    static func clampedRate(_ value: Float) -> Float {
        min(max(value, rateRange.lowerBound), rateRange.upperBound)
    }

    /// Tốc độ khi bấm "Đọc chậm": khoảng 60% tốc độ thường, nhưng không chậm đến mức méo tiếng
    static func slowRate(from normal: Float) -> Float {
        max(0.22, normal * 0.6)
    }

    /// Mức chất lượng của giọng: 1 = cơ bản, 2 = nâng cao, 3 = cao cấp
    static func qualityRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium: return 3
        case .enhanced: return 2
        default: return 1
        }
    }

    static func qualityLabel(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch qualityRank(quality) {
        case 3: return "Cao cấp"
        case 2: return "Nâng cao"
        default: return "Cơ bản"
        }
    }

    /// Các giọng tiếng Trung phổ thông (zh-CN) có trên máy, giọng tốt nhất đứng đầu
    static func availableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "zh-CN" }
            .sorted { a, b in
                let (ra, rb) = (qualityRank(a.quality), qualityRank(b.quality))
                return ra != rb ? ra > rb : a.name < b.name
            }
    }

    /// Giọng đang dùng: giọng người dùng chọn nếu còn trên máy, không thì giọng tốt nhất có sẵn
    static func currentVoice() -> AVSpeechSynthesisVoice? {
        let voices = availableVoices()
        if let id = store.string(forKey: voiceKey), !id.isEmpty,
           let chosen = voices.first(where: { $0.identifier == id }) {
            return chosen
        }
        return voices.first ?? AVSpeechSynthesisVoice(language: "zh-CN")
    }
}

/// Phát âm tiếng Trung bằng giọng đọc có sẵn của iOS (không cần mạng).
/// Dùng giọng chất lượng cao nhất trên máy (Cao cấp > Nâng cao > Cơ bản) trừ khi người dùng chọn giọng khác.
@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speak(_ text: String, slow: Bool = false) {
        // .playback để vẫn nghe được khi gạt công tắc im lặng
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = SpeechSettings.currentVoice()
        let normal = SpeechSettings.rate
        utterance.rate = slow ? SpeechSettings.slowRate(from: normal) : normal
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        // Nghỉ một chút trước khi đọc để thiết bị âm thanh kịp bật, tránh mất âm đầu
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    // Đọc xong thì trả âm lượng lại cho nhạc/podcast đang phát
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard !self.synthesizer.isSpeaking else { return }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
