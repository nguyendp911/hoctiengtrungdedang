import SwiftUI
import WebKit

/// Màn hình luyện viết: xem thứ tự nét, tập tô theo nét mờ, tự viết không gợi ý.
/// Nét chữ dùng thư viện Hanzi Writer (tải từ mạng lần đầu cho mỗi chữ).
struct WritingView: View {
    let phrase: Phrase

    @Environment(\.dismiss) private var dismiss
    @StateObject private var board: WritingBoard
    @State private var selected: String

    private let characters: [String]

    init(phrase: Phrase) {
        self.phrase = phrase
        let chars = phrase.hanzi
            .filter { $0.unicodeScalars.contains { $0.properties.isIdeographic } }
            .map(String.init)
        let first = chars.first ?? "你"
        characters = chars.isEmpty ? [first] : chars
        _selected = State(initialValue: first)
        _board = StateObject(wrappedValue: WritingBoard(character: first))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(phrase.pinyin).font(.title3).foregroundStyle(.red)
                    Text(phrase.meaningVi).font(.subheadline).foregroundStyle(.secondary)
                }

                if characters.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(characters, id: \.self) { char in
                                Button(char) { selected = char }
                                    .font(.title2.weight(selected == char ? .bold : .regular))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        selected == char ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                WritingBoardView(board: board)
                    .frame(height: 380)

                HStack(spacing: 10) {
                    actionButton("Xem nét", icon: "play.fill") { board.run("animate()") }
                    actionButton("Tập tô", icon: "pencil.and.outline") { board.run("quiz(true)") }
                    actionButton("Tự viết", icon: "pencil") { board.run("quiz(false)") }
                }
                .padding(.horizontal)

                Button {
                    Speaker.shared.speak(selected)
                } label: {
                    Label("Nghe chữ \(selected)", systemImage: "speaker.wave.2.fill")
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .navigationTitle("Luyện viết")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                }
            }
        }
        // Vuốt xuống để đóng sẽ tranh với nét viết, nên chỉ đóng bằng nút "Xong"
        .interactiveDismissDisabled()
        .onChange(of: selected) { board.show(selected) }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

