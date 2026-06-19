import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/features/products/data/product_repository.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/cloudinary_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/image_pick_service.dart';
import 'package:pfb/shared/widgets/app_form_field.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _repo = ProductRepository();
  final _cloudinaryService = CloudinaryService();
  final _imageService = ImagePickService();
  final _firebaseService = FirebaseService();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _variantsCtrl = TextEditingController();
  final _stockQtyCtrl = TextEditingController(text: '0');
  final _promoTextCtrl = TextEditingController();
  final _promoDiscountCtrl = TextEditingController(text: '0');

  File? _selectedImage;
  bool _featured = false;
  bool _isTrending = false;
  bool _inStock = true;
  bool _loading = false;

  List<String> _selectedCategories = ['General'];

  Future<void> _pickImage() async {
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;

    final sizeBytes = await file.length();
    const maxBytes = 3 * 1024 * 1024;

    if (sizeBytes > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image too large. Max allowed is 3MB'),
        ),
      );
      return;
    }

    setState(() => _selectedImage = file);
  }

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedCategories.contains(category)) {
          _selectedCategories.add(category);
        }
      } else {
        _selectedCategories.remove(category);
      }

      if (_selectedCategories.isEmpty) {
        _selectedCategories = ['General'];
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final stockQty = int.tryParse(_stockQtyCtrl.text.trim()) ?? 0;
    final promoDiscount = double.tryParse(_promoDiscountCtrl.text.trim()) ?? 0;
    final variants = _variantsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (name.isEmpty ||
        description.isEmpty ||
        price == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select an image'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final categories = _selectedCategories.toSet().toList();

    if (_featured && !categories.contains('Featured')) {
      categories.add('Featured');
    }
    if (_isTrending && !categories.contains('Trending')) {
      categories.add('Trending');
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final product = ProductModel(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        createdBy: user.uid,
        createdAt: DateTime.now(),
        category: categories.isEmpty ? 'General' : categories.first,
        categories: categories,
        featured: _featured,
        isTrending: _isTrending,
        inStock: _inStock,
        stockQuantity: stockQty,
        variants: variants,
        promoText: _promoTextCtrl.text.trim(),
        promoDiscountPercent: promoDiscount,
      );

      await _repo.addProduct(product);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _variantsCtrl.dispose();
    _stockQtyCtrl.dispose();
    _promoTextCtrl.dispose();
    _promoDiscountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Add Product',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: 'Create a new product',
                  spacingBottom: 16,
                ),
                AppFormField(
                  controller: _nameCtrl,
                  hintText: 'Product name',
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _descCtrl,
                  hintText: 'Description',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _priceCtrl,
                  hintText: 'Price',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                Text(
                  'Categories',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<String>>(
                  stream: _firebaseService.watchCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? const ['General'];

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        final selected =
                            _selectedCategories.contains(category);

                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (value) =>
                              _toggleCategory(category, value),
                          selectedColor: colors.brandPrimary,
                          backgroundColor: colors.surfaceAlt,
                          labelStyle: GoogleFonts.poppins(
                            color: selected ? Colors.white : colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: selected
                                ? colors.brandPrimary
                                : colors.borderSoft,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _stockQtyCtrl,
                  hintText: 'Stock quantity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _variantsCtrl,
                  hintText: 'Variants (comma separated)',
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _promoTextCtrl,
                  hintText: 'Promo text e.g 20% off this week',
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _promoDiscountCtrl,
                  hintText: 'Promo discount %',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colors.brandPrimary,
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                  title: Text(
                    'Featured product',
                    style: GoogleFonts.poppins(color: colors.textPrimary),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colors.brandPrimary,
                  value: _isTrending,
                  onChanged: (v) => setState(() => _isTrending = v),
                  title: Text(
                    'Trending product',
                    style: GoogleFonts.poppins(color: colors.textPrimary),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colors.brandPrimary,
                  value: _inStock,
                  onChanged: (v) => setState(() => _inStock = v),
                  title: Text(
                    'In stock',
                    style: GoogleFonts.poppins(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.borderSoft),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: colors.textSecondary,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select product image',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Max image size: 3MB',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Product',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
