# Hệ Thống Điểm Danh & Chấm Công Nhân Viên (Mobile App & Web API)
**Sinh viên thực hiện:** Nguyễn Hữu Trí  
**Công nghệ:** Flutter (Frontend Mobile) & ASP.NET Core 8.0 Web API (Backend) + SQL Server

---

## 🌟 Tổng Quan Dự Án
Hệ thống quản lý điểm danh và chấm công thông minh dành cho doanh nghiệp, hỗ trợ đa nền tảng và tích hợp các công nghệ phần cứng hiện đại trên thiết bị di động:
1. **Xác thực 2 lớp bảo mật (2FA):** Đăng ký qua Email, đăng nhập Username/Password kèm mã xác thực OTP 6 số gửi qua Email / Demo OTP.
2. **Đăng nhập Sinh trắc học (Face ID / Vân tay):** Hỗ trợ cảm biến khuôn mặt và vân tay của điện thoại di động giúp đăng nhập nhanh và bảo mật.
3. **Phân quyền người dùng (Role-based):**
   - **Admin:** Quản lý nhân viên (CRUD), xem báo cáo chấm công tổng hợp, xuất/lọc dữ liệu, đặt lại/xóa bản ghi chấm công.
   - **Employee (Nhân viên):** Chấm công định vị GPS, quét mã QR, theo dõi lịch sử chấm công cá nhân, đặt lại chấm công hôm nay.
   - **Customer:** Cổng dịch vụ khách hàng.
4. **Chấm công định vị Geofencing GPS:** Kiểm tra khoảng cách thực tế của nhân viên với tọa độ văn phòng (phạm vi hợp lệ 300m).
5. **Chấm công Quét mã QR bằng Camera:** Sử dụng camera điện thoại quét mã QR động tại cổng văn phòng để ghi nhận check-in/check-out.

---

## 📁 Cấu Trúc Thư Mục
```text
├── lib/                     # Mã nguồn Flutter (Frontend)
│   ├── models/              # DTO & Data Models
│   ├── screens/             # Màn hình giao diện (Auth, Admin, Employee, Customer)
│   ├── services/            # API Service, GPS Geofencing, Biometric Auth
│   └── theme/               # Design system & màu sắc
├── backend_api/             # Mã nguồn ASP.NET Core 8.0 Web API (Backend)
│   └── nguyenhuutri/
│       ├── Controllers/     # AuthController, EmployeeController, AttendanceController
│       ├── Data/            # Entity Framework Core & SQL Server DbContext
│       ├── DTOs/            # Data Transfer Objects
│       └── Models/          # Entity Models (User, Employee, Attendance)
├── qrcode_checkin.html      # Trang web hiển thị mã QR chấm công tại công ty
└── README.md
```

---

## 🚀 Hướng Dẫn Khởi Chạy Cho Giảng Viên

### 1. Khởi chạy Backend Web API (.NET 8.0)
1. Mở file `backend_api/nguyenhuutri.slnx` hoặc thư mục `backend_api/nguyenhuutri` bằng **Visual Studio**.
2. Kiểm tra chuỗi kết nối trong `appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=.\\SQLEXPRESS;Database=nguyenhuutri;Trusted_Connection=True;TrustServerCertificate=True;"
   }
   ```
3. Bấm **F5** để khởi chạy API. 
4. Trình duyệt sẽ tự động mở giao diện **Swagger UI** tại:
   - Local: `http://localhost:5184/swagger`
   - **Link Public Online (Cloudflare HTTPS):** `https://posted-obtain-evaluating-goto.trycloudflare.com/swagger`
   *(Hệ thống đã tích hợp `AppDbContext.Database.EnsureCreated()` và nạp sẵn tài khoản mẫu, không cần chạy migration thủ công).*

### 2. Khởi chạy Ứng dụng Di động (Flutter)
1. Mở thư mục gốc bằng VS Code hoặc Android Studio.
2. Chạy lệnh cài đặt thư viện:
   ```bash
   flutter pub get
   ```
3. Khởi chạy ứng dụng lên Máy ảo Android hoặc Điện thoại thật:
   ```bash
   flutter run
   ```
4. **Cấu hình kết nối API:**
   - Khi chạy trên **Máy ảo Android**: Tự động kết nối qua `http://10.0.2.2:5184/api`.
   - Khi chạy trên **Điện thoại thật (cáp USB)**: Dùng lệnh `adb reverse tcp:5184 tcp:5184`, app tự kết nối `http://localhost:5184/api`.
   - Hoặc bấm vào icon **⚙️ Cài đặt** ở góc trên màn hình Đăng nhập để đổi IP tùy ý chỉ với 1 chạm.

---

## 🔑 Tài Khoản Mẫu Trải Nghiệm
| Vai trò | Tên đăng nhập | Mật khẩu | Chức năng nổi bật |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `123456` | Quản lý nhân viên, Báo cáo, Đặt lại chấm công |
| **Nhân viên** | `nv_an` | `123456` | Chấm công GPS, Quét QR, Lịch sử, Face ID |
| **Khách hàng** | `khachhang1` | `123456` | Cổng thông tin khách hàng |
