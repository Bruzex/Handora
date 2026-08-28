class Order {
  final int? dbId; // auto-increment PK from SQLite
  final String id;
  final int quantity;
  final String productEn;
  final String productHi;
  final int amountInRupees;
  final String placedAt;
  final String thumbnail;
  final String status; // "new", "shipped", "delivered"

  const Order({
    this.dbId,
    required this.id,
    required this.quantity,
    required this.productEn,
    required this.productHi,
    required this.amountInRupees,
    required this.placedAt,
    required this.thumbnail,
    this.status = 'new',
  });

  Map<String, dynamic> toMap() => {
    if (dbId != null) 'dbId': dbId,
    'id': id,
    'quantity': quantity,
    'productEn': productEn,
    'productHi': productHi,
    'amountInRupees': amountInRupees,
    'placedAt': placedAt,
    'thumbnail': thumbnail,
    'status': status,
  };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    dbId: m['dbId'] as int?,
    id: m['id'] as String,
    quantity: m['quantity'] as int,
    productEn: m['productEn'] as String,
    productHi: m['productHi'] as String,
    amountInRupees: m['amountInRupees'] as int,
    placedAt: m['placedAt'] as String,
    thumbnail: m['thumbnail'] as String,
    status: m['status'] as String? ?? 'new',
  );

  String get formattedAmount {
    final s = amountInRupees.toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted';
  }
}

/// Seed data loaded into SQLite on first launch.
const kSeedOrders = <Order>[
  Order(
    id: 'HND-2481',
    quantity: 1,
    productEn: 'Handmade Scarf',
    productHi: 'हस्तनिर्मित दुपट्टा',
    amountInRupees: 850,
    placedAt: '10 min ago',
    thumbnail: 'assets/images/scarf.jpg',
    status: 'new',
  ),
];
