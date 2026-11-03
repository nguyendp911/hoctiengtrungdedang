import SwiftUI

struct RootView: View {
    @StateObject private var model = AppModel()
    @State private var tab = 0
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 20 * 60

    var body: some View {
        TabView(selection: $tab) {
            LearnView()
                .tabItem { Label("Học", systemImage: "book.fill") }
                .tag(0)
            ReviewView()
                .tabItem { Label("Ôn tập", systemImage: "checklist") }
                .badge(model.dueCount)
                .tag(1)
            SettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .environmentObject(model)
        .onOpenURL { url in
            // hanzilock://phrase/<id> — được mở khi chạm vào widget
            guard url.host == "phrase",
                  let id = Int(url.lastPathComponent),
                  let tapped = model.phrases.first(where: { $0.id == id }) else { return }
            tab = 0
            model.picked = tapped
            Speaker.shared.speak(tapped.hanzi)
        }
        .task {
            await model.update(silent: true)
            await rescheduleReminder()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                model.reloadProgress()
                Task { await rescheduleReminder() }
            }
        }
    }

    private func rescheduleReminder() async {
        guard reminderEnabled else { return }
        await Reminder.schedule(minutes: reminderMinutes, phrases: model.phrases)
    }
}
