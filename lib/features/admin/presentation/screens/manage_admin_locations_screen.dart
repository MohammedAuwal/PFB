import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/features/shared/presentation/widgets/premium_location_picker_bottom_sheet.dart';
import 'package:pfb/models/place_suggestion_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_bottom_sheets.dart';
import 'package:pfb/shared/widgets/app_form_field.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ManageAdminLocationsScreen extends StatefulWidget {
  const ManageAdminLocationsScreen({super.key});

  @override
  State<ManageAdminLocationsScreen> createState() =>
      _ManageAdminLocationsScreenState();
}

class _ManageAdminLocationsScreenState
    extends State<ManageAdminLocationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _radiusCtrl = TextEditingController(text: '30');
  final _areasCtrl = TextEditingController();
  final _maxLoadCtrl = TextEditingController(text: '20');

  Future<void> _changeVendorAddress(String currentAddress) async {
    final result = await AppBottomSheets.showSheet<PlaceSuggestionModel>(
      context: context,
      isScrollControlled: true,
      child: PremiumLocationPickerBottomSheet(
        title: 'Set Vendor Pickup Address',
        hintText: 'Search vendor/shop pickup location in Nigeria',
        initialValue: currentAddress,
      ),
    );

    if (result == null || result.displayName.trim().isEmpty) return;

    await _firebaseService.updateVendorPickupAddress(result.displayName);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor pickup location updated'),
      ),
    );
  }

  Future<void> _setMyAdminBase(List<String> existingStates, bool currentActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await AppBottomSheets.showSheet<PlaceSuggestionModel>(
      context: context,
      isScrollControlled: true,
      child: const PremiumLocationPickerBottomSheet(
        title: 'Set My Admin Base Location',
        hintText: 'Search your admin operating location in Nigeria',
      ),
    );

    if (result == null || result.displayName.trim().isEmpty) return;

    final radius = double.tryParse(_radiusCtrl.text.trim()) ?? 30;
    final maxLoad = int.tryParse(_maxLoadCtrl.text.trim()) ?? 20;
    final areas = _areasCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await _firebaseService.updateAdminCoverage(
      adminUid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? (user.email ?? 'Admin'),
      baseAddress: result.displayName,
      baseLat: result.latitude,
      baseLng: result.longitude,
      serviceRadiusKm: radius,
      coverageStates: existingStates,
      coverageAreas: areas,
    );

    await _firebaseService.updateAdminWorkloadConfig(
      adminUid: user.uid,
      isActive: currentActive,
      maxActiveAssignments: maxLoad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your admin coverage location has been updated'),
      ),
    );
  }

  Future<void> _toggleAdminActive(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final maxLoad = int.tryParse(_maxLoadCtrl.text.trim()) ?? 20;

    await _firebaseService.updateAdminWorkloadConfig(
      adminUid: user.uid,
      isActive: value,
      maxActiveAssignments: maxLoad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Admin is now active for assignments'
              : 'Admin paused from assignments',
        ),
      ),
    );
  }

  Future<void> _saveWorkloadOnly(bool currentActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final maxLoad = int.tryParse(_maxLoadCtrl.text.trim()) ?? 20;

    await _firebaseService.updateAdminWorkloadConfig(
      adminUid: user.uid,
      isActive: currentActive,
      maxActiveAssignments: maxLoad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workload settings updated'),
      ),
    );
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _areasCtrl.dispose();
    _maxLoadCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentUser = FirebaseAuth.instance.currentUser;

    return AppPageScaffold(
      title: 'Admin Locations',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<String>(
            stream: _firebaseService.watchVendorPickupAddress(),
            builder: (context, snapshot) {
              final vendorAddress = snapshot.data ?? 'Nigeria';

              return AppSurfaceCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionTitle(
                      title: 'Vendor Pickup Location',
                      subtitle:
                          'This is the pickup point used by the delivery engine for all customer orders.',
                      spacingBottom: 14,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        vendorAddress,
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _changeVendorAddress(vendorAddress),
                        icon: const Icon(Icons.edit_location_alt_rounded),
                        label: Text(
                          'Change Pickup Location',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (currentUser != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.watchAdmins(),
              builder: (context, snapshot) {
                final admins = snapshot.data ?? [];
                Map<String, dynamic>? me;

                try {
                  me = admins.firstWhere((a) => a['uid'] == currentUser.uid);
                } catch (_) {
                  me = null;
                }

                final myBaseAddress = (me?['baseAddress'] ?? '').toString();
                final myRadius =
                    ((me?['serviceRadiusKm'] ?? 30) as num).toDouble();
                final myStates = List<String>.from(me?['coverageStates'] ?? []);
                final myAreas = List<String>.from(me?['coverageAreas'] ?? []);
                final myActive = (me?['isActive'] ?? true) == true;
                final myMaxLoad =
                    ((me?['maxActiveAssignments'] ?? 20) as num).toInt();

                if (_radiusCtrl.text.trim().isEmpty || _radiusCtrl.text == '30') {
                  _radiusCtrl.text = myRadius.toStringAsFixed(0);
                }

                if (_areasCtrl.text.trim().isEmpty && myAreas.isNotEmpty) {
                  _areasCtrl.text = myAreas.join(', ');
                }

                if (_maxLoadCtrl.text.trim().isEmpty ||
                    _maxLoadCtrl.text == '20') {
                  _maxLoadCtrl.text = myMaxLoad.toString();
                }

                return AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionTitle(
                        title: 'My Admin Coverage',
                        subtitle:
                            'Set your operating base so nearby users and orders can be assigned to you first.',
                        spacingBottom: 14,
                      ),
                      if (myBaseAddress.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colors.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Base: $myBaseAddress',
                                style: GoogleFonts.poppins(
                                  color: colors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              if (myStates.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'States: ${myStates.join(', ')}',
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (myAreas.isNotEmpty)
                                Text(
                                  'Areas: ${myAreas.join(', ')}',
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.brandPrimary,
                        value: myActive,
                        onChanged: _toggleAdminActive,
                        title: Text(
                          'Active for assignments',
                          style: GoogleFonts.poppins(color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          'Turn off if you do not want to receive nearby requests now.',
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppFormField(
                        controller: _radiusCtrl,
                        hintText: 'Service radius in km',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AppFormField(
                        controller: _areasCtrl,
                        hintText:
                            'Coverage areas (comma separated, e.g. Ikeja, Yaba, Lekki)',
                      ),
                      const SizedBox(height: 12),
                      AppFormField(
                        controller: _maxLoadCtrl,
                        hintText: 'Maximum active assignments',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _setMyAdminBase(myStates, myActive),
                              icon: const Icon(Icons.my_location_rounded),
                              label: Text(
                                'Set My Base Location',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _saveWorkloadOnly(myActive),
                              child: const Text('Save Workload'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
