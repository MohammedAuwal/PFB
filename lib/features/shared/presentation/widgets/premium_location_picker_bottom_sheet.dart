import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/features/rider/presentation/widgets/location_search_field.dart';
import 'package:pfb/models/place_suggestion_model.dart';
import 'package:pfb/services/location_service.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class PremiumLocationPickerBottomSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String initialValue;
  final bool enableCurrentLocation;

  const PremiumLocationPickerBottomSheet({
    super.key,
    required this.title,
    required this.hintText,
    this.initialValue = '',
    this.enableCurrentLocation = false,
  });

  @override
  State<PremiumLocationPickerBottomSheet> createState() =>
      _PremiumLocationPickerBottomSheetState();
}

class _PremiumLocationPickerBottomSheetState
    extends State<PremiumLocationPickerBottomSheet> {
  final _controller = TextEditingController();
  final _locationService = LocationService();

  PlaceSuggestionModel? _selectedSuggestion;
  bool _loadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
  }

  Future<void> _useCurrentLocation() async {
    if (!widget.enableCurrentLocation || _loadingCurrentLocation) return;

    setState(() => _loadingCurrentLocation = true);

    try {
      final result = await _locationService.getCurrentResolvedLocation();

      final suggestion = PlaceSuggestionModel(
        displayName: result.displayName,
        latitude: result.latitude,
        longitude: result.longitude,
      );

      _controller.text = suggestion.displayName;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );

      setState(() {
        _selectedSuggestion = suggestion;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to use current location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingCurrentLocation = false);
      }
    }
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    Navigator.of(context).pop(
      _selectedSuggestion ??
          PlaceSuggestionModel(
            displayName: value,
            latitude: 0,
            longitude: 0,
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.appColors;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Stack(
                children: [
                  LocationSearchField(
                    controller: _controller,
                    hintText: widget.hintText,
                    prefixIcon: Icons.location_on_outlined,
                    showCurrentLocationAction: widget.enableCurrentLocation,
                    onUseCurrentLocation: _useCurrentLocation,
                    onSuggestionSelected: (suggestion) {
                      _selectedSuggestion = suggestion;
                    },
                  ),
                  if (_loadingCurrentLocation)
                    Positioned(
                      right: 48,
                      top: 14,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: Text(
                    'Use This Location',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
