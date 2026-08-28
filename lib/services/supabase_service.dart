import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'product-images';

  /// Upload image to Supabase Storage and return its public URL.
  static Future<String> uploadProductImage(File imageFile) async {
    final fileName = '${const Uuid().v4()}.jpg';
    final path = 'products/$fileName';

    await _client.storage.from(_bucket).upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Insert product into Supabase database table.
  static Future<void> insertProduct({
    required String nameEn,
    required String nameHi,
    required String description,
    required String category,
    required int priceInRupees,
    required String imageUrl,
  }) async {
    await _client.from('products').insert({
      'name_en': nameEn,
      'name_hi': nameHi,
      'description': description,
      'category': category,
      'price_in_rupees': priceInRupees,
      'status': 'live',
      'image_url': imageUrl,
    });
  }

  /// Fetch all products from Supabase ordered by creation date.
  static Future<List<Product>> fetchProducts() async {
    final data = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((row) {
      return Product(
        id: row['id']?.toString() ?? const Uuid().v4(),
        nameEn: row['name_en'] as String? ?? 'Handmade Product',
        nameHi: row['name_hi'] as String? ?? 'हस्तनिर्मित उत्पाद',
        priceInRupees: (row['price_in_rupees'] as num?)?.toInt() ?? 0,
        status: ProductStatus.live,
        image: row['image_url'] as String? ?? '',
      );
    }).toList();
  }
}
