class OrderItemModel {
  final String productId;
  final String name;
  final String categoryId;
  final num price;
  final int qty;
  final String? imageUrl;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.qty,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'categoryId': categoryId,
    'price': price,
    'qty': qty,
    'imageUrl': imageUrl,
  };

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
    productId: m['productId'] as String,
    name: (m['name'] ?? '') as String,
    categoryId: (m['categoryId'] ?? '') as String,
    price: (m['price'] ?? 0) as num,
    qty: (m['qty'] ?? 0) as int,
    imageUrl: m['imageUrl'] as String?,
  );
}
