import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfb/models/product_model.dart';

class ProductDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Stream<List<ProductModel>> watchProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> saveProduct(ProductModel product) async {
    await _products.doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }
}
