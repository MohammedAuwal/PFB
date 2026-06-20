import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/products/data/product_repository.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/cloudinary_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/image_pick_service.dart';
import 'package:pfb/shared/widgets/app_form_field.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _repo              = ProductRepository();
  final _cloudinaryService = CloudinaryService();
  final _imageService      = ImagePickService();
  final _firebaseService   = FirebaseService();

  final _nameCtrl          = TextEditingController();
  final _descCtrl          = TextEditingController();
  final _priceCtrl         = TextEditingController();
  final _variantsCtrl      = TextEditingController();
  final _stockQtyCtrl      = TextEditingController(text: '0');
  final _promoTextCtrl     = TextEditingController();
  final _promoDiscountCtrl = TextEditingController(text: '0');

  File? _selectedImage;
  bool _featured   = false;
  bool _isTrending = false;
  bool _inStock    = true;
  bool _loading    = false;

  List<String> _selectedCategories = ['General'];

  Future<void> _pickImage() async {
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;

    final sizeBytes  = await file.length();
    const maxBytes   = 3 * 1024 * 1024;

    if (sizeBytes > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image too large. Max allowed is 3MB',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: context.appColors.error,
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

  void _showSnack(String message, {bool isError = false}) {
    final colors = context.appColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isError ? colors.error : AppPalette.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name         = _nameCtrl.text.trim();
    final description  = _descCtrl.text.trim();
    final price        = double.tryParse(_priceCtrl.text.trim());
    final stockQty     = int.tryParse(_stockQtyCtrl.text.trim()) ?? 0;
    final promoDiscount =
        double.tryParse(_promoDiscountCtrl.text.trim()) ?? 0;
    final variants = _variantsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (name.isEmpty ||
        description.isEmpty ||
        price == null ||
        _selectedImage == null) {
      _showSnack(
        'Please complete all fields and select an image',
        isError: true,
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
      final id       = DateTime.now().millisecondsSinceEpoch.toString();

      final product = ProductModel(
        id:                   id,
        name:                 name,
        description:          description,
        price:                price,
        imageUrl:             imageUrl,
        createdBy:            user.uid,
        createdAt:            DateTime.now(),
        category:             categories.isEmpty ? 'General' : categories.first,
        categories:           categories,
        featured:             _featured,
        isTrending:           _isTrending,
        inStock:              _inStock,
        stockQuantity:        stockQty,
        variants:             variants,
        promoText:            _promoTextCtrl.text.trim(),
        promoDiscountPercent: promoDiscount,
      );

      await _repo.addProduct(product);

      if (!mounted) return;
      _showSnack('Product created successfully ✓');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to add product: $e', isError: true);
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
    final isDark = context.isDarkMode;

    return AppPageScaffold(
      title: 'Add Product',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            padding:      const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Section header ───────────────────────────────────
                Row(
                  children: [
                    Container(
                      width:  3.5,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppPalette.primaryDark,
                            AppPalette.primaryLight,
                          ],
                          begin: Alignment.topCenter,
                          end:   Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const AppSectionTitle(
                      title:         'Create a new product',
                      spacingBottom: 0,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Fields ───────────────────────────────────────────
                AppFormField(
                  controller: _nameCtrl,
                  hintText:   'Product name',
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _descCtrl,
                  hintText:   'Description',
                  maxLines:   4,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller:   _priceCtrl,
                  hintText:     'Price (₦)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),

                const SizedBox(height: 18),

                // ── Categories ───────────────────────────────────────
                Text(
                  'Fabric Categories',
                  style: GoogleFonts.poppins(
                    color:      colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize:   14,
                  ),
                ),
                const SizedBox(height: 10),

                StreamBuilder<List<String>>(
                  stream: _firebaseService.watchCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? const ['General'];

                    return Wrap(
                      spacing:    8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        final selected =
                            _selectedCategories.contains(category);

                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (v) =>
                              _toggleCategory(category, v),
                          // Gold when selected — brand consistent
                          selectedColor: AppPalette.primary,
                          backgroundColor: colors.surfaceAlt,
                          checkmarkColor:  AppPalette.secondary,
                          labelStyle: GoogleFonts.poppins(
                            color: selected
                                ? AppPalette.secondary
                                : colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize:   13,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppPalette.primary
                                : colors.borderSoft,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                AppFormField(
                  controller:   _stockQtyCtrl,
                  hintText:     'Stock quantity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _variantsCtrl,
                  hintText:   'Variants (comma separated, e.g. Red, Blue)',
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller: _promoTextCtrl,
                  hintText:   'Promo text e.g 20% off this week',
                ),
                const SizedBox(height: 12),
                AppFormField(
                  controller:   _promoDiscountCtrl,
                  hintText:     'Promo discount %',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),

                const SizedBox(height: 16),

                // ── Toggles ──────────────────────────────────────────
                _LuxurySwitch(
                  value:    _featured,
                  label:    'Featured product',
                  subtitle: 'Show in featured collections',
                  onChanged: (v) => setState(() => _featured = v),
                  colors:   colors,
                ),
                const Divider(height: 1),
                _LuxurySwitch(
                  value:    _isTrending,
                  label:    'Trending product',
                  subtitle: 'Show in trending section',
                  onChanged: (v) => setState(() => _isTrending = v),
                  colors:   colors,
                ),
                const Divider(height: 1),
                _LuxurySwitch(
                  value:    _inStock,
                  label:    'In stock',
                  subtitle: 'Available for purchase',
                  onChanged: (v) => setState(() => _inStock = v),
                  colors:   colors,
                ),

                const SizedBox(height: 18),

                // ── Image picker ─────────────────────────────────────
                GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 200,
                    width:  double.infinity,
                    decoration: BoxDecoration(
                      color:        _selectedImage != null
                          ? Colors.transparent
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedImage != null
                            ? AppPalette.primary.withOpacity(0.50)
                            : colors.borderSoft,
                        width: _selectedImage != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width:  56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color:  AppPalette.primary
                                      .withOpacity(0.10),
                                  shape:  BoxShape.circle,
                                  border: Border.all(
                                    color: AppPalette.primary
                                        .withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppPalette.primary,
                                  size:  28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select product image',
                                style: GoogleFonts.poppins(
                                  color:      colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Max image size: 3MB',
                                style: GoogleFonts.poppins(
                                  color:    colors.textSecondary
                                      .withOpacity(0.65),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                                // Gold overlay + change label
                                Positioned(
                                  bottom: 0,
                                  left:   0,
                                  right:  0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.60),
                                        ],
                                        begin: Alignment.topCenter,
                                        end:   Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.edit_rounded,
                                          color: AppPalette.primary,
                                          size:  16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Change image',
                                          style: GoogleFonts.poppins(
                                            color:      AppPalette.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize:   13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                // ── Save button — Gold CTA ───────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: AppPalette.secondary,
                      elevation:       0,
                      shadowColor:     AppPalette.primary.withOpacity(0.30),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width:  22,
                            height: 22,
                            child:  CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:       AppPalette.secondary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Save Product',
                                style: GoogleFonts.poppins(
                                  fontWeight:   FontWeight.w700,
                                  fontSize:     16,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Luxury Switch Row
// ─────────────────────────────────────────────────────────────────────────────

class _LuxurySwitch extends StatelessWidget {
  final bool value;
  final String label;
  final String subtitle;
  final ValueChanged<bool> onChanged;
  final AppThemeColors colors;

  const _LuxurySwitch({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      // Gold when active — brand consistent
      activeColor:      AppPalette.primary,
      activeTrackColor: AppPalette.primary.withOpacity(0.35),
      value:    value,
      onChanged: onChanged,
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color:      colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize:   14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color:    colors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
