enum ProductStatus { live, draft }

class Product {
  final String id;
  final String nameEn;
  final String nameHi;
  final int priceInRupees;
  final ProductStatus status;
  final String image;

  const Product({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.priceInRupees,
    required this.status,
    required this.image,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nameEn': nameEn,
    'nameHi': nameHi,
    'priceInRupees': priceInRupees,
    'status': status.name,
    'image': image,
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as String,
    nameEn: m['nameEn'] as String,
    nameHi: m['nameHi'] as String,
    priceInRupees: m['priceInRupees'] as int,
    status: ProductStatus.values.byName(m['status'] as String),
    image: m['image'] as String,
  );

  /// Format price for display: 450 → "₹450", 1250 → "₹1,250"
  String get formattedPrice {
    final s = priceInRupees.toString();
    // Indian number formatting (groups of 3 then 2)
    final formatted = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted';
  }
}

/// Seed data loaded into SQLite on first launch.
const kSeedProducts = <Product>[
  Product(
    id: 'p-clay-pot',
    nameEn: 'Handmade Clay Pot',
    nameHi: 'हस्तनिर्मित मिट्टी का घड़ा',
    priceInRupees: 450,
    status: ProductStatus.live,
    image: 'assets/images/clay_pot.jpg',
  ),
  Product(
    id: 'p-scarf',
    nameEn: 'Handmade Scarf',
    nameHi: 'हस्तनिर्मित दुपट्टा',
    priceInRupees: 850,
    status: ProductStatus.live,
    image: 'assets/images/scarf.jpg',
  ),
  Product(
    id: 'p-wooden-toys',
    nameEn: 'Wooden Craft Toys',
    nameHi: 'लकड़ी के खिलौने',
    priceInRupees: 300,
    status: ProductStatus.draft,
    image: 'assets/images/wooden_toys.jpg',
  ),
];
