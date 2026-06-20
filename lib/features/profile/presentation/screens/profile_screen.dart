// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/theme_scope.dart';
import 'package:pfb/features/auth/presentation/screens/login_screen.dart';
import 'package:pfb/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pfb/features/profile/presentation/widgets/address_autocomplete_field.dart';
import 'package:pfb/models/place_suggestion_model.dart';
import 'package:pfb/services/cloudinary_service.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/image_pick_service.dart';
import 'package:pfb/services/local_notification_service.dart';
import 'package:pfb/shared/widgets/app_bottom_sheets.dart';
import 'package:pfb/shared/widgets/app_dialogs.dart';
import 'package:pfb/shared/widgets/app_list_tile_card.dart';
import 'package:pfb/shared/widgets/app_metric_card.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final bool showScaffold;

  const ProfileScreen({super.key, this.showScaffold = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService       = FirebaseAuthService();
  final _firebaseService   = FirebaseService();
  final _imageService      = ImagePickService();
  final _cloudinaryService = CloudinaryService();
  final _addressCtrl       = TextEditingController();

  bool _uploadingPhoto = false;
  bool _loggingOut     = false;
  bool _savingName     = false;
  PlaceSuggestionModel? _selectedAddressSuggestion;

  String _currentNotifSound = 'default';

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    _loadNotificationSound();
  }

  Future<void> _loadNotificationSound() async {
    final sound =
        await LocalNotificationService.instance.getNotificationSound();
    if (mounted) setState(() => _currentNotifSound = sound);
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          redirectTo: RouteNames.redirectProfile,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final photoUrl = await _cloudinaryService.uploadImage(file);
      await _firebaseService.updateProfilePhoto(photoUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final controller = TextEditingController(text: currentName);
    final colors     = context.appColors;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = ctx.appColors;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Name',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          content: TextField(
            controller:         controller,
            textCapitalization: TextCapitalization.words,
            autofocus:          true,
            style:              GoogleFonts.poppins(color: c.textPrimary),
            decoration: InputDecoration(
              hintText:  'Enter your full name',
              hintStyle: GoogleFonts.poppins(color: c.textSecondary),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              // Gold button → black text (Phlakes brand contrast)
              style: ElevatedButton.styleFrom(
                backgroundColor: c.brandPrimary,
                foregroundColor: AppPalette.secondary,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty || !mounted) return;

    setState(() => _savingName = true);

    try {
      await _firebaseService.updateDisplayName(newName.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Failed to update name: $e'),
          backgroundColor: colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _addAddress() async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address')),
      );
      return;
    }

    try {
      await _firebaseService.addAddress(address);
      _addressCtrl.clear();
      setState(() => _selectedAddressSuggestion = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added and selected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add address: $e')),
      );
    }
  }

  Future<void> _removeAddress(String address) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final confirm = await AppDialogs.confirm(
      context:     context,
      title:       'Remove address',
      message:     'Are you sure you want to remove this address?',
      confirmText: 'Remove',
      destructive: true,
      icon:        Icons.delete_outline_rounded,
    );

    if (!confirm) return;

    try {
      await _firebaseService.removeAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove address: $e')),
      );
    }
  }

  Future<void> _selectAddress(String address) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    try {
      await _firebaseService.setSelectedAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery address selected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select address: $e')),
      );
    }
  }

  // ── WhatsApp Support — updated to Phlakes Fabrics ─────────────────────────
  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse(
      'https://wa.me/2340000000000?text=Hello%20Phlakes%20Fabrics%20support',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  // ── About Dialog — updated to Phlakes Fabrics ─────────────────────────────
  Future<void> _showAboutDialog() async {
    await AppDialogs.info(
      context: context,
      title:   'Phlakes Fabrics',
      message:
          'Premium African fabrics, textiles & traditional products '
          'delivered to your doorstep.\n\nVersion 1.0.0',
      icon: Icons.info_outline_rounded,
    );
  }

  Future<void> _handleLogout() async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    if (_loggingOut) return;

    final confirm = await AppDialogs.confirm(
      context:     context,
      title:       'Log out',
      // ── Updated: Phlakes Fabrics brand name ──────────────────────
      message:     'Are you sure you want to log out of Phlakes Fabrics?',
      confirmText: 'Log out',
      destructive: true,
      icon:        Icons.logout_rounded,
    );

    if (!confirm || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _showNotificationSoundPicker() {
    final sounds = LocalNotificationService.instance.availableSounds;

    AppBottomSheets.showSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final sheetColors = ctx.appColors;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize:      MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBottomSheets.sheetHeader(
                  ctx,
                  title:    'Notification Sound',
                  // ── Updated: Phlakes brand name ────────────────
                  subtitle: 'Choose how Phlakes Fabrics notification alerts sound',
                ),
                const SizedBox(height: 16),
                ...sounds.map((sound) {
                  final isSelected = sound == _currentNotifSound;
                  final label = sound == 'default'
                      ? 'Default Sound'
                      : 'Silent (No Sound)';
                  final icon = sound == 'default'
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded;

                  return ListTile(
                    onTap: () async {
                      await LocalNotificationService.instance
                          .setNotificationSound(sound);
                      setState(() => _currentNotifSound = sound);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    leading: Icon(
                      icon,
                      color: isSelected
                          ? sheetColors.brandPrimary
                          : sheetColors.textSecondary,
                    ),
                    title: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? sheetColors.brandPrimary
                            : sheetColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: sheetColors.brandPrimary,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: isSelected
                        ? sheetColors.brandPrimary.withOpacity(0.08)
                        : null,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Guest Content ──────────────────────────────────────────────────────────

  Widget _buildGuestContent(BuildContext context) {
    final colors          = context.appColors;
    final themeController = ThemeScope.of(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Guest Hero Card ────────────────────────────────
              AppSurfaceCard(
                padding:      const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    // ── Brand Logo Avatar — PF emblem ───────────
                    Container(
                      width:  96,
                      height: 96,
                      decoration: BoxDecoration(
                        color:  colors.brandPrimary.withOpacity(0.10),
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: colors.brandPrimary.withOpacity(0.28),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width:  62,
                          height: 62,
                          decoration: BoxDecoration(
                            // Deep black inner circle — matches logo
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF2A2A2A),
                                Color(0xFF0D0D0D),
                              ],
                              center: Alignment.topLeft,
                              radius: 1.5,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:      colors.brandPrimary
                                    .withOpacity(0.35),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'PF',
                              style: GoogleFonts.montserrat(
                                color:       colors.brandPrimary,
                                fontSize:    18,
                                fontWeight:  FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Brand Name ──────────────────────────────
                    Text(
                      'Welcome to Phlakes Fabrics',
                      style: GoogleFonts.poppins(
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                        color:      colors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── Brand Pill ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical:   4,
                      ),
                      decoration: BoxDecoration(
                        color:        colors.brandPrimary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.brandPrimary.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        'PHLAKES',
                        style: GoogleFonts.montserrat(
                          color:       colors.brandPrimary,
                          fontSize:    11,
                          fontWeight:  FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Browse products freely. Sign in to save favourites, '
                      'track orders, manage addresses, and enjoy the full '
                      'Phlakes Fabrics experience.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height:   1.6,
                        color:    colors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Sign In CTA — gold, black text ──────────
                    SizedBox(
                      width:  double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.brandPrimary,
                          // Black text on gold — Phlakes brand contrast
                          foregroundColor: AppPalette.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon:  const Icon(Icons.login_rounded),
                        label: Text(
                          'Sign In / Create Account',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Preferences ──────────────────────────────────
              _SectionHeader(title: 'Preferences'),
              const SizedBox(height: 8),
              _ProfileTile(
                icon:     Icons.dark_mode_rounded,
                title:    'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                trailing: Switch(
                  value:     themeController.isDarkMode,
                  onChanged: themeController.toggleDarkMode,
                ),
              ),
              _ProfileTile(
                icon:     Icons.notifications_outlined,
                title:    'Notification Sound',
                subtitle: 'Current: ${_currentNotifSound == 'default' ? 'Default Sound' : 'Silent'}',
                onTap:    _showNotificationSoundPicker,
              ),
              const SizedBox(height: 8),

              _SectionHeader(title: 'Account'),
              const SizedBox(height: 8),
              _ProfileTile(
                icon:     Icons.favorite_border_rounded,
                title:    'Favourites',
                subtitle: 'Sign in to save your favourite products',
                onTap:    _goToLogin,
              ),
              _ProfileTile(
                icon:     Icons.location_on_outlined,
                title:    'Saved Addresses',
                subtitle: 'Sign in to save delivery addresses',
                onTap:    _goToLogin,
              ),
              _ProfileTile(
                icon:     Icons.receipt_long_rounded,
                title:    'Orders',
                subtitle: 'Sign in to track your order history',
                onTap:    _goToLogin,
              ),
              const SizedBox(height: 8),

              _SectionHeader(title: 'Support'),
              const SizedBox(height: 8),
              _ProfileTile(
                icon:     Icons.support_agent_rounded,
                title:    'Help & Support',
                // ── Updated: Phlakes brand name ──────────────────
                subtitle: 'Chat with Phlakes Fabrics support on WhatsApp',
                onTap:    _openWhatsAppSupport,
              ),
              _ProfileTile(
                icon:     Icons.info_outline_rounded,
                title:    'About Phlakes Fabrics',
                subtitle: 'Learn more about Phlakes Fabrics',
                onTap:    _showAboutDialog,
              ),
              const SizedBox(height: 24),

              // ── Footer ───────────────────────────────────────
              Center(
                child: Text(
                  'Phlakes Fabrics · PFB · Version 1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color:    colors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Authenticated Content ──────────────────────────────────────────────────

  Widget _buildAuthenticatedContent(BuildContext context) {
    final colors          = context.appColors;
    final themeController = ThemeScope.of(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firebaseService.watchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile      = snapshot.data ?? {};
        final name         = (profile['displayName'] ?? '').toString();
        final displayName  = name.isNotEmpty ? name : 'Phlakes Member';
        final email        = (profile['email'] ?? '').toString();
        final displayEmail = email.isNotEmpty ? email : 'No email';
        final photoUrl     = (profile['photoUrl'] ?? '').toString();
        final favorites    = List<String>.from(profile['favorites'] ?? []);
        final cart         = List<Map<String, dynamic>>.from(
          profile['cart'] ?? [],
        );
        final addresses       = List<String>.from(profile['addresses'] ?? []);
        final selectedAddress =
            (profile['selectedAddress'] ?? '').toString();
        final initial = displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'P';

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Profile Header Card ──────────────────────
                  AppSurfaceCard(
                    padding:      const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        // Avatar — tappable, gold ring border
                        GestureDetector(
                          onTap: _uploadingPhoto
                              ? null
                              : _pickAndUploadProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.brandPrimary
                                        .withOpacity(0.45),
                                    width: 2.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius:          34,
                                  backgroundColor: colors.brandPrimary,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? Text(
                                          initial,
                                          style: GoogleFonts.montserrat(
                                            // Black initial on gold — brand contrast
                                            color:      AppPalette.secondary,
                                            fontWeight: FontWeight.w900,
                                            fontSize:   24,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              // Camera icon badge
                              Positioned(
                                bottom: 0,
                                right:  0,
                                child: Container(
                                  width:  24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colors.brandPrimary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.card,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size:  12,
                                    // Black icon on gold badge — brand contrast
                                    color: AppPalette.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tappable name + edit icon
                              GestureDetector(
                                onTap: _savingName
                                    ? null
                                    : () => _editDisplayName(displayName),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: GoogleFonts.poppins(
                                          fontSize:   18,
                                          fontWeight: FontWeight.w700,
                                          color:      colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: colors.brandPrimary
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size:  14,
                                        color: colors.brandPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Email row
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size:  13,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      displayEmail,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:    colors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // ── Member badge — Phlakes brand ───
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical:   3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.brandPrimary
                                      .withOpacity(0.10),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colors.brandPrimary
                                        .withOpacity(0.22),
                                  ),
                                ),
                                child: Text(
                                  'Phlakes Member',
                                  style: GoogleFonts.poppins(
                                    color:       colors.brandPrimary,
                                    fontSize:    10,
                                    fontWeight:  FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              // Upload progress
                              if (_uploadingPhoto)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width:  12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color:       colors.brandPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Uploading photo...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color:    colors.brandPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Name save progress
                              if (_savingName)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Saving name...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color:    colors.brandPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Metrics Row ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: AppMetricCard(
                          title: 'Favourites',
                          value: '${favorites.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Cart Items',
                          value: '${cart.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Addresses',
                          value: '${addresses.length}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Preferences ──────────────────────────────
                  _SectionHeader(title: 'Preferences'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon:     Icons.dark_mode_rounded,
                    title:    'Dark Mode',
                    subtitle: 'Switch between light and dark theme',
                    trailing: Switch(
                      value:     themeController.isDarkMode,
                      onChanged: themeController.toggleDarkMode,
                    ),
                  ),
                  _ProfileTile(
                    icon:     Icons.notifications_outlined,
                    title:    'Notification Sound',
                    subtitle: 'Current: ${_currentNotifSound == 'default' ? 'Default Sound' : 'Silent'}',
                    onTap:    _showNotificationSoundPicker,
                  ),
                  const SizedBox(height: 8),

                  // ── Delivery Addresses ───────────────────────
                  _SectionHeader(title: 'Delivery Addresses'),
                  const SizedBox(height: 8),

                  AppSurfaceCard(
                    margin:       const EdgeInsets.only(bottom: 12),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected address banner
                        Container(
                          width:   double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical:   10,
                          ),
                          decoration: BoxDecoration(
                            color: selectedAddress.isEmpty
                                ? colors.error.withOpacity(0.08)
                                : colors.brandPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedAddress.isEmpty
                                  ? colors.error.withOpacity(0.25)
                                  : colors.brandPrimary.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedAddress.isEmpty
                                    ? Icons.location_off_outlined
                                    : Icons.check_circle_rounded,
                                color: selectedAddress.isEmpty
                                    ? colors.error
                                    : colors.brandPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedAddress.isEmpty
                                      ? 'No delivery address selected'
                                      : selectedAddress,
                                  style: GoogleFonts.poppins(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w600,
                                    color: selectedAddress.isEmpty
                                        ? colors.error
                                        : colors.brandPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Add new address row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AddressAutocompleteField(
                                controller: _addressCtrl,
                                onSuggestionSelected: (suggestion) {
                                  _selectedAddressSuggestion = suggestion;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _addAddress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.brandPrimary,
                                  // Black icon on gold — brand contrast
                                  foregroundColor: AppPalette.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Existing addresses list
                        if (addresses.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ...addresses.map((address) {
                            final isSelected = selectedAddress == address;

                            return Container(
                              margin:  const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical:   10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.brandPrimary.withOpacity(0.06)
                                    : colors.surfaceAlt,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.brandPrimary.withOpacity(0.35)
                                      : colors.borderSoft,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.place_outlined,
                                    size:  18,
                                    color: isSelected
                                        ? colors.brandPrimary
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: GoogleFonts.poppins(
                                        fontSize:   12.5,
                                        color:      colors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (!isSelected)
                                    TextButton(
                                      onPressed: () =>
                                          _selectAddress(address),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 10,
                                          vertical:   4,
                                        ),
                                      ),
                                      child: Text(
                                        'Use',
                                        style: GoogleFonts.poppins(
                                          color:      colors.brandPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize:   12,
                                        ),
                                      ),
                                    ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 4,
                                      ),
                                      child: Text(
                                        'Active',
                                        style: GoogleFonts.poppins(
                                          color:      colors.brandPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize:   11,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () =>
                                        _removeAddress(address),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size:  18,
                                      color: colors.error,
                                    ),
                                    padding:     EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth:  32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ] else ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  color: colors.textSecondary
                                      .withOpacity(0.5),
                                  size: 32,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No saved addresses yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colors.textSecondary
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── My Account ───────────────────────────────
                  _SectionHeader(title: 'My Account'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon:     Icons.favorite_border_rounded,
                    title:    'Favourites',
                    subtitle: 'View all your favourite products',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileTile(
                    icon:     Icons.cleaning_services_rounded,
                    title:    'Clean Old Notifications',
                    subtitle: 'Delete notifications older than 30 days',
                    onTap: () async {
                      final count = await _firebaseService
                          .cleanupOldNotifications(days: 30);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Deleted $count old notification'
                            '${count == 1 ? '' : 's'}',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Support ──────────────────────────────────
                  _SectionHeader(title: 'Support'),
                  const SizedBox(height: 8),
                  _ProfileTile(
                    icon:     Icons.support_agent_rounded,
                    title:    'Help & Support',
                    subtitle: 'Chat with Phlakes Fabrics support on WhatsApp',
                    onTap:    _openWhatsAppSupport,
                  ),
                  _ProfileTile(
                    icon:     Icons.info_outline_rounded,
                    title:    'About Phlakes Fabrics',
                    subtitle: 'Learn more about Phlakes Fabrics',
                    onTap:    _showAboutDialog,
                  ),
                  const SizedBox(height: 20),

                  // ── Logout ───────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _loggingOut ? null : _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.error.withOpacity(0.10),
                        foregroundColor: colors.error,
                        elevation:       0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colors.error.withOpacity(0.25),
                          ),
                        ),
                      ),
                      icon: _loggingOut
                          ? SizedBox(
                              width:  18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       colors.error,
                              ),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        _loggingOut ? 'Logging out...' : 'Log Out',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ───────────────────────────────────
                  Center(
                    child: Text(
                      'Phlakes Fabrics · PFB · Version 1.0.0',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color:    colors.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_isGuest) {
      final guestContent = _buildGuestContent(context);

      if (!widget.showScaffold) {
        return Scaffold(
          backgroundColor: colors.scaffold,
          body: SafeArea(child: guestContent),
        );
      }

      return AppPageScaffold(
        title: 'Profile',
        body:  guestContent,
      );
    }

    final content = _buildAuthenticatedContent(context);

    if (!widget.showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return AppPageScaffold(
      title: 'Profile',
      body:  content,
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        // Gold left accent bar — brand signature
        Container(
          width:  4,
          height: 16,
          decoration: BoxDecoration(
            color:        colors.brandPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize:      13,
            fontWeight:    FontWeight.w700,
            color:         colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Profile Tile ───────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData  icon;
  final String    title;
  final String    subtitle;
  final Widget?   trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: Container(
        width:  42,
        height: 42,
        decoration: BoxDecoration(
          color:        colors.brandPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.brandPrimary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color:      colors.textPrimary,
          fontSize:   14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          color:    colors.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textSecondary,
          ),
      onTap: onTap,
    );
  }
}
