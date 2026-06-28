import 'package:hive/hive.dart';
import '../../../features/home/domain/models/cart_model.dart';

class CartItemModelAdapter extends TypeAdapter<CartItemModel> {
  @override
  final int typeId = 2;

  @override
  CartItemModel read(BinaryReader reader) {
    return CartItemModel.fromMap(reader.readMap().cast<String, dynamic>());
  }

  @override
  void write(BinaryWriter writer, CartItemModel obj) {
    writer.writeMap(obj.toMap());
  }
}
