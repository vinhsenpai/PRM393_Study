## Plan sửa lỗi sản phẩm ở Home bị khuất + RenderFlex overflow

### Information Gathered
- `BuyerNavigationShell` dùng `Scaffold` với `bottomNavigationBar: BuyerBottomNav(...)` và `body: IndexedStack(...)`.
- `BuyerHomeScreen` là `Scaffold` riêng, trong `body` có `Column` gồm header + `Expanded(ProductCatalogScreen(hideAppBar: true))`.
- `ProductCatalogScreen(hideAppBar:true)` trả về `_ProductCatalogBody` và `_ProductCatalogBodyState` dùng `RefreshIndicator -> CustomScrollView -> SliverGrid`.
- `ProductCatalogScreen` hiện tại không có padding dưới để “nhường chỗ” cho bottom nav.
- Lỗi console: `RenderFlex overflowed by 8.8 pixels on the bottom` thường do content không khớp vùng hiển thị (bị che bởi bottom bar / thiếu padding / widget không được co giãn đúng).

### Plan (file-level)
1. **Sửa `lib/screens/product_catalog_screen.dart`**
   - Thêm padding dưới cho `CustomScrollView` (ví dụ `SliverPadding` bottom + hoặc `Padding` ngoài) để Grid không bị che bởi bottom navigation.
   - Dùng `MediaQuery.of(context).padding.bottom` + `kBottomNavigationBarHeight` (hoặc value phù hợp) để tạo khoảng trống động.
2. **(Nếu cần) Sửa `lib/navigation/buyer_navigation_shell.dart`**
   - Kiểm tra có đang bọc `Scaffold` lồng nhau (Scaffold trong `BuyerHomeScreen` + Scaffold ngoài). Nếu cần, giảm bớt lồng `Scaffold` cho Home screen hoặc chuyển `BuyerHomeScreen` về dạng không có Scaffold khi nằm trong shell.
   - Toggle `resizeToAvoidBottomInset` nếu layout bị ảnh hưởng bởi keyboard/insets.

### Dependent Files to be edited
- `lib/screens/product_catalog_screen.dart`
- Có thể: `lib/navigation/buyer_navigation_shell.dart` và/hoặc `lib/screens/buyer_home_screen.dart`

### Followup steps
- Chạy `flutter run` và kiểm tra trang Home: các card ở cuối lưới không còn bị khuất + không còn `RenderFlex overflowed ...`.

<ask_followup_question>
Bạn muốn ưu tiên fix nhanh chỉ ở `ProductCatalogScreen` (thêm padding dưới cho Sliver/CustomScrollView) hay muốn mình cũng xử lý khả năng “Scaffold lồng nhau” giữa `BuyerNavigationShell` và `BuyerHomeScreen`?
</ask_followup_question>

