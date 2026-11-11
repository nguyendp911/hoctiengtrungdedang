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
Shared/phrases-widget.json  Bản gọn cho widget (tự sinh, đừng sửa tay)
Tests/                   Unit test (XCTest)
tools/                   Script kiểm tra và sinh dữ liệu
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

Số từ trong app theo đúng danh sách HSK 3.0 chính thức: HSK 1: 393 trên 500, HSK 2: 571 trên 772, HSK 3: 791 trên 973, HSK 4: 788 trên 1000, HSK 5: 821 trên 1071, HSK 6: 696 trên 1140, HSK 7–9: 3.103 trên khoảng 5.600; phần còn thiếu đang được bổ sung dần. Mỗi từ HSK trong `phrases.json` có thêm `unitNo` và `unit` để xếp vào bài; từ thêm sau chỉ cần ghi hai trường này và chủ đề là `HSK 1` ... `HSK 6`, `HSK 7-9`.

## Ba tab (Học, Ôn tập, Cài đặt)

- **Học**: thẻ từ (chữ Hán, pinyin, cách đọc, Hán Việt, nghĩa, câu ví dụ), chọn chủ đề, danh sách từ.
- **Ôn tập**: chuỗi ngày học, số từ cần ôn hôm nay, tiến độ theo chủ đề (chạm vào chủ đề để ôn riêng chủ đề đó).
- **Cài đặt**: nhắc học mỗi ngày, cập nhật từ, xoá tiến độ.

Lịch ôn ngắt quãng: trả lời đúng thì lần hỏi lại cách xa dần kiểu SM-2: thẻ lật có bốn nút Học lại / Khó / Tốt / Dễ, khoảng ôn lần lượt khoảng 1, 3 rồi nhân với hệ số dễ của từng từ (tối đa 180 ngày); Khó nhân nhỏ hơn, Dễ nhân lớn hơn, Học lại thì hỏi lại ngay và lùi 2 bậc (không về 0). Câu trắc nghiệm đúng tính là Tốt, sai là Học lại.

## Luyện nói

Bấm **Luyện nói** trên thẻ từ, đọc to, app nhận dạng giọng tiếng Trung và chấm phần trăm giống câu mẫu (sai thanh điệu bị trừ điểm). Cần cho phép micro và nhận dạng giọng nói; nhận dạng có thể cần mạng.

## Nhắc học mỗi ngày

Cài đặt › bật **Nhắc học mỗi ngày** và chọn giờ. Mỗi ngày một từ khác nhau hiện trong thông báo; hôm nào đã học rồi thì không nhắc. App đặt sẵn 14 ngày và đặt lại mỗi lần mở.

## Widget có nút bấm

Widget màn hình chính (nhỏ và vừa) có nút ✓ để đánh dấu **Đã thuộc** ngay trên widget. Widget màn hình khoá không có nút, chạm vào để mở app.

## Luyện viết

Bấm **Luyện viết** trên thẻ từ: xem thứ tự nét, tập tô theo nét mờ, hoặc tự viết không gợi ý; app chấm từng nét. Thư viện Hanzi Writer (MIT) và dữ liệu nét của 3.092 chữ (đủ cho toàn bộ từ trong app) đã đóng gói sẵn trong app (`App/Resources`), nên luyện viết chạy được khi không có mạng. Chữ mới thêm sau này mà chưa có sẵn thì app tự tải từ mạng. Dữ liệu nét lấy từ gói `hanzi-writer-data`, xuất xứ từ dự án Make Me a Hanzi (font Arphic, giấy phép Arphic Public License), xem điều khoản trước khi phát hành công khai.

## Tìm kiếm và yêu thích

Ô tìm kiếm ở tab Học khớp theo chữ Hán, pinyin, cách đọc, Hán Việt hoặc nghĩa, không phân biệt dấu ("ni hao", "nỉ hảo", "chao" đều tìm được). Bấm ngôi sao trên thẻ từ, hoặc vuốt phải trên một dòng, để thêm vào **Yêu thích**; chọn chip Yêu thích để chỉ xem các từ đó.

## Luyện tập khác (tab Ôn tập)

