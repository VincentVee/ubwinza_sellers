class FirebasePaths {
  static const sellers = 'sellers';
  static const categories = 'categories';
  static const orders = 'orders';

  static String productsCol(String sellerId) => 'sellers/$sellerId/products';
  static String productDoc(String sellerId, String productId) => 'sellers/$sellerId/products/$productId';


// storage
  static String productImagePath(String sellerId, String productId, int index) =>
      'sellersImages/$sellerId/products/$productId-$index.jpg';
}