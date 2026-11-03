import AVFoundation

/// Phát âm tiếng Trung bằng giọng đọc có sẵn của iOS (không cần mạng).
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, slow: Bool = false) {
        // .playback để vẫn nghe được khi gạt công tắc im lặng
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = slow ? 0.25 : 0.42
        synthesizer.speak(utterance)
    }
}
