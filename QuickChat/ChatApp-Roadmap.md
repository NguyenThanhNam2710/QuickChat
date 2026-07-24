# Lộ Trình Xây Dựng App Chat bằng SwiftUI

> Tài liệu nội bộ dự án — dùng làm kim chỉ nam cho kiến trúc, cấu trúc thư mục và tiến độ phát triển.
> Đối tượng: Dev iOS có kỹ năng Swift/SwiftUI, chưa có kinh nghiệm backend.

---

## 1. Bối cảnh & Lựa chọn công nghệ

Mục tiêu: xây một app chat đơn giản, chuẩn Apple, không cần tự viết server.

| Thành phần | Lựa chọn | Lý do |
|---|---|---|
| UI | SwiftUI (iOS 17+) | Chuẩn hiện đại, hỗ trợ `@Observable`, `NavigationStack` |
| Kiến trúc | MVVM | Phù hợp nhất với SwiftUI, tách View/Logic rõ ràng |
| Concurrency | Swift Concurrency (`async/await`, `Task`, `AsyncStream`) | Chuẩn Apple, thay completion handler/Combine cho phần lớn use case |
| Backend | Firebase (Auth, Firestore, Storage, Cloud Messaging) | Backend-as-a-Service, có SDK Swift chính thức, realtime tốt, không cần viết server |
| Local cache | SwiftData | Cache offline, chuẩn Apple, thay thế CoreData cho project mới |
| Dependency Injection | Protocol-based, inject qua init | Dễ mock để unit test, không cần thư viện ngoài |

> **Ghi chú quan trọng:** Firebase không phải là "viết code server". Bạn chỉ cấu hình Security Rules trên Firebase Console và gọi SDK trong Swift. Đây là cách phổ biến để dev iOS solo build app chat mà không cần biết Node.js/backend framework.

---

## 2. Tổng quan 6 giai đoạn

1. **Setup & kiến trúc nền tảng** — 2-3 ngày
2. **Authentication** — 3-5 ngày
3. **Danh sách cuộc trò chuyện (Conversations List)** — 3-4 ngày
4. **Màn hình chat real-time** — 5-7 ngày
5. **Tính năng nâng cao** — 1-2 tuần
6. **Polish, testing, chuẩn bị release** — 1 tuần

Tổng thời gian ước tính: **~5-7 tuần** làm việc bán thời gian (part-time), ngắn hơn nếu full-time.

---

## 3. Cấu trúc thư mục dự án

```
ChatApp/
├── ChatAppApp.swift                 # Entry point (@main)
├── Info.plist
├── GoogleService-Info.plist          # Config Firebase
│
├── App/
│   ├── AppState.swift                # Trạng thái toàn cục (user đã login chưa...)
│   └── AppDelegate.swift             # Config Firebase, push notification
│
├── Core/
│   ├── Extensions/                   # String+Ext, Date+Ext, View+Ext...
│   ├── Utilities/                    # Helper functions, Constants.swift
│   └── DesignSystem/                 # Colors.swift, Fonts.swift, Spacing.swift
│
├── Models/
│   ├── User.swift
│   ├── Conversation.swift
│   ├── Message.swift
│   └── MessageStatus.swift           # enum: sending, sent, delivered, read
│
├── Services/                         # Lớp giao tiếp với Firebase (Data layer)
│   ├── Protocols/
│   │   ├── AuthServiceProtocol.swift
│   │   ├── ChatServiceProtocol.swift
│   │   └── UserServiceProtocol.swift
│   ├── AuthService.swift
│   ├── ChatService.swift
│   ├── UserService.swift
│   └── StorageService.swift          # Upload ảnh
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   └── SignUpView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   │
│   ├── ConversationList/
│   │   ├── Views/
│   │   │   ├── ConversationListView.swift
│   │   │   └── ConversationRowView.swift
│   │   └── ViewModels/
│   │       └── ConversationListViewModel.swift
│   │
│   ├── Chat/
│   │   ├── Views/
│   │   │   ├── ChatView.swift
│   │   │   ├── MessageBubbleView.swift
│   │   │   └── MessageInputBarView.swift
│   │   └── ViewModels/
│   │       └── ChatViewModel.swift
│   │
│   └── Profile/
│       ├── Views/ProfileView.swift
│       └── ViewModels/ProfileViewModel.swift
│
├── Navigation/
│   └── AppRouter.swift               # NavigationStack + NavigationPath quản lý điều hướng
│
└── Resources/
    └── Assets.xcassets
```

### Nguyên tắc phân lớp

- **`Models`** — dữ liệu thuần (`struct`, `Codable`), không chứa logic nghiệp vụ.
- **`Services`** — nơi DUY NHẤT "chạm" vào Firebase. Nếu sau này đổi backend (ví dụ sang Supabase), chỉ cần sửa ở lớp này, không đụng vào Feature/View.
- **`Features`** — mỗi tính năng có `View` + `ViewModel` riêng biệt, hạn chế phụ thuộc chéo giữa các feature.
- Dùng **protocol** cho từng Service (`AuthServiceProtocol`, `ChatServiceProtocol`...) để ViewModel có thể test bằng mock, không cần Firebase thật khi chạy Unit Test.

---

## 4. Chi tiết từng giai đoạn

### Giai đoạn 1 — Setup nền tảng (2-3 ngày)

