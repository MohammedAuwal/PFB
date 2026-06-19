import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
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

enum AnalyticsRange {
  today,
  week,
  month,
  all,
  custom,
}

class SuperAdminAnalyticsScreen extends StatefulWidget {
  const SuperAdminAnalyticsScreen({super.key});

  @override
  State<SuperAdminAnalyticsScreen> createState() =>
      _SuperAdminAnalyticsScreenState();
}

class _SuperAdminAnalyticsScreenState extends State<SuperAdminAnalyticsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  AnalyticsRange _range = AnalyticsRange.all;
  DateTimeRange? _customRange;

  String _selectedState = 'All';
  String _selectedAdmin = 'All';
  String _selectedArea = 'All';

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
        23,
        59,
        59,
      );
    }
    return DateTime.now();
  }

  bool _inRange(DateTime date) {
    final start = _rangeStart();
    final end = _rangeEnd();
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  bool _matchesOrderFilters(OrderModel order) {
    if (!_inRange(order.createdAt)) return false;
    if (_selectedState != 'All' && order.assignedAdminState != _selectedState) {
      return false;
    }
    if (_selectedAdmin != 'All' && order.assignedAdminName != _selectedAdmin) {
      return false;
    }
    if (_selectedArea != 'All' && order.assignedAdminArea != _selectedArea) {
      return false;
    }
    return true;
  }

  bool _matchesRideFilters(RideModel ride) {
    if (!_inRange(ride.createdAt)) return false;
    if (_selectedState != 'All' &&
        (ride.assignedAdminState ?? '') != _selectedState) {
      return false;
    }
    if (_selectedAdmin != 'All' &&
        (ride.assignedAdminName ?? '') != _selectedAdmin) {
      return false;
    }
    if (_selectedArea != 'All' &&
        (ride.assignedAdminArea ?? '') != _selectedArea) {
      return false;
    }
    return true;
  }

  Map<String, double> _sumOrderTotalsByField(
    List<OrderModel> orders,
    String Function(OrderModel order) keyBuilder,
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
    String Function(OrderModel order) keyBuilder,
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
    String Function(RideModel ride) keyBuilder,
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
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange,
    );

    if (result == null) return;

    setState(() {
      _customRange = result;
      _range = AnalyticsRange.custom;
    });
  }

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
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSoft),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: colors.surfaceAlt,
            style: GoogleFonts.poppins(color: colors.textPrimary, fontSize: 12),
            iconEnabledColor: colors.iconPrimary,
            isExpanded: true,
            hint: Text(label, style: GoogleFonts.poppins(color: colors.textSecondary)),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
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
        return '${_customRange!.start.day}/${_customRange!.start.month}/${_customRange!.start.year} - ${_customRange!.end.day}/${_customRange!.end.month}/${_customRange!.end.year}';
      case AnalyticsRange.all:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
      _firebaseService.currentUser?.uid,
    );

    return AppPageScaffold(
      title: 'Super Admin Analytics',
      body: !isSuperAdmin
          ? Center(
              child: Text(
                'Only super admin can view analytics',
                style: GoogleFonts.poppins(color: colors.textSecondary),
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

                        final availableStates = {
                          'All',
                          ...orders
                              .map((e) => e.assignedAdminState)
                              .where((e) => e.trim().isNotEmpty),
                          ...rides
                              .map((e) => e.assignedAdminState ?? '')
                              .where((e) => e.trim().isNotEmpty),
                        }.toList()
                          ..sort();

                        final availableAdmins = {
                          'All',
                          ...orders
                              .map((e) => e.assignedAdminName)
                              .where((e) => e.trim().isNotEmpty),
                          ...rides
                              .map((e) => e.assignedAdminName ?? '')
                              .where((e) => e.trim().isNotEmpty),
                        }.toList()
                          ..sort();

                        final availableAreas = {
                          'All',
                          ...orders
                              .map((e) => e.assignedAdminArea)
                              .where((e) => e.trim().isNotEmpty),
                          ...rides
                              .map((e) => e.assignedAdminArea ?? '')
                              .where((e) => e.trim().isNotEmpty),
                        }.toList()
                          ..sort();

                        if (!availableStates.contains(_selectedState)) {
                          _selectedState = 'All';
                        }
                        if (!availableAdmins.contains(_selectedAdmin)) {
                          _selectedAdmin = 'All';
                        }
                        if (!availableAreas.contains(_selectedArea)) {
                          _selectedArea = 'All';
                        }

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

                        final totalSales = deliveredOrders.fold<double>(
                          0,
                          (sum, item) => sum + item.totalAmount,
                        );
                        final totalOrders = filteredOrders.length;
                        final totalRides =
                            filteredRides.where((e) => e.type == 'ride').length;
                        final totalDeliveries = filteredRides
                            .where((e) => e.type == 'delivery')
                            .length;
                        final totalEscalations = filteredOrders
                                .where((e) => e.escalatedToSuperAdmin)
                                .length +
                            filteredRides
                                .where((e) => e.escalatedToSuperAdmin)
                                .length;

                        final totalReassignments = filteredOrders
                                .where((e) =>
                                    e.assignmentMethod == 'manual_reassignment')
                                .length +
                            filteredRides
                                .where((e) =>
                                    e.assignmentMethod == 'manual_reassignment')
                                .length;

                        final orderCompletionRate = totalOrders == 0
                            ? 0
                            : (deliveredOrders.length / totalOrders) * 100;

                        final orderCancellationRate = totalOrders == 0
                            ? 0
                            : (cancelledOrders.length / totalOrders) * 100;

                        final rideCompletionRate = filteredRides.isEmpty
                            ? 0
                            : (completedRides.length / filteredRides.length) * 100;

                        final rideCancellationRate = filteredRides.isEmpty
                            ? 0
                            : (cancelledRides.length / filteredRides.length) * 100;

                        final salesByAdmin = _sumOrderTotalsByField(
                          filteredOrders,
                          (order) => order.assignedAdminName,
                        );

                        final salesByState = _sumOrderTotalsByField(
                          filteredOrders,
                          (order) => order.assignedAdminState,
                        );

                        final salesByArea = _sumOrderTotalsByField(
                          filteredOrders,
                          (order) => order.assignedAdminArea,
                        );

                        final ordersByAdmin = _countOrdersByField(
                          filteredOrders,
                          (order) => order.assignedAdminName,
                        );

                        final ridesByAdmin = _countRidesByField(
                          filteredRides.where((e) => e.type == 'ride').toList(),
                          (ride) => ride.assignedAdminName ?? '',
                        );

                        final deliveriesByAdmin = _countRidesByField(
                          filteredRides
                              .where((e) => e.type == 'delivery')
                              .toList(),
                          (ride) => ride.assignedAdminName ?? '',
                        );

                        final reassignmentsByAdmin = _countOrdersByField(
                          filteredOrders
                              .where((e) =>
                                  e.assignmentMethod == 'manual_reassignment')
                              .toList(),
                          (order) => order.assignedAdminName,
                        );

                        final salesSeries = _dailySalesSeries(filteredOrders);
                        final orderSeries = _dailyOrderSeries(filteredOrders);
                        final rideSeries = _dailyRideSeries(filteredRides);

                        final sortedAdminSales = salesByAdmin.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        final sortedStateSales = salesByState.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        final sortedAreaSales = salesByArea.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                        final topAdminEntry =
                            sortedAdminSales.isEmpty ? null : sortedAdminSales.first;
                        final worstAdminEntry =
                            sortedAdminSales.isEmpty ? null : sortedAdminSales.last;

                        final topStateEntry =
                            sortedStateSales.isEmpty ? null : sortedStateSales.first;
                        final worstStateEntry =
                            sortedStateSales.isEmpty ? null : sortedStateSales.last;

                        final topAreaEntry =
                            sortedAreaSales.isEmpty ? null : sortedAreaSales.first;
                        final worstAreaEntry =
                            sortedAreaSales.isEmpty ? null : sortedAreaSales.last;

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            AppSurfaceCard(
                              margin: const EdgeInsets.only(bottom: 18),
                              color: colors.brandPrimary.withOpacity(0.10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Analytics range: $_rangeLabel',
                                          style: GoogleFonts.poppins(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<AnalyticsRange>(
                                          value: _range,
                                          dropdownColor: colors.surfaceAlt,
                                          style: GoogleFonts.poppins(
                                            color: colors.textPrimary,
                                          ),
                                          iconEnabledColor: colors.iconPrimary,
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
                                              child: Text('All'),
                                            ),
                                            DropdownMenuItem(
                                              value: AnalyticsRange.custom,
                                              child: Text('Custom'),
                                            ),
                                          ],
                                          onChanged: (value) async {
                                            if (value == null) return;
                                            if (value == AnalyticsRange.custom) {
                                              await _pickCustomRange();
                                              return;
                                            }
                                            setState(() => _range = value);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_range == AnalyticsRange.custom)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: OutlinedButton.icon(
                                        onPressed: _pickCustomRange,
                                        icon: const Icon(Icons.date_range_rounded),
                                        label: const Text('Change Custom Range'),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _filterDropdown(
                                        label: 'State',
                                        value: _selectedState,
                                        items: availableStates,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => _selectedState = value);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      _filterDropdown(
                                        label: 'Admin',
                                        value: _selectedAdmin,
                                        items: availableAdmins,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => _selectedAdmin = value);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _filterDropdown(
                                        label: 'Area',
                                        value: _selectedArea,
                                        items: availableAreas,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => _selectedArea = value);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedState = 'All';
                                              _selectedAdmin = 'All';
                                              _selectedArea = 'All';
                                            });
                                          },
                                          child: const Text('Clear Filters'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Total Sales',
                                    value: '₦${totalSales.toStringAsFixed(2)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Delivered Orders',
                                    value: '${deliveredOrders.length}',
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Admins',
                                    value: '${admins.length + AppConstants.superAdminUids.length}',
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Deliveries',
                                    value: '$totalDeliveries',
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    title: 'Reassignments',
                                    value: '$totalReassignments',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Performance Health'),
                            Row(
                              children: [
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title: 'Order Completion Rate',
                                    value: '${orderCompletionRate.toStringAsFixed(1)}%',
                                    subtitle: 'Delivered orders / total orders',
                                    accentColor: colors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title: 'Order Cancellation Rate',
                                    value: '${orderCancellationRate.toStringAsFixed(1)}%',
                                    subtitle: 'Cancelled orders / total orders',
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
                                    title: 'Ride Completion Rate',
                                    value: '${rideCompletionRate.toStringAsFixed(1)}%',
                                    subtitle: 'Completed rides / total movement',
                                    accentColor: colors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PerformanceStatusCard(
                                    title: 'Ride Cancellation Rate',
                                    value: '${rideCancellationRate.toStringAsFixed(1)}%',
                                    subtitle: 'Cancelled rides / total movement',
                                    accentColor: colors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Top Performers'),
                            Row(
                              children: [
                                Expanded(
                                  child: TopRankCard(
                                    title: 'Top Admin',
                                    name: topAdminEntry?.key ?? 'N/A',
                                    value: topAdminEntry == null
                                        ? '₦0'
                                        : '₦${topAdminEntry.value.toStringAsFixed(2)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TopRankCard(
                                    title: 'Top State',
                                    name: topStateEntry?.key ?? 'N/A',
                                    value: topStateEntry == null
                                        ? '₦0'
                                        : '₦${topStateEntry.value.toStringAsFixed(2)}',
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
                                    name: topAreaEntry?.key ?? 'N/A',
                                    value: topAreaEntry == null
                                        ? '₦0'
                                        : '₦${topAreaEntry.value.toStringAsFixed(2)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Best vs Needs Attention'),
                            ComparisonDuelCard(
                              title: 'Admin Sales Comparison',
                              bestLabel: topAdminEntry?.key ?? 'N/A',
                              bestValue: topAdminEntry == null
                                  ? '₦0'
                                  : '₦${topAdminEntry.value.toStringAsFixed(2)}',
                              worstLabel: worstAdminEntry?.key ?? 'N/A',
                              worstValue: worstAdminEntry == null
                                  ? '₦0'
                                  : '₦${worstAdminEntry.value.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 12),
                            ComparisonDuelCard(
                              title: 'State Sales Comparison',
                              bestLabel: topStateEntry?.key ?? 'N/A',
                              bestValue: topStateEntry == null
                                  ? '₦0'
                                  : '₦${topStateEntry.value.toStringAsFixed(2)}',
                              worstLabel: worstStateEntry?.key ?? 'N/A',
                              worstValue: worstStateEntry == null
                                  ? '₦0'
                                  : '₦${worstStateEntry.value.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 12),
                            ComparisonDuelCard(
                              title: 'Area Sales Comparison',
                              bestLabel: topAreaEntry?.key ?? 'N/A',
                              bestValue: topAreaEntry == null
                                  ? '₦0'
                                  : '₦${topAreaEntry.value.toStringAsFixed(2)}',
                              worstLabel: worstAreaEntry?.key ?? 'N/A',
                              worstValue: worstAreaEntry == null
                                  ? '₦0'
                                  : '₦${worstAreaEntry.value.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Sales Trend'),
                            AnalyticsBarChartCard(
                              title: 'Daily Sales',
                              data: salesSeries,
                              isCurrency: true,
                              emptyLabel: 'No sales trend data yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Order Trend'),
                            AnalyticsBarChartCard(
                              title: 'Daily Orders',
                              data: orderSeries,
                              isCurrency: false,
                              emptyLabel: 'No order trend data yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Ride & Delivery Trend'),
                            AnalyticsBarChartCard(
                              title: 'Daily Movement',
                              data: rideSeries,
                              isCurrency: false,
                              emptyLabel: 'No ride trend data yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Sales by Admin'),
                            AnalyticsBarChartCard(
                              title: 'Top Admin Sales',
                              data: salesByAdmin,
                              isCurrency: true,
                              emptyLabel: 'No sales data yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Sales by State'),
                            AnalyticsBarChartCard(
                              title: 'Top State Sales',
                              data: salesByState,
                              isCurrency: true,
                              emptyLabel: 'No state sales data yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Sales by Area'),
                            AnalyticsBarChartCard(
                              title: 'Top Area Sales',
                              data: salesByArea,
                              isCurrency: true,
                              emptyLabel: 'No area sales data yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Orders by Admin'),
                            AnalyticsBarChartCard(
                              title: 'Admin Order Count',
                              data: ordersByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No admin order activity yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Rides by Admin'),
                            AnalyticsBarChartCard(
                              title: 'Admin Ride Count',
                              data: ridesByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No ride activity yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Deliveries by Admin'),
                            AnalyticsBarChartCard(
                              title: 'Admin Delivery Count',
                              data: deliveriesByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No delivery activity yet',
                            ),
                            const SizedBox(height: 20),
                            const AppSectionTitle(title: 'Manual Reassignments by Admin'),
                            AnalyticsBarChartCard(
                              title: 'Reassignment Count',
                              data: reassignmentsByAdmin,
                              isCurrency: false,
                              emptyLabel: 'No reassignment records yet',
                            ),
                            const SizedBox(height: 24),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSurfaceCard(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              color: colors.brandPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
