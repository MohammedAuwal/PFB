import 'package:flutter/material.dart';
import 'package:pfb/features/rider/presentation/widgets/location_search_field.dart';
import 'package:pfb/models/place_suggestion_model.dart';

class AddressAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<PlaceSuggestionModel>? onSuggestionSelected;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LocationSearchField(
      controller: controller,
      hintText: 'Enter address anywhere in Nigeria',
      prefixIcon: Icons.location_on_outlined,
      onSuggestionSelected: onSuggestionSelected,
    );
  }
}
