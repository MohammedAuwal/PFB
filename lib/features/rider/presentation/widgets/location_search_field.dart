import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/place_suggestion_model.dart';
import 'package:pfb/services/geocoding_service.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<PlaceSuggestionModel>? onSuggestionSelected;
  final VoidCallback? onUseCurrentLocation;
  final bool showCurrentLocationAction;
  final ValueChanged<bool>? onSelectionValidityChanged;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.onSuggestionSelected,
    this.onUseCurrentLocation,
    this.showCurrentLocationAction = false,
    this.onSelectionValidityChanged,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final GeocodingService _geocodingService = GeocodingService();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _loading = false;
  bool _hasSelectedSuggestion = false;
  List<PlaceSuggestionModel> _suggestions = [];
  String _lastConfirmedValue = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_handleFocusChange);
  }

  void _notifyValidity() {
    widget.onSelectionValidityChanged?.call(_hasSelectedSuggestion);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    } else {
      _showOverlayIfNeeded();
    }
  }

  void _onChanged() {
    final current = widget.controller.text.trim();

    if (current != _lastConfirmedValue) {
      if (_hasSelectedSuggestion) {
        _hasSelectedSuggestion = false;
        _notifyValidity();
      }
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = widget.controller.text.trim();

      if (query.length < 2) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _loading = false;
          });
          _removeOverlay();
        }
        return;
      }

      if (mounted) {
        setState(() => _loading = true);
      }
      _showOverlayIfNeeded();

      try {
        final results = await _geocodingService.searchSuggestions(query);
        if (!mounted) return;

        setState(() {
          _suggestions = results;
          _loading = false;
        });

        if (_suggestions.isEmpty) {
          _removeOverlay();
        } else {
          _showOverlayIfNeeded(forceRebuild: true);
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _suggestions = [];
        });
        _removeOverlay();
      }
    });
  }

  void _selectSuggestion(PlaceSuggestionModel suggestion) {
    widget.controller.text = suggestion.displayName;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
    _lastConfirmedValue = suggestion.displayName;
    _hasSelectedSuggestion = true;
    _notifyValidity();
    widget.onSuggestionSelected?.call(suggestion);
    _suggestions = [];
    _removeOverlay();
    _focusNode.unfocus();
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final colors = context.appColors;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 64),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: colors.borderSoft),
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: colors.borderSoft),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: colors.brandPrimary,
                            ),
                            title: Text(
                              suggestion.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                            onTap: () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOverlayIfNeeded({bool forceRebuild = false}) {
    if (!_focusNode.hasFocus) return;
    if (_loading || _suggestions.isNotEmpty) {
      if (_overlayEntry != null && !forceRebuild) return;
      _removeOverlay();
      _overlayEntry = _buildOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.removeListener(_handleFocusChange);
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final showInvalid =
        widget.controller.text.trim().isNotEmpty && !_hasSelectedSuggestion;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: GoogleFonts.poppins(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.poppins(color: colors.textSecondary),
              prefixIcon: Icon(widget.prefixIcon),
              suffixIcon: widget.showCurrentLocationAction
                  ? IconButton(
                      onPressed: widget.onUseCurrentLocation,
                      icon: const Icon(Icons.gps_fixed_rounded),
                      tooltip: 'Use current location',
                    )
                  : (_hasSelectedSuggestion
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colors.success,
                        )
                      : null),
              filled: true,
              fillColor: colors.surfaceAlt,
            ),
          ),
          if (showInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 6),
              child: Text(
                'Please choose a location from the suggestion list',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
