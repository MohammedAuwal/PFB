import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _firebaseService = FirebaseService();
  final _categoryCtrl = TextEditingController();

  Future<void> _addCategory() async {
    final name = _categoryCtrl.text.trim();
    if (name.isEmpty) return;

    await _firebaseService.addCategory(name);
    _categoryCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category added')),
    );
  }

  Future<void> _removeCategory(String category) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove Category'),
            content: Text('Remove "$category"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await _firebaseService.removeCategory(category);
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Manage Categories',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            child: Column(
              children: [
                TextField(
                  controller: _categoryCtrl,
                  style: GoogleFonts.poppins(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Category name',
                    hintStyle: GoogleFonts.poppins(color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addCategory,
                    child: const Text('Add Category'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return Text(
                  'No categories yet',
                  style: GoogleFonts.poppins(color: colors.textSecondary),
                );
              }

              return Column(
                children: categories.map((category) {
                  final isProtected = const [
                    'General',
                    'Trending',
                    'Featured',
                  ].contains(category);

                  return AppSurfaceCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(
                        category,
                        style: GoogleFonts.poppins(color: colors.textPrimary),
                      ),
                      subtitle: isProtected
                          ? Text(
                              'Default category',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      trailing: IconButton(
                        onPressed: isProtected
                            ? null
                            : () async {
                                await _removeCategory(category);
                              },
                        icon: Icon(
                          Icons.delete_outline,
                          color: isProtected
                              ? colors.textSecondary.withOpacity(0.4)
                              : colors.error,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
