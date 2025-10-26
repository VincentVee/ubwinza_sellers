class ProductModel {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String categoryId;
  final num price;
  final int stock;
  final List<Map<String, dynamic>>? sizes; // CHANGED: Now Map instead of String
  final List<Map<String, dynamic>>? addons;
  final int? prepTimeMinutes;
  final List<String>? variations;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.stock,
    required this.images,
    List<Map<String, dynamic>>? sizes, // CHANGED
    List<Map<String, dynamic>>? addons,
    int? prepTimeMinutes,
    List<String>? variations,
    required this.isActive,
    required this.createdAt,
  }) : sizes = sizes,
       addons = addons,
       prepTimeMinutes = prepTimeMinutes,
       variations = variations;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'price': price,
      'stock': stock,
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt,
    };
    
    // Explicitly add the optional fields
    if (sizes != null) {
      map['sizes'] = sizes;
    }
    if (addons != null) {
      map['addons'] = addons;
    }
    if (prepTimeMinutes != null) {
      map['prepTimeMinutes'] = prepTimeMinutes;
    }
    if (variations != null) {
      map['variations'] = variations;
    }
    
    return map;
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> m) {
    return ProductModel(
      id: id,
      sellerId: m['sellerId'] as String,
      name: (m['name'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      categoryId: (m['categoryId'] ?? '') as String,
      price: (m['price'] ?? 0) as num,
      stock: (m['stock'] ?? 0) as int,
      images: List<String>.from(m['images'] ?? const []),
      sizes: _parseSizesList(m['sizes']), // CHANGED: Use new parser
      addons: _parseAddonsList(m['addons']),
      variations: _parseStringList(m['variations']),
      prepTimeMinutes: m['prepTimeMinutes'] as int?,
      isActive: (m['isActive'] as bool?) ?? true,
      createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Helper method to safely parse string lists from Firestore
  static List<String>? _parseStringList(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return List<String>.from(data.map((item) => item.toString()));
    }
    return null;
  }

  // NEW: Helper method to parse sizes list
  static List<Map<String, dynamic>>? _parseSizesList(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return {
            'id': item['id'] ?? item['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'size_${DateTime.now().millisecondsSinceEpoch}',
            'name': item['name'] ?? 'Unnamed Size',
            'description': item['description'] ?? '',
            'priceModifier': (item['priceModifier'] is num) ? (item['priceModifier'] as num).toDouble() : 0.0,
            'inStock': item['inStock'] ?? true,
          };
        } else if (item is String) {
          // Convert old string format to new map format
          return {
            'id': item.toLowerCase().replaceAll(' ', '_'),
            'name': item,
            'description': '',
            'priceModifier': 0.0,
            'inStock': true,
          };
        }
        return {
          'id': 'size_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Unnamed Size',
          'description': '',
          'priceModifier': 0.0,
          'inStock': true,
        };
      }).toList();
    }
    return null;
  }

  // Helper method to parse addons list
  static List<Map<String, dynamic>>? _parseAddonsList(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return {
            'id': item['id'] ?? item['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'addon_${DateTime.now().millisecondsSinceEpoch}',
            'name': item['name'] ?? 'Unnamed Addon',
            'description': item['description'] ?? '',
            'price': (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
            'inStock': item['inStock'] ?? true,
          };
        } else if (item is String) {
          return {
            'id': item.toLowerCase().replaceAll(' ', '_'),
            'name': item,
            'description': '',
            'price': 0.0,
            'inStock': true,
          };
        }
        return {
          'id': 'addon_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Unnamed Addon',
          'description': '',
          'price': 0.0,
          'inStock': true,
        };
      }).toList();
    }
    return null;
  }
}