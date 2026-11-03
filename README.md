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

## Thêm từ mới, chủ đề mới (không cần cài lại app)

Sửa file `Shared/phrases.json` ngay trên GitHub (bấm vào file › biểu tượng bút chì › Commit changes). App và widget tự tải bản mới:

- App: mở app, hoặc kéo danh sách xuống / bấm nút ↻.
- Widget: tự tải lại khoảng 6 giờ một lần.

Mỗi từ là một dòng, `id` không được trùng. Ghi chủ đề mới vào `topic` là có chủ đề mới:

```json
{ "id": 66, "topic": "Trái cây", "hanzi": "苹果", "pinyin": "píngguǒ", "readingVi": "pính của", "meaningVi": "Quả táo" },
```

Nếu file bị sai cú pháp (thiếu dấu phẩy, ngoặc…), app bỏ qua và giữ danh sách cũ.

Đổi chủ đề trên màn hình khoá: giữ màn hình khoá › Tuỳ chỉnh › chạm vào widget Hán Tự › chọn Chủ đề.

Muốn đổi tần suất đổi từ, sửa `rotationInterval` trong `Shared/Phrase.swift`.

## Ôn tập và đánh dấu đã thuộc

- Bấm **Đánh dấu thuộc** trên thẻ từ, hoặc vuốt sang trái trên một dòng trong danh sách.
- **Ôn tập**: 10 câu trắc nghiệm theo chủ đề đang chọn (nhìn chữ chọn nghĩa, hoặc nhìn nghĩa chọn chữ). Đúng 3 lần liên tiếp thì từ được tính là đã thuộc, trả lời sai thì từ phải học lại.
- Widget ưu tiên hiện từ chưa thuộc; khi đã thuộc hết chủ đề thì hiện lại tất cả.

Tiến độ được lưu qua App Group `group.com.nguyendp.hanzilock`. Nếu công cụ ký lại làm mất App Group, app vẫn lưu tiến độ, chỉ là widget không biết từ nào đã thuộc.

## Lộ trình HSK (tab Lộ trình)

Lộ trình theo chuẩn HSK 3.0: **HSK 0** (nhập môn phiên âm, không phải cấp chính thức), HSK 1 đến 6, và HSK 7–9 (chuẩn 3.0 gộp ba cấp này làm một). Số từ chính thức mỗi cấp: 500, 772, 973, 1000, 1071, 1140 và khoảng 5.600 (tổng khoảng 11.000 từ). Từng cấp được biên soạn dần, cấp nào chưa có từ sẽ hiện thông báo "đang biên soạn".

- **HSK 0:** bảng phiên âm 23 thanh mẫu và 36 vận mẫu (chạm để nghe), mẹo phát âm cho người Việt, luyện thanh điệu.
- **HSK 1 trở lên:** chia thành các bài theo chủ đề (ví dụ HSK 1: Chào hỏi và xưng hô, Số đếm và ngày giờ, Hành động hằng ngày...).

- **Kế hoạch hôm nay:** học số từ mới mỗi ngày bạn đặt (mặc định 5, đổi trong Cài đặt) cộng với các từ đến hạn ôn. Một nút "Bắt đầu hôm nay" mở thẻ lật đúng các từ đó.
- **Ước tính ngày hoàn thành:** từ số từ còn lại chia cho số từ mới mỗi ngày.
- **Học bài / Kiểm tra bài:** mỗi bài có thẻ lật và bài kiểm tra riêng.
- **Thi thử HSK:** 20 câu từ vựng trộn của cấp đó, đạt từ 60%.

Số từ trong app hiện là HSK 1: 469, HSK 2: 757, HSK 3: 962, so với 500, 772 và 973 của chuẩn 3.0, nên chưa đủ. Các từ HSK hiện có được xếp cấp xấp xỉ theo kinh nghiệm học, chưa đối chiếu từng từ với danh sách chính thức của HSK 3.0. Mỗi từ HSK trong `phrases.json` có thêm `unitNo` và `unit` để xếp vào bài; từ thêm sau chỉ cần ghi hai trường này và chủ đề là `HSK 1` ... `HSK 6`, `HSK 7-9`.

## Ba tab (Học, Ôn tập, Cài đặt)

