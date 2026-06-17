# TODO - Local Hive Shopping Cart System

- [ ] 1) Add Hive CE + hive_flutter dependencies (if needed) and ensure pubspec.yaml is correct
- [ ] 2) Implement Hive CartItem model (with adapter) including: productId, title, price, imageUrl, quantity, sellerId, game, stockStatus, addedAt
- [ ] 3) Implement CartService (open box, load/save, clear, remove, update)
- [ ] 4) Replace/upgrade CartProvider to the required API while keeping legacy in-memory methods working where possible
- [ ] 5) Ensure Hive is initialized before providers in main.dart
- [ ] 6) Update product detail screen to call CartProvider.addToCart() and show Snackbar
- [ ] 7) Implement Cart UI components (CartItemWidget, OrderSummary sticky checkout bar, Empty cart state)
- [ ] 8) Upgrade CartScreen: dismissible delete, quantity stepper, pull-to-refresh, sticky summary, placeholder Checkout
- [ ] 9) Run flutter analyze / flutter test (if configured) and smoke test add-to-cart + persistence
- [ ] 10) Confirm cart persists after restart and after logout/login