- **Mục tiêu hằng ngày** và biểu đồ 7 ngày: đổi số câu mục tiêu trong Cài đặt.
- **Thẻ lật**: chạm để lật, rồi tự chấm Học lại / Khó / Tốt / Dễ (vuốt phải = Tốt, vuốt trái = Học lại).
- **Luyện nghe**: nghe phát âm rồi chọn nghĩa đúng.
- **Luyện thanh điệu**: xem đường cao độ của 4 thanh, rồi nghe một chữ và chọn thanh.
- **Điền chỗ trống**: câu ví dụ bị che một từ, chọn từ đúng trong 4 đáp án (ưu tiên đáp án nhiễu cùng số chữ, cùng cấp). Sau khi trả lời, app đọc cả câu.
- **Học theo bộ thủ**: các chữ trong app được nhóm theo 214 bộ thủ Khang Hy (tên Hán Việt và nghĩa), bộ gặp nhiều nhất đứng đầu; tìm theo tên bộ, nghĩa hoặc chữ Hán. Chạm vào một chữ để nghe và lọc các từ có chữ đó, rồi bấm Ôn để làm trắc nghiệm riêng nhóm này. Dữ liệu bộ thủ của từng chữ (`App/Resources/radicals.json`) lấy từ trường kRSUnicode của Unihan (Unicode, giấy phép Unicode); tạo lại bằng `python tools/make_radicals_json.py Unihan_IRGSources.txt` khi thêm chữ mới.

## Siri và Phím tắt

Ứng dụng Phím tắt có sẵn hành động **Từ hôm nay**: đọc to từ đang hiện trên widget. Nút loa trên widget màn hình chính cũng đọc to từ mà không cần mở app (cần quyền phát âm khi chạy nền).

## Dữ liệu từ vựng

`Shared/phrases.json` có 10.710 từ: 65 từ theo chủ đề, 7.163 từ nằm đúng cấp HSK 1–9 theo danh sách chính thức, và 3.482 từ ở chủ đề **Ngoài HSK 3.0** (từ hữu ích nhưng không có trong danh sách chính thức; vẫn học và ôn được, tiến độ cũ được giữ vì `id` không đổi). Pinyin được đối chiếu tự động với thư viện pypinyin; âm Hán Việt và cách đọc tiếng Việt do người soạn viết, nên rà lại bằng từ điển.

Sau khi sửa file, chạy kiểm tra (CI cũng chạy tự động):

```bash
python tools/validate_phrases.py
```

Widget và Siri dùng bản gọn `phrases-widget.json` (khoảng 1,3 MB thay vì 3,8 MB) để tiết kiệm bộ nhớ. File này do GitHub Actions tự tạo lại khi `phrases.json` đổi; chạy tay bằng `python tools/make_widget_json.py`.

## Sao lưu tiến độ

Cài đặt › **Sao lưu tiến độ** xuất file JSON (lưu vào Tệp hoặc iCloud Drive); **Khôi phục từ file** nạp lại, dùng khi cài lại app hoặc đổi máy.

## Kiểm thử

Unit test nằm trong `Tests/` (từ vựng, tìm kiếm, lịch ôn, sao lưu). Chạy trong Xcode bằng Cmd+U, hoặc để GitHub Actions chạy khi push/PR (`.github/workflows/test.yml`).

## Giới hạn của iOS

- Widget trên màn hình khoá **không phát được âm thanh trực tiếp**; chạm vào sẽ mở app (cần mở khoá) rồi app tự đọc.
- Widget màn hình khoá hiển thị đơn sắc, diện tích nhỏ, nên chữ dài sẽ tự thu nhỏ.

## Đối chiếu với danh sách HSK 3.0 chính thức

Cấp HSK của từng từ đã được xếp lại theo [ivankra/hsk30](https://github.com/ivankra/hsk30) (dữ liệu từ Bộ Giáo dục Trung Quốc; chú ý bản quyền của dữ liệu gốc chưa rõ ràng nên file này không đưa vào repo, hãy tải `hsk30.csv` về một thư mục riêng):

```bash
python tools/relevel_hsk.py hsk30.csv          # xem thống kê
python tools/relevel_hsk.py hsk30.csv --write  # ghi lại phrases.json
python tools/compare_hsk30.py hsk30.csv Shared/phrases.json  # báo cáo khớp/thiếu theo cấp
```

Còn thiếu khoảng 3.800 từ chính thức (HSK 1: 93, HSK 2: 180, HSK 3: 166, HSK 4: 185, HSK 5: 240, HSK 6: 432, HSK 7–9: 2.509); nhiều mục là dạng ghép hoặc biến thể (一下儿、前边、第（第二）...). Mỗi từ cần cách đọc tiếng Việt, Hán Việt, nghĩa và ví dụ do người soạn viết, nên chưa thêm tự động.
