import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'product-images';

  /// Returns the current authenticated user's id, or null if not logged in.
  static String? get currentUserId {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the storage object path/filename from a Supabase public CDN URL.
  static String? _extractStorageFileName(String imageUrl) {
    if (!imageUrl.contains('/storage/v1/object/public/$_bucket/')) {
      return null;
    }
    final parts = imageUrl.split('/storage/v1/object/public/$_bucket/');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return Uri.decodeComponent(parts[1]);
    }
    return null;
  }

  /// Uploads local image file to Supabase Storage bucket 'product-images'
  /// and returns the public HTTP CDN URL.
  static Future<String> uploadProductImage(File imageFile) async {
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await imageFile.readAsBytes();

    try {
      await _client.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(fileName);
      debugPrint('✅ Image uploaded to Supabase Storage: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Storage upload failed: $e');
      rethrow;
    }
  }

  /// Insert product into Supabase database table with public HTTP image URL.
  /// Always writes the current authenticated user's id into 'user_id'.
  static Future<void> insertProduct({
    required String nameEn,
    required String nameHi,
    required String description,
    required String category,
    required int priceInRupees,
    required String imageUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ No authenticated user — skipping Supabase insert');
      return;
    }
    try {
      await _client.from('products').insert({
        'name_en': nameEn,
        'name_hi': nameHi,
        'description': description,
        'category': category,
        'price_in_rupees': priceInRupees,
        'status': 'live',
        'image_url': imageUrl,
        'user_id': userId,
      });
      debugPrint('✅ Inserted product into Supabase table for user $userId');
    } catch (e) {
      debugPrint('❌ Supabase insert failed: $e');
      rethrow;
    }
  }

  /// Update product in Supabase database table (scoped by user_id).
  static Future<void> updateProduct(Product product) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _client.from('products').update({
        'name_en': product.nameEn,
        'name_hi': product.nameHi,
        'description': product.description,
        'category': product.category,
        'price_in_rupees': product.priceInRupees,
        'status': product.status.name,
      }).eq('id', product.id).eq('user_id', userId);
      debugPrint('✅ Updated product in Supabase table: ${product.id}');
    } catch (e) {
      debugPrint('⚠️ Supabase update failed: $e');
      rethrow;
    }
  }

  /// Delete product database record and associated image file from Supabase Storage.
  static Future<void> deleteProduct({required String id, String? imageUrl}) async {
    try {
      // 1. Delete database row from products table (RLS will enforce ownership)
      await _client.from('products').delete().eq('id', id);

      // 2. If imageUrl is a valid Supabase Storage URL, remove file from bucket
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final storagePath = _extractStorageFileName(imageUrl);
        if (storagePath != null && storagePath.isNotEmpty) {
          await _client.storage.from(_bucket).remove([storagePath]);
          debugPrint('🗑️ Removed image from Supabase storage: $storagePath');
        }
      }

      debugPrint('✅ Product and image deleted from Supabase: $id');
    } catch (e) {
      debugPrint('❌ Cloud deletion failed: $e');
    }
  }

  /// Fetch products from Supabase for the current authenticated user only.
  static Future<List<Product>> fetchProducts() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final data = await _client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((row) {
      return Product(
        id: row['id']?.toString() ?? const Uuid().v4(),
        nameEn: row['name_en'] as String? ?? 'Handmade Product',
        nameHi: row['name_hi'] as String? ?? 'उत्पाद',
        description: row['description'] as String? ?? '',
        category: row['category'] as String? ?? 'Other',
        priceInRupees: (row['price_in_rupees'] as num?)?.toInt() ?? 0,
        status: ProductStatus.live,
        image: row['image_url'] as String? ?? '',
        isSynced: true,
        userId: userId,
      );
    }).toList();
  }
}

