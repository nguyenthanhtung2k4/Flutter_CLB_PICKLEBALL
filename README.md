# 🏓 Ứng Dụng Quản Lý Câu Lạc Bộ Pickleball (Pickleball Club App)

## 👤 Thông Tin Sinh Viên (Author)

| **Hạng Mục**           | **Thông Tin**         |
| :--------------------- | :-------------------- |
| **Họ và Tên**          | **Nguyen Thanh Tung** |
| **Mã Sinh Viên (MSV)** | **1771020729**        |
| **Lớp**                | **CNTT 17-08**        |

---

## 📝 Đề Tài & Bài Toán (Topic)

### **Xây Dựng Hệ Thống Quản Lý Sân & Đặt Lịch Cho CLB Pickleball**

**Mục tiêu:**
Xây dựng giải pháp phần mềm toàn diện giúp các câu lạc bộ Pickleball quản lý hoạt động hiệu quả hơn, thay thế cho việc ghi chép thủ công.

**Các chức năng chính:**

- 📅 **Đặt sân Online (Booking):** Giúp hội viên đặt sân dễ dàng qua ứng dụng di động.
- 🔔 **Thông báo Real-time:** Nhận thông báo xác nhận đặt sân, hủy sân ngay lập tức (SignalR).
- 👥 **Quản lý Hội viên:** Theo dõi danh sách thành viên, phân hạng VIP/Thường.
- 📊 **Quản lý Sân bãi:** Kiểm tra tình trạng sân trống/đầy theo thời gian thực.
- 🔒 **Bảo mật:** Đăng nhập, đăng ký và xác thực người dùng an toàn (JWT).

---

## 📂 Cấu Trúc Dự Án (Folder Structure)

Dự án được triển khai theo mô hình **Client-Server** với cấu trúc thư mục như sau:

```bash
📦 Flutter_CLB_PICKLEBALL (Root)
 ┣ 📂 Backend            # 🖥️ Server-side (ASP.NET Core API)
 ┃ ┣ 📂 Controllers      # API Endpoints (Booking, Auth, Members...)
 ┃ ┣ 📂 Hubs             # SignalR Hub (Xử lý Real-time)
 ┃ ┣ 📂 Models           # Cấu trúc dữ liệu & Entity Framework
 ┃ ┗ 📜 Program.cs       # Cấu hình hệ thống
 ┃
 ┗ 📂 pickleball_app     # 📱 Mobile App (Flutter)
   ┣ 📂 lib
   ┃ ┣ 📂 screens        # Giao diện (Màn hình Home, Booking, Login...)
   ┃ ┣ 📂 services       # Gọi API (Dio Service)
   ┃ ┣ 📂 widgets        # Các Widget tái sử dụng
   ┃ ┗ 📜 main.dart      # Điểm khởi chạy ứng dụng
   ┗ 📜 pubspec.yaml     # Quản lý thư viện
```

---

## 🛠 Công Nghệ Sử Dụng (Technology Stack)

Ứng dụng được xây dựng dựa trên các công nghệ hiện đại, đảm bảo hiệu năng và trải nghiệm người dùng tốt nhất.

### **1. Backend (Server)**

| Công nghệ                                                                                                                 | Mô tả                                                         |
| :------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------ |
| ![.NET](https://img.shields.io/badge/.NET_8-512BD4?style=flat-square&logo=dotnet&logoColor=white)                         | **ASP.NET Core Web API** - Framework mạnh mẽ của Microsoft.   |
| ![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=flat-square&logo=microsoft-sql-server&logoColor=white) | **SQL Server** - Hệ quản trị cơ sở dữ liệu quan hệ.           |
| **Entity Framework**                                                                                                      | ORM để làm việc với Database dễ dàng hơn.                     |
| **SignalR**                                                                                                               | Công nghệ giao tiếp thời gian thực (Real-time communication). |
| **JWT**                                                                                                                   | JSON Web Token để xác thực bảo mật.                           |

### **2. Mobile App (Client)**

| Công nghệ                                                                                              | Mô tả                                            |
| :----------------------------------------------------------------------------------------------------- | :----------------------------------------------- |
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) | **Flutter SDK** - Xây dựng ứng dụng đa nền tảng. |
| **Dart**                                                                                               | Ngôn ngữ lập trình chính cho Flutter.            |
| **Provider**                                                                                           | Quản lý trạng thái ứng dụng (State Management).  |
| **Dio**                                                                                                | Thư viện HTTP Client để gọi API.                 |
| **GoRouter**                                                                                           | Quản lý điều hướng màn hình thông minh.          |

---

## 🚀 Hướng Dẫn Cài Đặt (Setup Guide)

### **Bước 1: Chạy Backend**

1. Di chuyển vào thư mục `Backend`.
2. Cấu hình chuỗi kết nối Database trong `appsettings.json`.
3. Chạy lệnh: `dotnet run`.

### **Bước 2: Chạy Mobile App**

1. Di chuyển vào thư mục `pickleball_app`.
2. Tải các thư viện cần thiết:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng trên thiết bị giả lập hoặc máy thật:
   ```bash
   flutter run
   ```

---

_Developed by **Nguyen Thanh Tung** (CNTT 17-08)_