/// Dữ liệu nét chữ đóng gói sẵn trong app (strokes.json)
enum StrokeStore {
    private static let all: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "strokes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return object
    }()

    static func json(for char: String) -> String? {
        guard let entry = all[char],
              let data = try? JSONSerialization.data(withJSONObject: entry)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

@MainActor
final class WritingBoard: ObservableObject {
    let webView: WKWebView

    init(character: String) {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        // Thư viện và dữ liệu nét nằm sẵn trong app nên dùng được khi không có mạng.
        // Chữ nào chưa có sẵn thì thư viện tự tải từ mạng.
        let libTag: String
        if let url = Bundle.main.url(forResource: "hanzi-writer.min", withExtension: "js"),
           let lib = try? String(contentsOf: url, encoding: .utf8) {
            libTag = "<script>\(lib)</script>"
        } else {
            libTag = "<script src=\"https://cdn.jsdelivr.net/npm/hanzi-writer@3.5.0/dist/hanzi-writer.min.js\"></script>"
        }
        let html = Self.html
            .replacingOccurrences(of: "__LIB__", with: libTag)
            .replacingOccurrences(of: "__CHAR__", with: character)
            .replacingOccurrences(of: "__DATA__", with: StrokeStore.json(for: character) ?? "null")
        webView.loadHTMLString(html, baseURL: URL(string: "https://cdn.jsdelivr.net"))
    }

    func run(_ script: String) {
        webView.evaluateJavaScript(script)
    }

    func show(_ char: String) {
        run("make('\(char)', \(StrokeStore.json(for: char) ?? "null"))")
    }

    private static let html = """
    <!doctype html>
    <html><head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
    <style>
      :root { color-scheme: light dark; --msg: #6e6e73; --frame: #d9534f; }
      @media (prefers-color-scheme: dark) { :root { --msg: #a1a1a6; } }
      html, body { margin: 0; background: transparent; overflow: hidden;
        font-family: -apple-system, sans-serif; -webkit-user-select: none; user-select: none;
        touch-action: none; -webkit-touch-callout: none; }
      #wrap { position: relative; margin: 0 auto; }
      #grid, #target { position: absolute; inset: 0; }
      #msg { text-align: center; color: var(--msg); font-size: 15px; min-height: 22px; margin-top: 12px; padding: 0 16px; }
    </style>
    </head><body>
    <div id="wrap">
      <svg id="grid" viewBox="0 0 100 100" preserveAspectRatio="none">
        <rect x="0.5" y="0.5" width="99" height="99" fill="none" style="stroke: var(--frame)" stroke-width="1" opacity="0.7"/>
        <g style="stroke: var(--frame)" stroke-width="0.4" stroke-dasharray="2 2" opacity="0.5">
          <line x1="50" y1="0" x2="50" y2="100"/><line x1="0" y1="50" x2="100" y2="50"/>
          <line x1="0" y1="0" x2="100" y2="100"/><line x1="100" y1="0" x2="0" y2="100"/>
        </g>
      </svg>
      <div id="target"></div>
    </div>
    <div id="msg"></div>
    __LIB__
    <script>
      const size = Math.min(window.innerWidth - 32, 330);
      const wrap = document.getElementById('wrap');
      wrap.style.width = size + 'px';
      wrap.style.height = size + 'px';
      const dark = matchMedia('(prefers-color-scheme: dark)').matches;
      let writer = null;

      function msg(text) { document.getElementById('msg').textContent = text; }

      function make(char, data) {
        if (typeof HanziWriter === 'undefined') { msg('Không tải được bộ nét chữ. Kiểm tra mạng.'); return; }
        document.getElementById('target').innerHTML = '';
        msg('Đang tải nét chữ…');
        writer = HanziWriter.create('target', char, {
          ...(data ? { charDataLoader: (c, ok) => ok(data) } : {}),
          width: size, height: size, padding: 12,
          strokeColor: dark ? '#f2f2f7' : '#1c1c1e',
          radicalColor: '#e0484a',
          outlineColor: dark ? '#48484a' : '#d1d1d6',
          drawingColor: '#2f80ed', drawingWidth: 22,
          strokeAnimationSpeed: 1, delayBetweenStrokes: 300,
          onLoadCharDataSuccess: () => msg('Bấm "Xem nét" để xem thứ tự viết'),
          onLoadCharDataError: () => msg('Không tải được nét của chữ này. Kiểm tra mạng.')
        });
      }

      function animate() {
        if (!writer) return;
        writer.cancelQuiz();
        writer.showCharacter();
        msg('Thứ tự các nét (bộ thủ màu đỏ)');
        writer.animateCharacter({ onComplete: () => msg('Bấm "Tập tô" để viết theo nét mờ') });
      }

      function quiz(withHint) {
        if (!writer) return;
        writer.cancelQuiz();
        writer.hideCharacter();
        if (withHint) { writer.showOutline(); } else { writer.hideOutline(); }
        msg(withHint ? 'Tô theo nét mờ, bắt đầu từ nét 1' : 'Tự viết chữ vào ô, bắt đầu từ nét 1');
        writer.quiz({
          showHintAfterMisses: withHint ? 2 : 3,
          highlightOnComplete: true,
          onCorrectStroke: d => msg('Đúng! Còn ' + d.strokesRemaining + ' nét'),
          onMistake: d => msg('Chưa đúng, thử lại nét ' + (d.strokeNum + 1)),
          onComplete: s => {
            writer.showOutline();
            msg(s.totalMistakes === 0 ? 'Tuyệt vời! Không sai nét nào' : 'Hoàn thành, sai ' + s.totalMistakes + ' lần');
          }
        });
      }

      make('__CHAR__', __DATA__);
    </script>
    </body></html>
    """
}

struct WritingBoardView: UIViewRepresentable {
    let board: WritingBoard

    func makeUIView(context: Context) -> WKWebView { board.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
