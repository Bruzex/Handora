import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../services/supabase_service.dart';

/// Bridges the UI, local SQLite database, and Supabase backend.
///
/// Call [init] once at app startup to seed initial data (if first run)
/// and load everything into memory. After that, use the mutation methods
/// which write to the DB and then refresh the in-memory lists.
class DataProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Product> _products = [];
  List<Order> _orders = [];
  bool _initialized = false;
  bool _isProcessingAi = false;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<Order> get recentOrders => _orders.take(5).toList();
  bool get initialized => _initialized;
  bool get isProcessingAi => _isProcessingAi;
  bool get isSyncing => _isSyncing;

  int get productCount => _products.length + (_isProcessingAi ? 1 : 0);
  int get activeProductCount =>
      _products.where((p) => p.status == ProductStatus.live).length;
  int get pendingSyncCount => _products.where((p) => !p.isSynced).length;
  bool get hasPendingSync => pendingSyncCount > 0;

  void setProcessingAi(bool value) {
    if (_isProcessingAi == value) return;
    _isProcessingAi = value;
    notifyListeners();
  }

  /// Sum of all active / non-cancelled order amounts — formatted for display.
  String get todaysSales {
    final nonCancelled = _orders.where((o) => o.status.toLowerCase() != 'cancelled');
    final total = nonCancelled.fold<int>(0, (sum, o) => sum + o.amountInRupees);
    final s = total.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$s';
  }

  /// Seeds the database on first run, then loads everything and starts network listener.
  Future<void> init() async {
    final existingProducts = await _db.queryAllProducts();
    if (existingProducts.isEmpty) {
      for (final p in kSeedProducts) {
        await _db.insertProduct(p);
      }
    }

    final existingOrders = await _db.queryAllOrders();
    if (existingOrders.isEmpty) {
      for (final o in kSeedOrders) {
        await _db.insertOrder(o);
      }
    }

    await loadProducts();
    await loadOrders();
    _initialized = true;
    notifyListeners();

    // Listen to network state changes for automatic background sync
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && hasPendingSync) {
        debugPrint(
            '🌐 Network connected: Auto-syncing $pendingSyncCount pending products...');
        syncOfflineProducts();
      }
    });

    // Trigger sync if online and pending
    syncOfflineProducts();
  }

  Future<void> loadProducts() async {
    _products = await _db.queryAllProducts();
    notifyListeners();
  }

  Future<void> loadOrders() async {
    _orders = await _db.queryAllOrders();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _db.insertProduct(product);
    await loadProducts();
  }

  /// Updates product details locally in SQLite and in Supabase if online.
  Future<void> updateProduct(Product product) async {
    var toSave = product;
    try {
      if (product.isSynced) {
        await SupabaseService.updateProduct(product);
      }
    } catch (e) {
      debugPrint('⚠️ Supabase update failed (marking product as unsynced): $e');
      toSave = product.copyWith(isSynced: false);
    }
    await _db.updateProduct(toSave);
    await loadProducts();
  }

  /// Syncs any offline / pending products to Supabase Storage and database.
  Future<void> syncOfflineProducts() async {
    if (_isSyncing) return;
    final unsynced = _products.where((p) => !p.isSynced).toList();
    if (unsynced.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      for (final p in unsynced) {
        try {
          String publicUrl = p.image;
          // If image is a local file path, upload to Supabase Storage
          if (!p.image.startsWith('http://') && !p.image.startsWith('https://')) {
            final file = File(p.image);
            if (await file.exists()) {
              publicUrl = await SupabaseService.uploadProductImage(file);
            }
          }

          // Insert into Supabase table
          await SupabaseService.insertProduct(
            nameEn: p.nameEn,
            nameHi: p.nameHi,
            description: p.description,
            category: p.category,
            priceInRupees: p.priceInRupees,
            imageUrl: publicUrl,
          );

          // Update local SQLite record with isSynced = true and remote public URL
          final updated = Product(
            id: p.id,
            nameEn: p.nameEn,
            nameHi: p.nameHi,
            description: p.description,
            category: p.category,
            priceInRupees: p.priceInRupees,
            status: p.status,
            image: publicUrl,
            isSynced: true,
          );
          await _db.updateProduct(updated);
          debugPrint('✅ Synced offline product ${p.id} to Supabase');
        } catch (e) {
          debugPrint('⚠️ Sync attempt for product ${p.id} pending: $e');
        }
      }
    } finally {
      _isSyncing = false;
      await loadProducts();
    }
  }

  /// Deletes product from local SQLite and Supabase (PostgreSQL + Storage bucket), then refreshes UI.
  Future<void> deleteProduct(String id) async {
    Product? targetProduct;
    try {
      targetProduct = _products.firstWhere((p) => p.id == id);
    } catch (_) {
      targetProduct = null;
    }

    await _db.deleteProduct(id);

    try {
      await SupabaseService.deleteProduct(
        id: id,
        imageUrl: targetProduct?.image,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase deletion error: $e');
    }

    await loadProducts();
  }

  /// Updates an order status in local SQLite and refreshes orders.
  Future<void> updateOrderStatus(int dbId, String status) async {
    await _db.updateOrderStatus(dbId, status);
    await loadOrders();
  }

  Future<void> addOrder(Order order) async {
    await _db.insertOrder(order);
    await loadOrders();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
