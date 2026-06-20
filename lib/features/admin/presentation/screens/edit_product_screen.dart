import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/cloudinary_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/image_pick_service.dart';
import 'package:pfb/shared/widgets/app_dialogs.dart';
import 'package:pfb/shared/widgets/app_form_field.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _firebaseService = FirebaseService();
  final _cloudinaryService = CloudinaryService();
  final _imageService = ImagePickService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _variantsCtrl;
  late final TextEditingController _stockQtyCtrl;
  late final TextEditingController _promoTextCtrl;
  late final TextEditingController _promoDiscountCtrl;

  File? _selectedImage;
  late bool _featured;
  late bool _isTrending;
  late bool _inStock;
  late List<String> _selectedCategories;
  bool _loading = false;

  bool get _isSuperAdmin => AppConstants.isSuperAdminUid(
        FirebaseAuth.instance.currentUser?.uid,
      );

  bool get _canEdit {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _isSuperAdmin || uid == widget.product.createdBy;
  }

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description);
    _priceCtrl = TextEditingController(text: widget.product.price.toString());
    _variantsCtrl =
        TextEditingController(text: widget.product.variants.join(', '));
    _stockQtyCtrl =
        TextEditingController(text: widget.product.stockQuantity.toString());
    _promoTextCtrl = TextEditingController(text: widget.product.promoText);
    _promoDiscountCtrl = TextEditingController(
      text: widget.product.promoDiscountPercent.toString(),
    );
    _featured = widget.product.featured;
    _isTrending = widget.product.isTrending;
    _inStock = widget.product.inStock;
    _selectedCategories = widget.product.normalizedCategories.toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_canEdit && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only edit your own products'),
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _pickImage() async {
    if (!_canEdit) return;

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
    if (!_canEdit) return;

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

  Future<void> _save() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own products'),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim());
    final stockQty = int.tryParse(_stockQtyCtrl.text.trim()) ?? 0;
    final promoDiscount = double.tryParse(_promoDiscountCtrl.text.trim()) ?? 0;

    if (price == null ||
        _nameCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill product name, description and valid price'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String imageUrl = widget.product.imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      }

      final categories = _selectedCategories.toSet().toList();

      if (_featured && !categories.contains('Featured')) {
        categories.add('Featured');
      }
      if (_isTrending && !categories.contains('Trending')) {
        categories.add('Trending');
      }

      final updated = ProductModel(
        id: widget.product.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: price,
        imageUrl: imageUrl,
        createdBy: widget.product.createdBy,
        createdAt: widget.product.createdAt,
        category: categories.isEmpty ? 'General' : categories.first,
        categories: categories,
        featured: _featured,
        isTrending: _isTrending,
        inStock: _inStock,
        stockQuantity: stockQty,
        variants: _variantsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        promoText: _promoTextCtrl.text.trim(),
        promoDiscountPercent: promoDiscount,
      );

      await _firebaseService.updateProduct(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: $e'),
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
      title: 'Edit Product',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSuperAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Created by: ${widget.product.createdBy}',
                      style: GoogleFonts.poppins(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const AppSectionTitle(
                  title: 'Edit product details',
                  spacingBottom: 12,
                ),
                AppFormField(
                  controller: _nameCtrl,
                  hintText: 'Product name',
                  enabled: _canEdit,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _descCtrl,
                  hintText: 'Description',
                  maxLines: 4,
                  enabled: _canEdit,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _priceCtrl,
                  hintText: 'Price',
                  enabled: _canEdit,
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
                        final selected = _selectedCategories.contains(category);

                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: _canEdit
                              ? (value) => _toggleCategory(category, value)
                              : null,
                          selectedColor: colors.brandPrimary,
                          backgroundColor: colors.surfaceAlt,
                          disabledColor: colors.surfaceAlt,
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
                  enabled: _canEdit,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _variantsCtrl,
                  hintText: 'Variants comma separated',
                  enabled: _canEdit,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _promoTextCtrl,
                  hintText: 'Promo text',
                  enabled: _canEdit,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _promoDiscountCtrl,
                  hintText: 'Promo discount %',
                  enabled: _canEdit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colors.brandPrimary,
                  value: _featured,
                  onChanged: _canEdit ? (v) => setState(() => _featured = v) : null,
                  title: Text(
                    'Featured',
                    style: GoogleFonts.poppins(color: colors.textPrimary),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colors.brandPrimary,
                  value: _isTrending,
                  onChanged:
                      _canEdit ? (v) => setState(() => _isTrending = v) : null,
                  title: Text(
                    'Trending',
                    style: GoogleFonts.poppins(color: colors.textPrimary),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: colors.brandPrimary,
                  value: _inStock,
                  onChanged: _canEdit ? (v) => setState(() => _inStock = v) : null,
                  title: Text(
                    'In stock',
                    style: GoogleFonts.poppins(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _canEdit ? _pickImage : null,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.borderSoft),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : _hasValidImage(widget.product.imageUrl)
                              ? Image.network(
                                  widget.product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: context.colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: context.colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_loading || !_canEdit) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
