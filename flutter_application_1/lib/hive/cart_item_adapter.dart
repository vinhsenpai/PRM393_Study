import 'package:hive/hive.dart';

import '../models/cart_item.dart';

/// Handwritten Hive adapter (no code generation required).
class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 1;



  @override
  CartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (var i = 0; i < numOfFields; i++) {
      final fieldKey = reader.readByte();
      fields[fieldKey] = reader.read();
    }

    return CartItem(
      productId: fields[0] as String,
      title: fields[1] as String,
      price: fields[2] as double,
      imageUrl: fields[3] as String,
      quantity: fields[4] as int,
      sellerId: fields[5] as String,
      game: fields[6] as String,
      stockStatus: fields[7] as String,
      addedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.sellerId)
      ..writeByte(6)
      ..write(obj.game)
      ..writeByte(7)
      ..write(obj.stockStatus)
      ..writeByte(8)
      ..write(obj.addedAt);
  }

  @override
  String toString() => 'CartItemAdapter(typeId: $typeId)';
}

