import 'package:hive/hive.dart';
import 'package:rc_mobile_v2/features/home/domain/models/product_model.dart';

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    return ProductModel(
      id: reader.readString(),
      name: reader.readString(),
      price: reader.readDouble(),
      rating: reader.readDouble(),
      reviewCount: reader.readInt(),
      imageUrl: reader.readString(),
      category: reader.readString(),
      isFavorite: reader.readBool(),
      isActive: reader.readBool(),
      description: reader.readString(),
      availableSizes: reader.readStringList() ?? ['S', 'M', 'L', 'XL'],
      stock: reader.readInt(),
      weight: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeDouble(obj.price);
    writer.writeDouble(obj.rating);
    writer.writeInt(obj.reviewCount);
    writer.writeString(obj.imageUrl);
    writer.writeString(obj.category);
    writer.writeBool(obj.isFavorite);
    writer.writeBool(obj.isActive);
    writer.writeString(obj.description);
    writer.writeStringList(obj.availableSizes);
    writer.writeInt(obj.stock);
    writer.writeDouble(obj.weight);
  }
}

class BannerModelAdapter extends TypeAdapter<BannerModel> {
  @override
  final int typeId = 3;

  @override
  BannerModel read(BinaryReader reader) {
    return BannerModel(
      id: reader.readString(),
      title: reader.readString(),
      subtitle: reader.readString(),
      imageUrl: reader.readString(),
      discount: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, BannerModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.subtitle);
    writer.writeString(obj.imageUrl);
    writer.writeString(obj.discount ?? '');
  }
}
