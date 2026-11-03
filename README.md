# Hán Tự – học tiếng Trung trên màn hình khoá

App iOS hiển thị một từ/câu tiếng Trung trên **màn hình khoá** (widget), mỗi giờ đổi một câu:

- Chữ Hán + pinyin
- Cách đọc bằng tiếng Việt
- Nghĩa tiếng Việt
- Phát âm: chạm vào widget → mở app và tự đọc (giọng zh-CN có sẵn của iOS, không cần mạng)

Yêu cầu: iOS 17 trở lên.

## Cấu trúc

```
project.yml              Cấu hình project (XcodeGen)
Shared/Phrase.swift      Model + chọn câu theo giờ (dùng chung app & widget)
Shared/phrases.json      Danh sách từ/câu – sửa/thêm ở đây
App/                     App chính: thẻ từ, nút phát âm, danh sách
Widget/HanziWidget.swift Widget màn hình khoá / màn hình chính
```

## Build trên GitHub (không cần Mac)

Mỗi lần push lên `main`, GitHub Actions tự build và tạo file `HanziLock-unsigned.ipa`:

1. Vào tab **Actions** của repo › chọn lần chạy mới nhất › mục **Artifacts** › tải `HanziLock-unsigned-ipa` (file .zip, giải nén ra .ipa).
2. Cài [Sideloadly](https://sideloadly.io) trên Windows (kèm iTunes bản tải từ web Apple), cắm iPhone qua cáp.
3. Kéo file .ipa vào Sideloadly, nhập Apple ID, bấm Start.
4. Trên iPhone: Cài đặt › Quyền riêng tư & Bảo mật › bật **Chế độ nhà phát triển**; Cài đặt › Cài đặt chung › VPN & Quản lý thiết bị › tin cậy Apple ID của bạn.

Apple ID miễn phí: app hết hạn sau 7 ngày, cài lại bằng Sideloadly là được.

## Build trên Mac (Xcode 15+)

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open HanziLock.xcodeproj
```

Trong Xcode: chọn target **HanziLock** và **HanziWidget** › Signing & Capabilities › chọn Team (Apple ID miễn phí cũng được), cắm iPhone và bấm Run.

## Thêm widget lên màn hình khoá

Giữ màn hình khoá › **Tuỳ chỉnh** › **Màn hình khoá** › chạm ô widget dưới đồng hồ › chọn **Hán Tự** (kiểu chữ nhật hiển thị đầy đủ nhất).

## Thêm từ mới

Thêm một dòng vào `Shared/phrases.json` (id không trùng):

```json
{ "id": 31, "hanzi": "苹果", "pinyin": "píngguǒ", "readingVi": "pính của", "meaningVi": "Quả táo" }
```

Muốn đổi tần suất, sửa `rotationInterval` trong `Shared/Phrase.swift`.

## Giới hạn của iOS

- Widget trên màn hình khoá **không phát được âm thanh trực tiếp**; chạm vào sẽ mở app (cần mở khoá) rồi app tự đọc.
- Widget màn hình khoá hiển thị đơn sắc, diện tích nhỏ, nên chữ dài sẽ tự thu nhỏ.
