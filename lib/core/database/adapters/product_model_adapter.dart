import 'package:hive/hive.dart';
import 'package:rc_mobile_v2/features/home/domain/models/product_model.dart';

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final price = reader.readDouble();
    final rating = reader.readDouble();
    final reviewCount = reader.readInt();
    final imageUrl = reader.readString();
    final category = reader.readString();
    final isFavorite = reader.readBool();
    final isActive = reader.readBool();
    final description = reader.readString();
    final sizes = reader.readStringList() ?? ['S', 'M', 'L', 'XL'];
    final sizeStock = <String, int>{};
    final count = reader.readInt();
    for (int i = 0; i < count; i++) {
      final size = reader.readString();
      final qty = reader.readInt();
      sizeStock[size] = qty;
    }
    final weight = reader.readDouble();
    return ProductModel(
      id: id,
      name: name,
      price: price,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      category: category,
      isFavorite: isFavorite,
      isActive: isActive,
      description: description,
      availableSizes: sizes,
      stockPerSize: sizeStock,
      weight: weight,
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
    writer.writeInt(obj.stockPerSize.length);
    for (final entry in obj.stockPerSize.entries) {
      writer.writeString(entry.key);
      writer.writeInt(entry.value);
    }
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
