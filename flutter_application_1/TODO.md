# TODO - Fix RenderFlex overflow in ProductCard

- [ ] Inspect current ProductCard widget implementation (already reviewed)
- [x] Update `lib/widgets/product_card.dart` to remove/avoid the inner `Expanded` layout that can overflow

- [ ] Constrain the inner content so it always fits within the fixed card height
- [ ] Run `flutter analyze` and/or `flutter test` (if available) to confirm no widget/layout errors