- **Học**: thẻ từ (chữ Hán, pinyin, cách đọc, Hán Việt, nghĩa, câu ví dụ), chọn chủ đề, danh sách từ.
- **Ôn tập**: chuỗi ngày học, số từ cần ôn hôm nay, tiến độ theo chủ đề (chạm vào chủ đề để ôn riêng chủ đề đó).
- **Cài đặt**: nhắc học mỗi ngày, cập nhật từ, xoá tiến độ.

Lịch ôn ngắt quãng: trả lời đúng thì lần hỏi lại cách xa dần (1, 2, 4, 7, 15 ngày), trả lời sai thì hỏi lại ngay.

## Luyện nói

Bấm **Luyện nói** trên thẻ từ, đọc to, app nhận dạng giọng tiếng Trung và chấm phần trăm giống câu mẫu (sai thanh điệu bị trừ điểm). Cần cho phép micro và nhận dạng giọng nói; nhận dạng có thể cần mạng.

## Nhắc học mỗi ngày

Cài đặt › bật **Nhắc học mỗi ngày** và chọn giờ. Mỗi ngày một từ khác nhau hiện trong thông báo; hôm nào đã học rồi thì không nhắc. App đặt sẵn 14 ngày và đặt lại mỗi lần mở.

## Widget có nút bấm

Widget màn hình chính (nhỏ và vừa) có nút ✓ để đánh dấu **Đã thuộc** ngay trên widget. Widget màn hình khoá không có nút, chạm vào để mở app.

## Luyện viết

Bấm **Luyện viết** trên thẻ từ: xem thứ tự nét, tập tô theo nét mờ, hoặc tự viết không gợi ý; app chấm từng nét. Thư viện Hanzi Writer (MIT) và dữ liệu nét của 392 chữ đã đóng gói sẵn trong app (`App/Resources`), nên luyện viết chạy được khi không có mạng. Chữ mới thêm sau này mà chưa có sẵn thì app tự tải từ mạng. Dữ liệu nét lấy từ gói `hanzi-writer-data`, xuất xứ từ dự án Make Me a Hanzi (font Arphic, giấy phép Arphic Public License), xem điều khoản trước khi phát hành công khai.

## Tìm kiếm và yêu thích

Ô tìm kiếm ở tab Học khớp theo chữ Hán, pinyin, cách đọc, Hán Việt hoặc nghĩa, không phân biệt dấu ("ni hao", "nỉ hảo", "chao" đều tìm được). Bấm ngôi sao trên thẻ từ, hoặc vuốt phải trên một dòng, để thêm vào **Yêu thích**; chọn chip Yêu thích để chỉ xem các từ đó.

## Luyện tập khác (tab Ôn tập)

- **Mục tiêu hằng ngày** và biểu đồ 7 ngày: đổi số câu mục tiêu trong Cài đặt.
- **Thẻ lật**: vuốt phải khi đã nhớ, vuốt trái để học lại, chạm để lật.
- **Luyện nghe**: nghe phát âm rồi chọn nghĩa đúng.
- **Luyện thanh điệu**: xem đường cao độ của 4 thanh, rồi nghe một chữ và chọn thanh.

## Siri và Phím tắt

Ứng dụng Phím tắt có sẵn hành động **Từ hôm nay**: đọc to từ đang hiện trên widget. Nút loa trên widget màn hình chính cũng đọc to từ mà không cần mở app (cần quyền phát âm khi chạy nền).

## Dữ liệu từ vựng

`Shared/phrases.json` có 340 từ: 65 từ theo chủ đề và 275 từ HSK 1, 2, 3 (chọn lọc, chưa đủ toàn bộ danh sách chính thức). Pinyin được đối chiếu tự động với thư viện pypinyin; âm Hán Việt và cách đọc tiếng Việt do người soạn viết, chỉ kiểm tra được số âm tiết, nên nên rà lại bằng từ điển.

## Giới hạn của iOS

- Widget trên màn hình khoá **không phát được âm thanh trực tiếp**; chạm vào sẽ mở app (cần mở khoá) rồi app tự đọc.
- Widget màn hình khoá hiển thị đơn sắc, diện tích nhỏ, nên chữ dài sẽ tự thu nhỏ.
