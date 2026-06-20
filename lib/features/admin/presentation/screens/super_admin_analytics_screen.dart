import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/admin/presentation/widgets/analytics_bar_chart_card.dart';
import 'package:pfb/features/admin/presentation/widgets/comparison_duel_card.dart';
import 'package:pfb/features/admin/presentation/widgets/performance_status_card.dart';
import 'package:pfb/features/admin/presentation/widgets/top_rank_card.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/models/ride_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

enum AnalyticsRange { today, week, month, all, custom }

class SuperAdminAnalyticsScreen extends StatefulWidget {
  const SuperAdminAnalyticsScreen({super.key});

  @override
  State<SuperAdminAnalyticsScreen> createState() =>
      _SuperAdminAnalyticsScreenState();
}

class _SuperAdminAnalyticsScreenState
    extends State<SuperAdminAnalyticsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  AnalyticsRange _range       = AnalyticsRange.all;
  DateTimeRange? _customRange;

  String _selectedState = 'All';
  String _selectedAdmin = 'All';
  String _selectedArea  = 'All';

  // ── Date helpers ─────────────────────────────────────────────────

  DateTime _rangeStart() {
    final now = DateTime.now();
    switch (_range) {
      case AnalyticsRange.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsRange.week:
        return now.subtract(const Duration(days: 7));
      case AnalyticsRange.month:
        return now.subtract(const Duration(days: 30));
      case AnalyticsRange.custom:
        return _customRange?.start ?? DateTime(2000);
      case AnalyticsRange.all:
        return DateTime(2000);
    }
  }

  DateTime _rangeEnd() {
    if (_range == AnalyticsRange.custom && _customRange != null) {
      return DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
        23, 59, 59,
      );
    }
    return DateTime.now();
  }

  bool _inRange(DateTime date) {
    final start = _rangeStart();
    final end   = _rangeEnd();
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  bool _matchesOrderFilters(OrderModel order) {
    if (!_inRange(order.createdAt)) return false;
    if (_selectedState != 'All' &&
        order.assignedAdminState != _selectedState) return false;
    if (_selectedAdmin != 'All' &&
        order.assignedAdminName != _selectedAdmin) return false;
    if (_selectedArea != 'All' &&
        order.assignedAdminArea != _selectedArea) return false;
    return true;
  }

  bool _matchesRideFilters(RideModel ride) {
    if (!_inRange(ride.createdAt)) return false;
    if (_selectedState != 'All' &&
        (ride.assignedAdminState ?? '') != _selectedState) return false;
    if (_selectedAdmin != 'All' &&
        (ride.assignedAdminName ?? '') != _selectedAdmin) return false;
    if (_selectedArea != 'All' &&
        (ride.assignedAdminArea ?? '') != _selectedArea) return false;
    return true;
  }

  // ── Aggregation helpers ──────────────────────────────────────────

  Map<String, double> _sumOrderTotalsByField(
    List<OrderModel> orders,
    String Function(OrderModel) keyBuilder,
  ) {
    final map = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      final key = keyBuilder(order).trim();
      if (key.isEmpty) continue;
      map[key] = (map[key] ?? 0) + order.totalAmount;
    }
    return map;
  }

  Map<String, int> _countOrdersByField(
    List<OrderModel> orders,
    String Function(OrderModel) keyBuilder,
  ) {
    final map = <String, int>{};
    for (final order in orders) {
      final key = keyBuilder(order).trim();
      if (key.isEmpty) continue;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> _countRidesByField(
    List<RideModel> rides,
    String Function(RideModel) keyBuilder,
  ) {
    final map = <String, int>{};
    for (final ride in rides) {
      final key = keyBuilder(ride).trim();
      if (key.isEmpty) continue;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, double> _dailySalesSeries(List<OrderModel> orders) {
    final series = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      final key =
          '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';
      series[key] = (series[key] ?? 0) + order.totalAmount;
    }
    return series;
  }

  Map<String, int> _dailyOrderSeries(List<OrderModel> orders) {
    final series = <String, int>{};
    for (final order in orders) {
      final key =
          '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';
      series[key] = (series[key] ?? 0) + 1;
    }
    return series;
  }

  Map<String, int> _dailyRideSeries(List<RideModel> rides) {
    final series = <String, int>{};
    for (final ride in rides) {
      final key =
          '${ride.createdAt.day}/${ride.createdAt.month}/${ride.createdAt.year}';
      series[key] = (series[key] ?? 0) + 1;
    }
    return series;
  }

  Future<void> _pickCustomRange() async {
    final result = await showDateRangePicker(
      context:     context,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) {
        // Gold-themed date picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary:   AppPalette.primary,
              onPrimary: AppPalette.secondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (result == null) return;
    setState(() {
      _customRange = result;
      _range       = AnalyticsRange.custom;
    });
  }

  String get _rangeLabel {
    switch (_range) {
      case AnalyticsRange.today:
        return 'Today';
      case AnalyticsRange.week:
        return 'Last 7 Days';
      case AnalyticsRange.month:
        return 'Last 30 Days';
      case AnalyticsRange.custom:
        if (_customRange == null) return 'Custom Range';
        return '${_customRange!.start.day}/${_customRange!.start.month}/'
            '${_customRange!.start.year} — '
            '${_customRange!.end.day}/${_customRange!.end.month}/'
            '${_customRange!.end.year}';
      case AnalyticsRange.all:
        return 'All Time';
    }
  }

  // ── Filter Dropdown ──────────────────────────────────────────────

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = context.appColors;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.brandPrimary.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value:            value,
            dropdownColor:    colors.surfaceAlt,
            style:            GoogleFonts.poppins(
              color:    colors.textPrimary,
              fontSize: 12,
            ),
            iconEnabledColor: colors.brandPrimary,
            isExpanded:       true,
            hint: Text(
              label,
              style: GoogleFonts.poppins(color: colors.textSecondary),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors      = context.appColors;
    final isDark      = context.isDarkMode;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
      _firebaseService.currentUser?.uid,
    );

    return AppPageScaffold(
      title: 'Analytics Dashboard',
      body: !isSuperAdmin
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width:  80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.brandPrimary.withOpacity(0.08),
                      border: Border.all(
                        color: colors.brandPrimary.withOpacity(0.20),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: colors.brandPrimary,
                      size:  36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Restricted',
                    style: GoogleFonts.poppins(
                      color:      colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize:   18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Only super admins can view analytics',
                    style: GoogleFonts.poppins(
                      color:    colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<OrderModel>>(
              stream: _firebaseService.watchAllOrders(),
              builder: (context, orderSnapshot) {
                final orders = orderSnapshot.data ?? [];

                return StreamBuilder<List<RideModel>>(
                  stream: _firebaseService.watchAllRides(),
                  builder: (context, rideSnapshot) {
                    final rides = rideSnapshot.data ?? [];

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firebaseService.watchAdmins(),
                      builder: (context, adminSnapshot) {
                        final admins = adminSnapshot.data ?? [];

                        // ── Build filter option lists ────────────────
                        final availableStates = {
                          'All',
                          ...orders
                              .map((e) => e.assignedAdminState)
                              .where((e) => e.trim().isNotEmpty),
                          ...rides
                              .map((e) => e.assignedAdminState ?? '')
                              .where((e) => e.trim().isNotEmpty),
                        }.toList()..sort();

                        final availableAdmins = {
                          'All',
                          ...orders
                              .map((e) => e.assignedAdminName)
                              .where((e) => e.trim().isNotEmpty),
                          ...rides
                              .map((e) => e.assignedAdminName ?? '')
                              .where((e) => e.trim().isNotEmpty),
                        }.toList()..sort();

                        final availableAreas = {
                          'All',
                          ...orders
                              .map((e) => e.assignedAdminArea)
                              .where((e) => e.trim().isNotEmpty),
                          ...rides
                              .map((e) => e.assignedAdminArea ?? '')
                              .where((e) => e.trim().isNotEmpty),
                        }.toList()..sort();

                        if (!availableStates.contains(_selectedState)) {
                          _selectedState = 'All';
                        }
                        if (!availableAdmins.contains(_selectedAdmin)) {
                          _selectedAdmin = 'All';
                        }
                        if (!availableAreas.contains(_selectedArea)) {
                          _selectedArea = 'All';
                        }

                        // ── Apply filters ────────────────────────────
                        final filteredOrders =
                            orders.where(_matchesOrderFilters).toList();
                        final filteredRides =
                            rides.where(_matchesRideFilters).toList();

                        final deliveredOrders = filteredOrders
                            .where((e) => e.status == 'delivered')
                            .toList();
                        final cancelledOrders = filteredOrders
                            .where((e) => e.status == 'cancelled')
                            .toList();
                        final completedRides = filteredRides
                            .where((e) => e.status == 'completed')
                            .toList();
                        final cancelledRides = filteredRides
                            .where((e) => e.status == 'cancelled')
                            .toList();

                        // ── Summary metrics ──────────────────────────
                        final totalSales = deliveredOrders.fold<double>(
                          0, (sum, item) => sum + item.totalAmount,
                        );
                        final totalOrders     = filteredOrders.length;
                        final totalRides      = filteredRides
                            .where((e) => e.type == 'ride').length;
                        final totalDeliveries = filteredRides
                            .where((e) => e.type == 'delivery').length;
                        final totalEscalations =
                            filteredOrders
                                .where((e) => e.escalatedToSuperAdmin)
                                .length +
                            filteredRides
                                .where((e) => e.escalatedToSuperAdmin)
                                .length;
                        final totalReassignments =
                            filteredOrders
                                .where((e) =>
                                    e.assignmentMethod ==
                                    'manual_reassignment')
                                .length +
                            filteredRides
                                .where((e) =>
                                    e.assignmentMethod ==
                                    'manual_reassignment')
                                .length;

                        // ── Rates ────────────────────────────────────
                        final orderCompletionRate   = totalOrders == 0
                            ? 0.0
                            : (deliveredOrders.length / totalOrders) * 100;
                        final orderCancellationRate = totalOrders == 0
                            ? 0.0
                            : (cancelledOrders.length / totalOrders) * 100;
                        final rideCompletionRate    = filteredRides.isEmpty
                            ? 0.0
                            : (completedRides.length /
                                    filteredRides.length) *
                                100;
                        final rideCancellationRate  = filteredRides.isEmpty
                            ? 0.0
                            : (cancelledRides.length /
                                    filteredRides.length) *
                                100;

                        // ── Breakdowns ───────────────────────────────
                        final salesByAdmin = _sumOrderTotalsByField(
                          filteredOrders,
                          (o) => o.assignedAdminName,
                        );
                        final salesByState = _sumOrderTotalsByField(
                          filteredOrders,
                          (o) => o.assignedAdminState,
                        );
                        final salesByArea = _sumOrderTotalsByField(
                          filteredOrders,
                          (o) => o.assignedAdminArea,
                        );
                        final ordersByAdmin = _countOrdersByField(
                          filteredOrders,
                          (o) => o.assignedAdminName,
                        );
                        final ridesByAdmin = _countRidesByField(
                          filteredRides
                              .where((e) => e.type == 'ride')
                              .toList(),
                          (r) => r.assignedAdminName ?? '',
                        );
                        final deliveriesByAdmin = _countRidesByField(
                          filteredRides
                              .where((e) => e.type == 'delivery')
                              .toList(),
                          (r) => r.assignedAdminName ?? '',
                        );
                        final reassignmentsByAdmin = _countOrdersByField(
                          filteredOrders
                              .where((e) =>
                                  e.assignmentMethod ==
                                  'manual_reassignment')
                              .toList(),
                          (o) => o.assignedAdminName,
                        );

                        // ── Time series ──────────────────────────────
                        final salesSeries =
                            _dailySalesSeries(filteredOrders);
                        final orderSeries =
                            _dailyOrderSeries(filteredOrders);
                        final rideSeries  =
                            _dailyRideSeries(filteredRides);

                        // ── Top / worst performers ───────────────────
                        final sortedAdminSales =
                            salesByAdmin.entries.toList()
                              ..sort(
                                  (a, b) => b.value.compareTo(a.value));
                        final sortedStateSales =
                            salesByState.entries.toList()
                              ..sort(
                                  (a, b) => b.value.compareTo(a.value));
                        final sortedAreaSales =
                            salesByArea.entries.toList()
                              ..sort(
                                  (a, b) => b.value.compareTo(a.value));

                        final topAdminEntry   = sortedAdminSales.isEmpty
                            ? null
                            : sortedAdminSales.first;
                        final worstAdminEntry = sortedAdminSales.isEmpty
                            ? null
                            : sortedAdminSales.last;
                        final topStateEntry   = sortedStateSales.isEmpty
                            ? null
                            : sortedStateSales.first;
                        final worstStateEntry = sortedStateSales.isEmpty
                            ? null
                            : sortedStateSales.last;
                        final topAreaEntry    = sortedAreaSales.isEmpty
                            ? null
                            : sortedAreaSales.first;
                        final worstAreaEntry  = sortedAreaSales.isEmpty
                            ? null
                            : sortedAreaSales.last;

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [

                            // ── Phlakes Analytics Header ─────────────
                            Container(
                              margin:  const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                // Luxury black → gold gradient header
                                gradient: LinearGradient(
                                  colors: [
                                    AppPalette.secondary,
                                    const Color(0xFF1A1A0A),
                                    AppPalette.primaryDark,
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                  begin: Alignment.centerLeft,
                                  end:   Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:      AppPalette.primary
                                        .withOpacity(0.20),
                                    blurRadius: 16,
                                    offset:     const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width:  50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppPalette.primary
                                            .withOpacity(0.50),
                                        width: 2,
                                      ),
                                      color: Colors.white
                                          .withOpacity(0.08),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'PF',
                                        style: GoogleFonts.montserrat(
                                          color:       AppPalette.primary,
                                          fontSize:    16,
                                          fontWeight:  FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PHLAKES FABRICS',
                                          style: GoogleFonts.montserrat(
                                            color:       AppPalette.primary,
                                            fontWeight:  FontWeight.w900,
                                            fontSize:    14,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Super Admin Analytics',
                                          style: GoogleFonts.poppins(
                                            color:    Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Range label pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical:   5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppPalette.primary
                                          .withOpacity(0.18),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppPalette.primary
                                            .withOpacity(0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _rangeLabel,
                                      style: GoogleFonts.poppins(
                                        color:      AppPalette.primary,
                                        fontSize:   10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Filter Card ──────────────────────────
                            AppSurfaceCard(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Section header
                                  Row(
                                    children: [
                                      Container(
                                        width:  3.5,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppPalette.primaryDark,
                                              AppPalette.primaryLight,
                                            ],
                                            begin: Alignment.topCenter,
                                            end:   Alignment.bottomCenter,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Filters & Date Range',
                                        style: GoogleFonts.poppins(
                                          color:      colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize:   14,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // Range selector row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _rangeLabel,
                                          style: GoogleFonts.poppins(
                                            color:      colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize:   13,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.brandPrimary
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: colors.brandPrimary
                                                .withOpacity(0.20),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<
                                              AnalyticsRange>(
                                            value:         _range,
                                            dropdownColor: colors.surfaceAlt,
                                            style: GoogleFonts.poppins(
                                              color:    colors.textPrimary,
                                              fontSize: 13,
                                            ),
                                            iconEnabledColor:
                                                colors.brandPrimary,
                                            items: const [
                                              DropdownMenuItem(
                                                value: AnalyticsRange.today,
                                                child: Text('Today'),
                                              ),
                                              DropdownMenuItem(
                                                value: AnalyticsRange.week,
                                                child: Text('7 Days'),
                                              ),
                                              DropdownMenuItem(
                                                value: AnalyticsRange.month,
                                                child: Text('30 Days'),
                                              ),
                                              DropdownMenuItem(
                                                value: AnalyticsRange.all,
                                                child: Text('All Time'),
                                              ),
                                              DropdownMenuItem(
                                                value:
                                                    AnalyticsRange.custom,
                                                child: Text('Custom'),
                                              ),
                                            ],
                                            onChanged: (value) async {
                                              if (value == null) return;
                                              if (value ==
                                                  AnalyticsRange.custom) {
                                                await _pickCustomRange();
                                                return;
                                              }
                                              setState(
                                                  () => _range = value);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_range == AnalyticsRange.custom) ...[
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: _pickCustomRange,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            colors.brandPrimary,
                                        side: BorderSide(
                                          color: colors.brandPrimary
                                              .withOpacity(0.40),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.date_range_rounded),
                                      label: Text(
                                        'Change Custom Range',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 14),

                                  // Filter dropdowns
                                  Row(
                                    children: [
                                      _filterDropdown(
                                        label:    'State',
                                        value:    _selectedState,
                                        items:    availableStates,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(
                                              () => _selectedState = v);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      _filterDropdown(
                                        label:    'Admin',
                                        value:    _selectedAdmin,
                                        items:    availableAdmins,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(
                                              () => _selectedAdmin = v);
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      _filterDropdown(
                                        label:    'Area',
                                        value:    _selectedArea,
                                        items:    availableAreas,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(
                                              () => _selectedArea = v);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedState = 'All';
                                              _selectedAdmin = 'All';
                                              _selectedArea  = 'All';
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                colors.brandPrimary,
                                            side: BorderSide(
                                              color: colors.brandPrimary
                                                  .withOpacity(0.35),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                            ),
                                          ),
                                          child: Text(
                                            'Clear Filters',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ── Metric Cards ─────────────────────────
                            _SectionHeader(
                              title:  'Key Metrics',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Total Sales',
                                    value:
                                        '₦${totalSales.toStringAsFixed(0)}',
                                    icon:  Icons.payments_rounded,
                                    isPrimary: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Delivered',
                                    value: '${deliveredOrders.length}',
                                    icon:  Icons.check_circle_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    title: 'All Orders',
                                    value: '$totalOrders',
                                    icon:  Icons.receipt_long_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Admins',
                                    value:
                                        '${admins.length + AppConstants.superAdminUids.length}',
                                    icon:
                                        Icons.admin_panel_settings_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Rides',
                                    value: '$totalRides',
                                    icon:  Icons.local_taxi_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Deliveries',
                                    value: '$totalDeliveries',
                                    icon:  Icons.delivery_dining_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Escalations',
                                    value: '$totalEscalations',
                                    icon:  Icons.warning_amber_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Reassignments',
                                    value: '$totalReassignments',
                                    icon:  Icons.swap_horiz_rounded,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // ── Performance Health ───────────────────
                            _SectionHeader(
                              title:  'Performance Health',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title:       'Order Completion',
                                    value:
                                        '${orderCompletionRate.toStringAsFixed(1)}%',
                                    subtitle:    'Delivered / total orders',
                                    accentColor: colors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title:       'Order Cancellation',
                                    value:
                                        '${orderCancellationRate.toStringAsFixed(1)}%',
                                    subtitle:    'Cancelled / total orders',
                                    accentColor: colors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title:       'Ride Completion',
                                    value:
                                        '${rideCompletionRate.toStringAsFixed(1)}%',
                                    subtitle:    'Completed / total rides',
                                    accentColor: colors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title:       'Ride Cancellation',
                                    value:
                                        '${rideCancellationRate.toStringAsFixed(1)}%',
                                    subtitle:    'Cancelled / total rides',
                                    accentColor: colors.warning,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // ── Top Performers ───────────────────────
                            _SectionHeader(
                              title:  'Top Performers',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: TopRankCard(
                                    title: 'Top Admin',
                                    name:  topAdminEntry?.key ?? 'N/A',
                                    value: topAdminEntry == null
                                        ? '₦0'
                                        : '₦${topAdminEntry.value.toStringAsFixed(0)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TopRankCard(
                                    title: 'Top State',
                                    name:  topStateEntry?.key ?? 'N/A',
                                    value: topStateEntry == null
                                        ? '₦0'
                                        : '₦${topStateEntry.value.toStringAsFixed(0)}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TopRankCard(
                                    title: 'Top Area',
                                    name:  topAreaEntry?.key ?? 'N/A',
                                    value: topAreaEntry == null
                                        ? '₦0'
                                        : '₦${topAreaEntry.value.toStringAsFixed(0)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(child: SizedBox()),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // ── Comparison Duels ─────────────────────
                            _SectionHeader(
                              title:  'Best vs Needs Attention',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),

                            ComparisonDuelCard(
                              title:      'Admin Sales',
                              bestLabel:  topAdminEntry?.key ?? 'N/A',
                              bestValue:  topAdminEntry == null
                                  ? '₦0'
                                  : '₦${topAdminEntry.value.toStringAsFixed(0)}',
                              worstLabel: worstAdminEntry?.key ?? 'N/A',
                              worstValue: worstAdminEntry == null
                                  ? '₦0'
                                  : '₦${worstAdminEntry.value.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 12),
                            ComparisonDuelCard(
                              title:      'State Sales',
                              bestLabel:  topStateEntry?.key ?? 'N/A',
                              bestValue:  topStateEntry == null
                                  ? '₦0'
                                  : '₦${topStateEntry.value.toStringAsFixed(0)}',
                              worstLabel: worstStateEntry?.key ?? 'N/A',
                              worstValue: worstStateEntry == null
                                  ? '₦0'
                                  : '₦${worstStateEntry.value.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 12),
                            ComparisonDuelCard(
                              title:      'Area Sales',
                              bestLabel:  topAreaEntry?.key ?? 'N/A',
                              bestValue:  topAreaEntry == null
                                  ? '₦0'
                                  : '₦${topAreaEntry.value.toStringAsFixed(0)}',
                              worstLabel: worstAreaEntry?.key ?? 'N/A',
                              worstValue: worstAreaEntry == null
                                  ? '₦0'
                                  : '₦${worstAreaEntry.value.toStringAsFixed(0)}',
                            ),

                            const SizedBox(height: 22),

                            // ── Charts ───────────────────────────────
                            _SectionHeader(
                              title:  'Sales Trend',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Daily Sales',
                              data:       salesSeries,
                              isCurrency: true,
                              emptyLabel: 'No sales trend data yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Order Trend',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Daily Orders',
                              data:       orderSeries,
                              isCurrency: false,
                              emptyLabel: 'No order trend data yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Ride & Delivery Trend',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Daily Movement',
                              data:       rideSeries,
                              isCurrency: false,
                              emptyLabel: 'No ride trend data yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Sales by Admin',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Admin Sales',
                              data:       salesByAdmin,
                              isCurrency: true,
                              emptyLabel: 'No sales data yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Sales by State',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'State Sales',
                              data:       salesByState,
                              isCurrency: true,
                              emptyLabel: 'No state sales data yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Sales by Area',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Area Sales',
                              data:       salesByArea,
                              isCurrency: true,
                              emptyLabel: 'No area sales data yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Orders by Admin',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Admin Order Count',
                              data:       ordersByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No admin order activity yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Rides by Admin',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Admin Ride Count',
                              data:       ridesByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No ride activity yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Deliveries by Admin',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Admin Delivery Count',
                              data:       deliveriesByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No delivery activity yet',
                            ),

                            const SizedBox(height: 22),
                            _SectionHeader(
                              title:  'Reassignments by Admin',
                              colors: colors,
                            ),
                            const SizedBox(height: 10),
                            AnalyticsBarChartCard(
                              title:      'Reassignment Count',
                              data:       reassignmentsByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No reassignment records yet',
                            ),

                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header with gold accent bar
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppThemeColors colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  3.5,
          height: 20,
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
        AppSectionTitle(
          title:         title,
          spacingBottom: 0,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric Card — Gold value, luxury feel
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isPrimary;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Primary metric card gets a premium black→gold gradient
        gradient: isPrimary
            ? const LinearGradient(
                colors: [
                  AppPalette.secondary,
                  Color(0xFF1A1A0A),
                  AppPalette.primaryDark,
                ],
                begin: Alignment.centerLeft,
                end:   Alignment.centerRight,
              )
            : null,
        color: isPrimary ? null : colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? AppPalette.primary.withOpacity(0.35)
              : colors.borderSoft,
          width: isPrimary ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppPalette.primary.withOpacity(0.18)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        isPrimary
                  ? Colors.white.withOpacity(0.12)
                  : AppPalette.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPrimary
                    ? AppPalette.primary.withOpacity(0.30)
                    : AppPalette.primary.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppPalette.primary,
              size:  18,
            ),
          ),
          const SizedBox(height: 12),
          // Value — gold color
          Text(
            value,
            style: GoogleFonts.poppins(
              color:      AppPalette.primary,
              fontWeight: FontWeight.w800,
              fontSize:   isPrimary ? 18 : 20,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            title,
            style: GoogleFonts.poppins(
              color: isPrimary
                  ? Colors.white70
                  : colors.textSecondary,
              fontSize:   11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
