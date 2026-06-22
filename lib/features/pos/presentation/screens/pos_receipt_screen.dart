import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/models/receipt_model.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';
import 'package:pfb/features/pos/presentation/widgets/pos_receipt_preview.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PosReceiptScreen extends StatefulWidget {
  final PosSaleModel sale;
  final PosRepository repo;

  const PosReceiptScreen({
    super.key,
    required this.sale,
    required this.repo,
  });

  @override
  State<PosReceiptScreen> createState() => _PosReceiptScreenState();
}

class _PosReceiptScreenState extends State<PosReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSaving = false;

  late final ReceiptModel _receipt;

  @override
  void initState() {
    super.initState();
    _receipt = ReceiptModel.fromSale(widget.sale);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        backgroundColor: colors.scaffold,
        title: Text(
          'Receipt',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
        actions: [
          // Save Image
          IconButton(
            tooltip: 'Save as Image',
            icon: Icon(Icons.image_outlined, color: colors.textPrimary),
            onPressed: _isSaving ? null : _saveAsImage,
          ),
          // Share / PDF placeholder (future)
          IconButton(
            tooltip: 'Share',
            icon: Icon(Icons.share_outlined, color: colors.textPrimary),
            onPressed: _shareReceipt,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: RepaintBoundary(
                    key: _receiptKey,
                    child: PosReceiptPreview(receipt: _receipt),
                  ),
                ),
              ),
            ),
          ),

          // Action bar
          _buildActionBar(colors),
        ],
      ),
    );
  }

  Widget _buildActionBar(AppThemeColors colors) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.borderSoft)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Receipt ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.goldTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: colors.brandPrimary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_rounded,
                      color: colors.brandPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _receipt.receiptId,
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // New Sale
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('New Sale'),
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Image
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label:
                        Text(_isSaving ? 'Saving...' : 'Save Receipt'),
                    onPressed: _isSaving ? null : _saveAsImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsImage() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // In a real implementation, use image_gallery_saver or path_provider
      // to save the file. Here we show a success message as the save logic
      // depends on platform-specific packages.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Receipt ${_receipt.receiptId} captured. '
            'Integrate image_gallery_saver to persist.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareReceipt() {
    // Integrate share_plus for full sharing support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Integrate share_plus package for full share support.',
        ),
      ),
    );
  }
}