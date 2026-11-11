import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Tab "Cài đặt": nhắc học, cập nhật từ, hướng dẫn widget, xoá tiến độ
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 20 * 60
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @AppStorage("newPerDay") private var newPerDay = 5
    @State private var permissionDenied = false
    @State private var confirmReset = false
    @State private var importing = false
    @State private var backupMessage: String?

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60,
                                      second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (c.hour ?? 20) * 60 + (c.minute ?? 0)
                Task { await Reminder.schedule(minutes: reminderMinutes, phrases: model.phrases) }
            }
        )
    }

    /// Ghi bản sao lưu ra file tạm để chia sẻ
    private func backupFileURL() -> URL? {
        guard let data = ProgressStore.exportBackup() else { return nil }
        let day = Date().formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("HanTu-tiendo-\(day).json")
        return (try? data.write(to: url, options: .atomic)) != nil ? url : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Từ mới mỗi ngày: \(newPerDay)", value: $newPerDay, in: 1...30)
                    Stepper("Mục tiêu: \(dailyGoal) câu mỗi ngày", value: $dailyGoal, in: 5...100, step: 5)
                } header: {
                    Text("Kế hoạch học")
                } footer: {
                    Text("Từ mới mỗi ngày dùng cho tab Lộ trình và ước tính ngày hoàn thành mỗi cấp HSK. Mỗi câu trả lời trong ôn tập, thẻ lật hoặc luyện nghe được tính là một câu.")
                }

                Section {
                    Toggle("Nhắc học mỗi ngày", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Giờ nhắc", selection: timeBinding, displayedComponents: .hourAndMinute)
                    }
                    if permissionDenied {
                        Button("Bật thông báo trong Cài đặt iPhone") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } header: {
                    Text("Nhắc nhở")
                } footer: {
                    Text("Mỗi ngày một từ mới hiện ngay trong thông báo. Hôm nào bạn đã học rồi thì không nhắc.")
                }

                Section {
                    Button {
                        Task { await model.update() }
                    } label: {
                        HStack {
                            Text("Cập nhật từ mới")
                            Spacer()
                            if model.isUpdating { ProgressView() }
                        }
                    }
                    if let status = model.status {
                        Text(status).font(.footnote).foregroundStyle(.secondary)
                    }
                    LabeledContent("Tổng số từ", value: "\(model.phrases.count)")
                } header: {
                    Text("Từ vựng")
                } footer: {
                    Text("Danh sách từ lấy từ GitHub, app tự cập nhật mỗi lần mở.")
                }

                Section("Thêm widget vào màn hình khoá") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Giữ ngón tay lên màn hình khoá, bấm Tuỳ chỉnh.")
                        Text("2. Chạm ô dưới đồng hồ, chọn Hán Tự.")
                        Text("3. Muốn đổi chủ đề: chạm vào widget rồi chọn Chủ đề.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Section {
                    if let url = backupFileURL() {
                        ShareLink(item: url) { Label("Sao lưu tiến độ", systemImage: "square.and.arrow.up") }
                    }
                    Button { importing = true } label: { Label("Khôi phục từ file", systemImage: "square.and.arrow.down") }
                    if let backupMessage {
                        Text(backupMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Sao lưu")
                } footer: {
                    Text("Lưu file vào Tệp hoặc iCloud Drive để không mất tiến độ khi cài lại app hay đổi máy. Khôi phục sẽ ghi đè tiến độ hiện tại.")
                }

                Section {
                    Button("Xoá tiến độ học", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Đặt lại các từ đã thuộc, lịch ôn và chuỗi ngày học.")
                }
            }
            .navigationTitle("Cài đặt")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                guard case .success(let url) = result else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url), ProgressStore.importBackup(data) {
                    model.reloadProgress()
                    backupMessage = "Đã khôi phục tiến độ."
                } else {
                    backupMessage = "File sao lưu không hợp lệ."
                }
            }
            .confirmationDialog("Xoá toàn bộ tiến độ học?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Xoá tiến độ", role: .destructive) {
                    ProgressStore.resetAll()
                    model.reloadProgress()
                }
            }
            .onChange(of: reminderEnabled) {
                if reminderEnabled {
                    Task {
                        if await Reminder.requestPermission() {
                            permissionDenied = false
                            await Reminder.schedule(minutes: reminderMinutes, phrases: model.phrases)
                        } else {
                            reminderEnabled = false
                            permissionDenied = true
                        }
                    }
                } else {
                    Reminder.cancel()
                }
            }
        }
    }
}
