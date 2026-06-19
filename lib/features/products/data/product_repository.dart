import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfb/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Future<void> addProduct(ProductModel product) async {
    await _products.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _products.doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Stream<List<ProductModel>> watchProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
            .toList();
      },
    );
  }

  Stream<List<ProductModel>> watchTrendingProducts() {
    return watchProducts().map(
      (items) => items.where((product) => product.isTrending).toList(),
    );
  }

  Stream<List<ProductModel>> watchFeaturedProducts() {
    return watchProducts().map(
      (items) => items.where((product) => product.featured).toList(),
    );
  }
}