- [ ] Tạo project SwiftUI, target iOS 17+ (để dùng `@Observable` và `NavigationStack`).
- [ ] Cài Firebase qua Swift Package Manager: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `FirebaseMessaging`.
- [ ] Tạo project trên Firebase Console, tải `GoogleService-Info.plist`.
- [ ] Setup `AppRouter` dùng `NavigationStack` + `NavigationPath`.
- [ ] Dựng khung thư mục theo mục 3.

### Giai đoạn 2 — Authentication (3-5 ngày)

- [ ] Model `User`: `id`, `email`, `displayName`, `avatarURL`, `lastSeen`.
- [ ] `AuthService` implement `AuthServiceProtocol`: `signUp`, `signIn`, `signOut`.
- [ ] Bridge Firebase auth state listener (callback-based) sang `AsyncStream` để dùng với `async/await`.
- [ ] UI: `LoginView`, `SignUpView` dùng `TextField`, `SecureField`, validate input cơ bản (email hợp lệ, mật khẩu tối thiểu ký tự).
- [ ] `AppState` lắng nghe trạng thái đăng nhập → điều hướng vào app chính hoặc màn hình login.

### Giai đoạn 3 — Danh sách cuộc trò chuyện (3-4 ngày)

- [ ] Model `Conversation`: `id`, `participantIDs`, `lastMessage`, `lastMessageDate`, `unreadCount`.
- [ ] Thiết kế Firestore schema (xem mục 5).
- [ ] `ChatService.observeConversations()` dùng Firestore `addSnapshotListener`, bọc thành `AsyncStream<[Conversation]>`.
- [ ] UI: `ConversationListView` dùng `List` + `ConversationRowView` (avatar, tên, tin nhắn cuối, thời gian, badge unread).

### Giai đoạn 4 — Màn hình chat real-time (5-7 ngày, phần khó nhất)

- [ ] `ChatViewModel`: load lịch sử tin nhắn có phân trang (pagination), gửi tin nhắn mới, lắng nghe tin nhắn realtime.
- [ ] UI: `ScrollView` + `LazyVStack` (hoặc `List` ẩn separator), tự cuộn xuống cuối khi có tin mới bằng `ScrollViewReader`.
- [ ] `MessageBubbleView`: bong bóng chat trái/phải tùy theo sender (`HStack` + `Spacer`).
- [ ] `MessageInputBarView`: `TextField` nhiều dòng + nút gửi, xử lý tránh bàn phím che khuất bằng `.safeAreaInset`.

### Giai đoạn 5 — Tính năng nâng cao (1-2 tuần)

- [ ] Gửi ảnh: `PhotosPicker` (iOS 16+) → upload lên Firebase Storage → lưu URL vào message.
- [ ] Push notification: Firebase Cloud Messaging + `UNUserNotificationCenter`.
- [ ] Trạng thái online / typing indicator: field `isTyping`, `lastSeen` cập nhật realtime trong Firestore.
- [ ] Đã đọc / chưa đọc: cập nhật `status` của message khi `ChatView` xuất hiện trên màn hình.

### Giai đoạn 6 — Hoàn thiện & release (1 tuần)

- [ ] Viết Unit Test cho ViewModel (mock Service qua protocol, không gọi Firebase thật).
- [ ] Xử lý lỗi mạng, empty state, loading state cho mọi màn hình.
- [ ] Kiểm tra Dark Mode, Dynamic Type, VoiceOver (theo Human Interface Guidelines).
- [ ] Chuẩn bị App Icon, Launch Screen.
- [ ] Build và test qua TestFlight.

---

## 5. Thiết kế dữ liệu Firestore (đề xuất)

```
conversations/{conversationId}
  ├── participantIDs: [String]
  ├── lastMessage: String
  ├── lastMessageDate: Timestamp

messages/{conversationId}/items/{messageId}
  ├── senderID: String
  ├── text: String
  ├── timestamp: Timestamp
  ├── status: String   // sending | sent | delivered | read
  ├── imageURL: String?  // optional, dùng cho tính năng gửi ảnh
```

> Lưu ý: cần cấu hình Firestore Security Rules để chỉ `participantIDs` trong một conversation mới đọc/ghi được messages tương ứng — đây là phần "bảo mật server-side" quan trọng nhất cần làm dù không viết code backend.

---

## 6. Nguyên tắc "chuẩn Apple" cần giữ xuyên suốt

- **Single source of truth**: ViewModel giữ state, View chỉ render — không để state trùng lặp giữa nhiều nơi.
- **Dependency Injection qua init/Environment**: inject Service vào ViewModel qua initializer, hạn chế Singleton (trừ `AppState` ở tầng app).
- **Async/await ưu tiên hơn Combine**, trừ khi thực sự cần publisher phức tạp (ví dụ combine nhiều stream).
- **Không block UI thread**: mọi network call đều là hàm `async`, gọi trong View qua modifier `.task { }`.
- Tuân thủ Human Interface Guidelines: Dynamic Type, Dark Mode, Accessibility (VoiceOver) áp dụng ngay từ đầu, không để tới cuối mới sửa.

---

## 7. Bước tiếp theo

Sau khi hoàn thành Giai đoạn 1 (setup), việc code mẫu đầu tiên nên là:

1. `AuthService` + `AuthServiceProtocol` — nền tảng cho toàn bộ luồng đăng nhập.
2. `LoginView` + `AuthViewModel` — để có thể chạy thử end-to-end sớm nhất.
3. Từ đó lặp lại pattern (Protocol → Service → ViewModel → View) cho các giai đoạn tiếp theo.

---

*Tài liệu này nên được cập nhật khi kiến trúc hoặc lộ trình thay đổi trong quá trình phát triển thực tế.*
