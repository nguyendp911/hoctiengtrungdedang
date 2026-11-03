import SwiftUI
import UIKit

/// Tab "Cài đặt": nhắc học, cập nhật từ, hướng dẫn widget, xoá tiến độ
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 20 * 60
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @State private var permissionDenied = false
    @State private var confirmReset = false

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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Mục tiêu: \(dailyGoal) câu mỗi ngày", value: $dailyGoal, in: 5...100, step: 5)
                } header: {
                    Text("Mục tiêu")
                } footer: {
                    Text("Mỗi câu trả lời trong ôn tập, thẻ lật hoặc luyện nghe được tính là một câu.")
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
                    Button("Xoá tiến độ học", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Đặt lại các từ đã thuộc, lịch ôn và chuỗi ngày học.")
                }
            }
            .navigationTitle("Cài đặt")
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
