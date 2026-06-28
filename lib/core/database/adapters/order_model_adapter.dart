import 'package:hive/hive.dart';
import 'package:rc_mobile_v2/features/home/domain/models/order_model.dart';
import 'package:rc_mobile_v2/features/home/domain/models/product_model.dart';

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 1;

  @override
  OrderModel read(BinaryReader reader) {
    return OrderModel(
      id: reader.readString(),
      userId: reader.readString(),
      userName: reader.readString(),
      userAddress: reader.readString(),
      userPhone: reader.readString(),
      items: reader.readList().cast<ProductModel>(),
      totalPrice: reader.readDouble(),
      shippingCost: reader.readDouble(),
      status: OrderStatus.values[reader.readInt()],
      paymentMethod: PaymentMethod.values[reader.readInt()],
      paymentProof: reader.readString(),
      orderDate: DateTime.parse(reader.readString()),
      paymentDate: reader.readBool()
          ? DateTime.parse(reader.readString())
          : null,
      shippedDate: reader.readBool()
          ? DateTime.parse(reader.readString())
          : null,
      deliveredDate: reader.readBool()
          ? DateTime.parse(reader.readString())
          : null,
      courier: reader.readString(),
      courierService: reader.readString(),
      estimatedDelivery: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.userName);
    writer.writeString(obj.userAddress);
    writer.writeString(obj.userPhone);
    writer.writeList(obj.items);
    writer.writeDouble(obj.totalPrice);
    writer.writeDouble(obj.shippingCost);
    writer.writeInt(obj.status.index);
    writer.writeInt(obj.paymentMethod.index);
    writer.writeString(obj.paymentProof ?? '');
    writer.writeString(obj.orderDate.toIso8601String());
    writer.writeBool(obj.paymentDate != null);
    if (obj.paymentDate != null) {
      writer.writeString(obj.paymentDate!.toIso8601String());
    }
    writer.writeBool(obj.shippedDate != null);
    if (obj.shippedDate != null) {
      writer.writeString(obj.shippedDate!.toIso8601String());
    }
    writer.writeBool(obj.deliveredDate != null);
    if (obj.deliveredDate != null) {
      writer.writeString(obj.deliveredDate!.toIso8601String());
    }
    writer.writeString(obj.courier ?? '');
    writer.writeString(obj.courierService ?? '');
    writer.writeString(obj.estimatedDelivery ?? '');
  }
}
