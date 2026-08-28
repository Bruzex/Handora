import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

/// Bridges the UI and SQLite database for products and orders.
///
/// Call [init] once at app startup to seed initial data (if first run)
/// and load everything into memory. After that, use the mutation methods
/// which write to the DB and then refresh the in-memory lists.
class DataProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Product> _products = [];
  List<Order> _orders = [];
  bool _initialized = false;

  List<Product> get products => _products;
  List<Order> get orders => _orders;
  bool get initialized => _initialized;

  int get productCount => _products.length;
  int get activeProductCount =>
      _products.where((p) => p.status == ProductStatus.live).length;

  /// Sum of all order amounts — formatted for display.
  String get todaysSales {
    final total = _orders.fold<int>(0, (sum, o) => sum + o.amountInRupees);
    final s = total.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$s';
  }

  /// Seeds the database on first run, then loads everything.
  Future<void> init() async {
    final existingProducts = await _db.queryAllProducts();

    if (existingProducts.isEmpty) {
      // First launch — seed with default data
      for (final p in kSeedProducts) {
        await _db.insertProduct(p);
      }
      for (final o in kSeedOrders) {
        await _db.insertOrder(o);
      }
    }

    await loadProducts();
    await loadOrders();
    _initialized = true;
    notifyListeners();
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

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  Future<void> updateOrderStatus(int dbId, String status) async {
    await _db.updateOrderStatus(dbId, status);
    await loadOrders();
  }

  Future<void> addOrder(Order order) async {
    await _db.insertOrder(order);
    await loadOrders();
  }
}
