import Speech
import AVFoundation

/// Nghe người dùng đọc và nhận dạng thành chữ bằng giọng tiếng Trung của iOS.
final class SpeechChecker: ObservableObject {
    enum Phase { case idle, listening, processing, finished, denied, unavailable }

    @Published var phase: Phase = .idle
    @Published var heard = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var generation = 0

    func toggle() {
        if phase == .listening {
            stopListening()
        } else if phase != .processing {
            requestAndStart()
        }
    }

    func reset() {
        generation += 1
        cleanup()
        phase = .idle
        heard = ""
    }

    private func requestAndStart() {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async { self.phase = .denied }
                return
            }
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { self.begin() } else { self.phase = .denied }
                }
            }
        }
    }

    private func begin() {
        guard let recognizer, recognizer.isAvailable else {
            phase = .unavailable
            return
        }
        cleanup()
        generation += 1
        let current = generation

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            phase = .unavailable
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            cleanup()
            phase = .unavailable
            return
        }

        heard = ""
        phase = .listening
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            DispatchQueue.main.async {
                guard let self, self.generation == current else { return }
                if let text { self.heard = text }
                if isFinal || failed { self.finish() }
            }
        }

        // Tự dừng sau 8 giây nếu người dùng quên bấm dừng
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            guard let self, self.generation == current else { return }
            self.stopListening()
        }
    }

    private func stopListening() {
        guard phase == .listening else { return }
        phase = .processing
        let current = generation
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        // Phòng khi không nhận được kết quả cuối
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, self.generation == current else { return }
            self.finish()
        }
    }

    private func finish() {
        guard phase == .listening || phase == .processing else { return }
        cleanup()
        phase = .finished
    }

    private func cleanup() {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }
}

/// Chấm độ giống nhau giữa câu nghe được và câu mẫu.
enum SpeechScore {
    /// 0...1. Đúng chữ hoặc đúng cả pinyin có dấu = 1; chỉ đúng âm (sai thanh) bị trừ điểm.
    static func evaluate(heard: String, target: String) -> Double {
        let h = clean(heard)
        let t = clean(target)
        guard !h.isEmpty, !t.isEmpty else { return 0 }
        let exact = similarity(h, t)
        let tonedH = pinyin(h)
        let tonedT = pinyin(t)
        let toned = similarity(tonedH, tonedT)
        let toneless = similarity(strip(tonedH), strip(tonedT)) * 0.85
        return max(exact, toned, toneless)
    }

    static func pinyin(_ s: String) -> String {
        let latin = s.applyingTransform(.mandarinToLatin, reverse: false) ?? s
        return latin.precomposedStringWithCanonicalMapping.lowercased().filter { $0.isLetter }
    }

    private static func strip(_ s: String) -> String {
        s.applyingTransform(.stripDiacritics, reverse: false) ?? s
    }

    private static func clean(_ s: String) -> String {
        s.filter { $0.isLetter || $0.isNumber }
    }

    private static func similarity(_ a: String, _ b: String) -> Double {
        let x = Array(a)
        let y = Array(b)
        guard !x.isEmpty, !y.isEmpty else { return 0 }
        var prev = Array(0...y.count)
        for i in 1...x.count {
            var cur = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1))
            }
            prev = cur
        }
        return 1 - Double(prev[y.count]) / Double(max(x.count, y.count))
    }
}
