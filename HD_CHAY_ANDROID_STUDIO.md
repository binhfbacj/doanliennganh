# HƯỚNG DẪN MỞ & CHẠY DỰ ÁN TRÊN ANDROID STUDIO

Dự án này là ứng dụng Flutter Mobile **Quản Lý Tiêu Dùng Thông Minh**. Dưới đây là các bước chi tiết để bạn mở và chạy kiểm tra trực tiếp trên Android Studio.

---

## 1. Mở Dự Án trong Android Studio

1. Khởi động **Android Studio**.
2. Trên màn hình chào mừng (hoặc menu **File**), chọn **Open** (Mở dự án).
3. Tìm và chọn đúng thư mục gốc của dự án:
   ```
   C:\bai2\doanliennganh
   ```
   *(Lưu ý: Chọn thư mục gốc `doanliennganh`, KHÔNG chỉ chọn thư mục `android`)*.
4. Nhấn **OK** và đợi Android Studio tải dự án và phân tích file Dart.

---

## 2. Kiểm tra Plugin Flutter & Dart trong Android Studio

Nếu đây là lần đầu bạn mở Flutter trên Android Studio:
1. Vào **File** -> **Settings** (hoặc nhấn `Ctrl + Alt + S`).
2. Chọn mục **Plugins** ở thanh bên trái.
3. Chuyển sang tab **Marketplace**, tìm kiếm `Flutter` và bấm **Install**. (Plugin Dart sẽ được tự động cài kèm).
4. Khởi động lại Android Studio sau khi cài đặt.

---

## 3. Chạy Ứng Dụng (Run App)

### Cách 1: Chạy bằng Máy Ảo (Android Emulator)
1. Trên thanh công cụ trên cùng của Android Studio, nhấn vào mục **Device Selection** (mặc định có thể là `<no device>`).
2. Chọn **Device Manager** -> Nhấn **Create Device** (nếu chưa có máy ảo).
3. Chọn thiết bị (ví dụ: *Pixel 7* hoặc *Pixel 8*), tải System Image (khuyến nghị Android 13 hoặc 14, API 33/34) và nhấn **Finish**.
4. Khởi động máy ảo bằng cách bấm nút **Play ▶️**.
5. Chọn máy ảo vừa chạy trong danh sách Device.
6. Nhấn nút **Run ▶️** (màu xanh lá cây) hoặc phím tắt `Shift + F10`.

### Cách 2: Chạy trực tiếp trên Điện Thoại Android Thật (Khuyên dùng để test Giọng Nói AI tốt nhất)
1. Trên điện thoại Android của bạn: Vào **Cài đặt** -> **Thông tin điện thoại** -> Bấm 7 lần vào **Số bản dựng (Build number)** để bật Chế độ nhà phát triển.
2. Vào **Tùy chọn nhà phát triển** -> Bật **Gỡ lỗi qua USB (USB Debugging)**.
3. Cắm cáp USB kết nối điện thoại với máy tính -> Chọn "Luôn cho phép từ máy tính này".
4. Tên điện thoại của bạn sẽ xuất hiện trên thanh công cụ của Android Studio.
5. Bấm nút **Run ▶️** (hoặc `Shift + F10`).

---

## 4. Các Tính Năng Đã Được Nâng Cấp & Bổ Sung

1. **Dashboard Tiêu Dùng Thông Minh (Home Screen)**:
   - Thẻ số dư ví khả dụng, tổng thu nhập và chi tiêu.
   - **Thẻ Điểm Sức Khỏe Tài Chính (0-100)**: Tự động đánh giá kỷ luật tài chính dựa trên thu/chi và tỷ lệ tiết kiệm.
   - **Cảnh báo vượt ngân sách thông minh**: Tự động thông báo khi có danh mục chạm mốc 80% hoặc vượt 100% hạn mức.
   - **Hạn mức chi tiêu mỗi ngày**: Tự động tính toán số tiền trung bình còn được tiêu trong các ngày còn lại của tháng.

2. **Chỉnh Sửa Giao Dịch (Edit Transaction)**:
   - Cho phép chỉnh sửa lại số tiền, tên giao dịch, danh mục, ngày giờ và ghi chú dễ dàng.

3. **Mục Tiêu Tiết Kiệm (Savings Goals)**:
   - Đặt mục tiêu mua sắm, tích lũy (xe cộ, du lịch, quỹ khẩn cấp...) kèm thanh tiến độ % trực quan và tính năng nạp tiền.

4. **Biểu Đồ Tròn Phân Bổ Chi Tiêu (Donut Chart)**:
   - Vẽ biểu đồ hình tròn trực quan theo danh mục bằng CustomPainter 60fps mượt mà.
   - Tính năng **Xuất tóm tắt báo cáo** sao chép nhanh vào Clipboard.

5. **Lọc & Tìm Kiếm Giao Dịch Nâng Cao**:
   - Lọc theo loại (Thu/Chi), lọc theo Danh mục chi tiết, giao dịch bằng giọng nói.
   - Nhóm giao dịch theo Ngày (Hôm nay, Hôm qua, Ngày xx/xx) kèm tổng tiền mỗi ngày.

6. **Chế Độ Sáng / Tối (Dark Mode)**:
   - Tùy chỉnh Dark Mode ngay trong phần Cài đặt giúp bảo vệ mắt vào ban đêm.

7. **Trợ Lý Giọng Nói Tiếng Việt (Voice AI Assistant)**:
   - Nhận diện nhanh các câu nói đời sống: *"Ăn sáng 35k"*, *"Đổ xăng 70 nghìn"*, *"Mua áo phông 200k"*, *"Lương tháng này 15 triệu"*, *"Hôm nay tôi đã tiêu bao nhiêu?"*...
