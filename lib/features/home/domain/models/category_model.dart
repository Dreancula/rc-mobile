class CategoryModel {
  final String id;
  final String name;
  final String? iconPath;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconPath,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconPath,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconPath: map['iconPath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
    };
  }
}
