# Project TODO

## Fix: bottom overflow / home product cards bị khuất phần dưới
- [ ] Kiểm tra layout Home: BuyerNavigationShell + BuyerBottomNav + ProductCatalogScreen (CustomScrollView/SliverGrid) có đang bị thiếu padding cho bottom nav.
- [ ] Xem có widget đang bọc bằng Column trong khi content bên trong có chiều cao không đổi gây overflow.
- [ ] Chèn `padding`/`SliverPadding` dưới cho `CustomScrollView` để tránh phần tử bị khuất bởi bottomNavigationBar.
- [ ] Nếu vẫn overflow: bọc grid bằng `SafeArea` hoặc dùng `resizeToAvoidBottomInset: false/true` phù hợp.
- [ ] Chạy build/debug để xác nhận hết lỗi `RenderFlex overflowed by ... pixels on the bottom`.

