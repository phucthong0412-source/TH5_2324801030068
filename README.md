# Bài thực hành 5 — Ứng dụng ghi chú cá nhân

Ứng dụng Flutter với giao diện tiếng Việt, lưu ghi chú trên thiết bị bằng **SharedPreferences**. Dữ liệu không cần tài khoản hay kết nối mạng.

## Các yêu cầu đã thực hiện

| Yêu cầu | Cách sử dụng |
| --- | --- |
| Màn hình chính | Hiển thị tiêu đề, nhãn **Thời gian tạo** kèm ngày/giờ ngay dưới tiêu đề, và nội dung rút gọn của từng ghi chú. |
| Thêm ghi chú | Nhấn **Thêm ghi chú**, nhập tiêu đề và nội dung, nhấn **Lưu ghi chú**. Ứng dụng quay về danh sách. |
| Chỉnh sửa | Chạm vào ghi chú, chỉnh sửa và nhấn **Lưu thay đổi**. Thời gian tạo ban đầu được giữ nguyên. |
| Xóa | Vuốt ghi chú sang trái hoặc giữ lâu / nhấn dấu ba chấm để mở tùy chọn **Xóa ghi chú**. Chỉ xóa sau khi xác nhận **Xóa** trong hộp thoại. |
| Lưu dữ liệu | Danh sách được lưu dưới dạng JSON; mở lại ứng dụng vẫn đọc được các ghi chú đã lưu. |

Chức năng bổ sung: tìm theo tiêu đề hoặc nội dung, lọc ghi chú tạo hôm nay, sắp xếp theo thời gian tạo, chọn một trong năm màu và cảnh báo khi rời màn hình có thay đổi chưa lưu.

Ứng dụng kiểm tra tiêu đề/nội dung không được để trống. Nếu lưu hoặc xóa thất bại, dữ liệu hiện có được giữ lại và ứng dụng hiển thị thông báo. Nếu đọc dữ liệu thất bại, nút thêm bị vô hiệu hóa để tránh ghi đè dữ liệu cũ; có nút **Thử lại**.

## Chạy ứng dụng

Dự án đã được kiểm tra với Flutter 3.47.0 và Dart 3.13.0. Cần Flutter có Dart từ 3.13.0 trở lên.

Mở terminal trong thư mục dự án:

```powershell
cd D:\th5_2324801030068
flutter pub get
flutter run
```

Để chạy trên Android: mở máy ảo trong Android Studio hoặc kết nối điện thoại đã bật USB debugging, rồi chọn thiết bị khi chạy. Có thể xem thiết bị bằng `flutter devices`.

Để chạy nhanh trên Chrome:

```powershell
flutter run -d chrome
```

Để kiểm tra mã và các chức năng:

```powershell
flutter analyze
flutter test
```

Để tạo APK cài thử trên Android:

```powershell
flutter build apk --debug
```

APK nằm tại `build/app/outputs/flutter-apk/app-debug.apk`. Nếu Flutter báo chưa chấp nhận giấy phép Android SDK, chạy `flutter doctor --android-licenses` để tự đọc và chấp nhận các giấy phép cần thiết, rồi biên dịch lại.

## Tổ chức mã nguồn

```text
lib/
  main.dart                         Khởi tạo ứng dụng và tiếng Việt
  models/note.dart                  Dữ liệu ghi chú, chuyển đổi JSON
  data/note_repository.dart          Đọc/ghi SharedPreferences
  state/notes_controller.dart        Quản lý danh sách, thêm/sửa/xóa
  screens/notes_screen.dart          Danh sách, tìm kiếm, xác nhận xóa
  screens/note_editor_screen.dart    Nhập và sửa ghi chú
  widgets/note_card.dart             Thẻ ghi chú và thao tác vuốt/giữ
  theme/app_theme.dart               Màu sắc, kiểu giao diện
  utils/note_date.dart               Định dạng thời gian tạo
test/
  storage_test.dart                  Lưu/đọc lại JSON, dữ liệu lỗi
  widget_test.dart                   Các luồng thao tác và lỗi lưu/xóa
```

## Giải thích lưu trữ

Mỗi ghi chú có `id`, `title`, `content`, `createdAt`, `updatedAt` và `colorIndex`. Danh sách được mã hóa JSON, lưu thành chuỗi tại khóa `personal_notes_v1` qua `SharedPreferencesAsync` của gói [shared_preferences](https://pub.dev/packages/shared_preferences).

Luồng xử lý:

1. Khởi động: đọc chuỗi từ SharedPreferences, giải mã thành danh sách ghi chú.
2. Thêm: tạo ghi chú với mã và thời gian mới, lưu danh sách, cập nhật giao diện và quay về màn hình chính.
3. Sửa: tìm ghi chú theo `id`, thay tiêu đề/nội dung/màu, giữ `createdAt`, cập nhật `updatedAt` và lưu lại.
4. Xóa: yêu cầu xác nhận, lưu danh sách đã loại ghi chú, sau đó cập nhật giao diện.

Đối với bản Chrome, dữ liệu thuộc trình duyệt và địa chỉ chạy ứng dụng. Xóa dữ liệu ứng dụng/trình duyệt sẽ xóa ghi chú. Đây là lưu trữ cục bộ, chưa có đồng bộ hoặc sao lưu lên tài khoản.

## Kịch bản trình bày bài

1. Chạy ứng dụng, giới thiệu màn hình danh sách và nút thêm.
2. Tạo ghi chú “Kế hoạch học tập”, nhập nội dung và lưu.
3. Chỉ ra tiêu đề, phần nội dung rút gọn và thời gian tạo trên thẻ.
4. Chạm ghi chú, sửa nội dung và màu, lưu lại; danh sách cập nhật ngay.
5. Đóng rồi mở ứng dụng để minh họa dữ liệu được lưu.
6. Vuốt hoặc giữ lâu để xóa, nhấn **Hủy** để chứng minh ghi chú còn nguyên; thực hiện lại và xác nhận **Xóa**.

## Kết quả kiểm tra

- `flutter analyze`: không có lỗi hoặc cảnh báo.
- `flutter test`: cả 14 kiểm thử đạt, bao gồm thời gian tạo hiển thị trên điện thoại nhỏ và không bị thay bằng thời gian chỉnh sửa.
- `flutter build web`: biên dịch thành công.
- `flutter build apk --debug`: biên dịch thành công.
- Đã thử trên trình duyệt: thêm ghi chú tiếng Việt, mở chỉnh sửa, đổi màu, lưu và tải lại trang; ghi chú và màu đã lưu vẫn còn, thời gian tạo giữ nguyên.
- Ảnh giao diện: `screenshots/notes-preview.jpg`.
