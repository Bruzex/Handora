import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/order.dart';

/// Singleton that manages the local SQLite database.
///
/// Usage: `final db = await DatabaseHelper.instance.database;`
class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'handora.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            nameEn TEXT NOT NULL,
            nameHi TEXT NOT NULL,
            priceInRupees INTEGER NOT NULL,
            status TEXT NOT NULL,
            image TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            dbId INTEGER PRIMARY KEY AUTOINCREMENT,
            id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            productEn TEXT NOT NULL,
            productHi TEXT NOT NULL,
            amountInRupees INTEGER NOT NULL,
            placedAt TEXT NOT NULL,
            thumbnail TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'new'
          )
        ''');
      },
    );
  }

  // ── Products ──

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> queryAllProducts() async {
    final db = await database;
    final rows = await db.query('products');
    return rows.map(Product.fromMap).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ── Orders ──

  Future<int> insertOrder(Order order) async {
    final db = await database;
    return db.insert('orders', order.toMap());
  }

  Future<List<Order>> queryAllOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'dbId DESC');
    return rows.map(Order.fromMap).toList();
  }

  Future<int> updateOrderStatus(int dbId, String status) async {
    final db = await database;
    return db.update('orders', {'status': status},
        where: 'dbId = ?', whereArgs: [dbId]);
  }

  Future<int> deleteOrder(int dbId) async {
    final db = await database;
    return db.delete('orders', where: 'dbId = ?', whereArgs: [dbId]);
  }
}
