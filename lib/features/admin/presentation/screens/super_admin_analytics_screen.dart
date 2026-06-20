// lib/features/admin/presentation/screens/super_admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/widgets/analytics_bar_chart_card.dart';
import 'package:pfb/features/admin/presentation/widgets/comparison_duel_card.dart';
import 'package:pfb/features/admin/presentation/widgets/performance_status_card.dart';
import 'package:pfb/features/admin/presentation/widgets/top_rank_card.dart';
import 'package:pfb/models/order_model.dart';
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

  AnalyticsRange _range = AnalyticsRange.all;
  DateTimeRange? _customRange;

  String _selectedState = 'All';
  String _selectedAdmin = 'All';
  String _selectedArea = 'All';

  DateTime _orderDate(OrderModel order) {
    return DateTime.tryParse(order.createdAt) ?? DateTime(2000);
  }

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
    if (!_inRange(_orderDate(order))) return false;
    if (_selectedState != 'All' &&
        order.assignedAdminState != _selectedState) {
      return false;
    }
    if (_selectedAdmin != 'All' &&
        order.assignedAdminName != _selectedAdmin) {
      return false;
    }
    if (_selectedArea != 'All' &&
        order.assignedAdminArea != _selectedArea) {
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

  Map<String, double> _dailySalesSeries(List<OrderModel> orders) {
    final series = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      final d = _orderDate(order);
      final key = '${d.day}/${d.month}/${d.year}';
      series[key] = (series[key] ?? 0) + order.totalAmount;
    }
    return series;
  }

  Map<String, int> _dailyOrderSeries(List<OrderModel> orders) {
    final series = <String, int>{};
    for (final order in orders) {
      final d = _orderDate(order);
      final key = '${d.day}/${d.month}/${d.year}';
      series[key] = (series[key] ?? 0) + 1;
    }
    return series;
  }

  Map<String, double> _salesByFabricType(List<OrderModel> orders) {
    final map = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      for (final item in order.items) {
        final fabric =
            (item['fabricType'] ?? 'General').toString().trim();
        final price = ((item['price'] ?? 0) as num).toDouble() *
            ((item['qty'] ?? 1) as int);
        map[fabric] = (map[fabric] ?? 0) + price;
      }
    }
    return map;
  }

  Map<String, int> _ordersByFabricType(List<OrderModel> orders) {
    final map = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        final fabric =
            (item['fabricType'] ?? 'General').toString().trim();
        map[fabric] = (map[fabric] ?? 0) + 1;
      }
    }
    return map;
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
            style: GoogleFonts.poppins(
                color: colors.textPrimary, fontSize: 12),
            iconEnabledColor: colors.iconPrimary,
            isExpanded: true,
            hint: Text(label,
                style: GoogleFonts.poppins(
                    color: colors.textSecondary)),
            items: items
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis),
                    ))
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
        return '${_customRange!.start.day}/${_customRange!.start.month}/${_customRange!.start.year}'
            ' — ${_customRange!.end.day}/${_customRange!.end.month}/${_customRange!.end.year}';
      case AnalyticsRange.all:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
        _firebaseService.currentUser?.uid);

    return AppPageScaffold(
      title: 'Analytics Dashboard',
      body: !isSuperAdmin
          ? Center(
              child: Text(
                'Only super admins can view analytics.',
                style:
                    GoogleFonts.poppins(color: colors.textSecondary),
              ),
            )
          : StreamBuilder<List<OrderModel>>(
              stream: _firebaseService.watchAllOrders(),
              builder: (context, orderSnapshot) {
                final orders = orderSnapshot.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firebaseService.watchAdmins(),
                  builder: (context, adminSnapshot) {
                    final admins = adminSnapshot.data ?? [];

                    final availableStates = {
                      'All',
                      ...orders
                          .map((e) => e.assignedAdminState)
                          .where((e) => e.trim().isNotEmpty),
                    }.toList()
                      ..sort();

                    final availableAdmins = {
                      'All',
                      ...orders
                          .map((e) => e.assignedAdminName)
                          .where((e) => e.trim().isNotEmpty),
                    }.toList()
                      ..sort();

                    final availableAreas = {
                      'All',
                      ...orders
                          .map((e) => e.assignedAdminArea)
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

                    final deliveredOrders = filteredOrders
                        .where((e) => e.status == 'delivered')
                        .toList();
                    final cancelledOrders = filteredOrders
                        .where((e) => e.status == 'cancelled')
                        .toList();
                    final processingOrders = filteredOrders
                        .where((e) => e.status == 'processing')
                        .toList();
                    final shippedOrders = filteredOrders
                        .where((e) => e.status == 'shipped')
                        .toList();

                    final totalSales = deliveredOrders.fold<double>(
                      0,
                      (sum, item) => sum + item.totalAmount,
                    );
                    final totalOrders = filteredOrders.length;

                    final totalEscalations = filteredOrders
                        .where((e) => e.escalatedToSuperAdmin)
                        .length;

                    final totalReassignments = filteredOrders
                        .where((e) =>
                            e.assignmentMethod == 'manual_reassignment')
                        .length;

                    final orderCompletionRate = totalOrders == 0
                        ? 0.0
                        : (deliveredOrders.length / totalOrders) * 100;

                    final orderCancellationRate = totalOrders == 0
                        ? 0.0
                        : (cancelledOrders.length / totalOrders) * 100;

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
                    final salesByFabric =
                        _salesByFabricType(filteredOrders);

                    final ordersByAdmin = _countOrdersByField(
                      filteredOrders,
                      (o) => o.assignedAdminName,
                    );
                    final ordersByFabric =
                        _ordersByFabricType(filteredOrders);

                    final reassignmentsByAdmin = _countOrdersByField(
                      filteredOrders
                          .where((e) =>
                              e.assignmentMethod == 'manual_reassignment')
                          .toList(),
                      (o) => o.assignedAdminName,
                    );

                    final salesSeries =
                        _dailySalesSeries(filteredOrders);
                    final orderSeries =
                        _dailyOrderSeries(filteredOrders);

                    final sortedAdminSales =
                        salesByAdmin.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                    final sortedStateSales =
                        salesByState.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                    final sortedAreaSales =
                        salesByArea.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                    final topAdmin = sortedAdminSales.isEmpty
                        ? null
                        : sortedAdminSales.first;
                    final worstAdmin = sortedAdminSales.isEmpty
                        ? null
                        : sortedAdminSales.last;
                    final topState = sortedStateSales.isEmpty
                        ? null
                        : sortedStateSales.first;
                    final worstState = sortedStateSales.isEmpty
                        ? null
                        : sortedStateSales.last;
                    final topArea = sortedAreaSales.isEmpty
                        ? null
                        : sortedAreaSales.first;
                    final worstArea = sortedAreaSales.isEmpty
                        ? null
                        : sortedAreaSales.last;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppSurfaceCard(
                          margin: const EdgeInsets.only(bottom: 18),
                          color:
                              colors.brandPrimary.withOpacity(0.08),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Range: $_rangeLabel',
                                      style: GoogleFonts.poppins(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child:
                                        DropdownButton<AnalyticsRange>(
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
                                          child: Text('All Time'),
                                        ),
                                        DropdownMenuItem(
                                          value: AnalyticsRange.custom,
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
                                    icon: const Icon(
                                        Icons.date_range_rounded),
                                    label:
                                        const Text('Change Custom Range'),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _filterDropdown(
                                    label: 'State',
                                    value: _selectedState,
                                    items: availableStates,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _selectedState = v);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _filterDropdown(
                                    label: 'Admin',
                                    value: _selectedAdmin,
                                    items: availableAdmins,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _selectedAdmin = v);
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
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _selectedArea = v);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() {
                                        _selectedState = 'All';
                                        _selectedAdmin = 'All';
                                        _selectedArea = 'All';
                                      }),
                                      child: const Text('Clear Filters'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const AppSectionTitle(title: 'Sales Overview'),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Revenue',
                                value: '₦${totalSales.toStringAsFixed(0)}',
                                icon: Icons.payments_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Delivered Orders',
                                value: '${deliveredOrders.length}',
                                icon: Icons.check_circle_outline_rounded,
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
                                icon: Icons.receipt_long_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Processing',
                                value: '${processingOrders.length}',
                                icon: Icons.autorenew_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Shipped',
                                value: '${shippedOrders.length}',
                                icon: Icons.local_shipping_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Cancelled',
                                value: '${cancelledOrders.length}',
                                icon: Icons.cancel_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Admins',
                                value:
                                    '${admins.length + AppConstants.superAdminUids.length}',
                                icon: Icons.admin_panel_settings_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Escalations',
                                value: '$totalEscalations',
                                icon: Icons.warning_amber_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Reassignments',
                                value: '$totalReassignments',
                                icon: Icons.swap_horiz_rounded,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(
                            title: 'Performance Health'),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: PerformanceStatusCard(
                                title: 'Completion Rate',
                                value:
                                    '${orderCompletionRate.toStringAsFixed(1)}%',
                                subtitle: 'Delivered / total orders',
                                accentColor: colors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PerformanceStatusCard(
                                title: 'Cancellation Rate',
                                value:
                                    '${orderCancellationRate.toStringAsFixed(1)}%',
                                subtitle: 'Cancelled / total orders',
                                accentColor: colors.error,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(title: 'Top Performers'),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: TopRankCard(
                                title: 'Top Admin',
                                name: topAdmin?.key ?? 'N/A',
                                value: topAdmin == null
                                    ? '₦0'
                                    : '₦${topAdmin.value.toStringAsFixed(0)}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TopRankCard(
                                title: 'Top State',
                                name: topState?.key ?? 'N/A',
                                value: topState == null
                                    ? '₦0'
                                    : '₦${topState.value.toStringAsFixed(0)}',
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
                                name: topArea?.key ?? 'N/A',
                                value: topArea == null
                                    ? '₦0'
                                    : '₦${topArea.value.toStringAsFixed(0)}',
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(
                            title: 'Best vs Needs Attention'),
                        const SizedBox(height: 10),

                        ComparisonDuelCard(
                          title: 'Admin Sales Comparison',
                          bestLabel: topAdmin?.key ?? 'N/A',
                          bestValue: topAdmin == null
                              ? '₦0'
                              : '₦${topAdmin.value.toStringAsFixed(0)}',
                          worstLabel: worstAdmin?.key ?? 'N/A',
                          worstValue: worstAdmin == null
                              ? '₦0'
                              : '₦${worstAdmin.value.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 12),

                        ComparisonDuelCard(
                          title: 'State Sales Comparison',
                          bestLabel: topState?.key ?? 'N/A',
                          bestValue: topState == null
                              ? '₦0'
                              : '₦${topState.value.toStringAsFixed(0)}',
                          worstLabel: worstState?.key ?? 'N/A',
                          worstValue: worstState == null
                              ? '₦0'
                              : '₦${worstState.value.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 12),

                        ComparisonDuelCard(
                          title: 'Area Sales Comparison',
                          bestLabel: topArea?.key ?? 'N/A',
                          bestValue: topArea == null
                              ? '₦0'
                              : '₦${topArea.value.toStringAsFixed(0)}',
                          worstLabel: worstArea?.key ?? 'N/A',
                          worstValue: worstArea == null
                              ? '₦0'
                              : '₦${worstArea.value.toStringAsFixed(0)}',
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(title: 'Revenue Trend'),
                        AnalyticsBarChartCard(
                          title: 'Daily Sales (₦)',
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
                        const AppSectionTitle(
                            title: 'Revenue by Fabric Type'),
                        AnalyticsBarChartCard(
                          title: 'Fabric Type Sales',
                          data: salesByFabric,
                          isCurrency: true,
                          emptyLabel: 'No fabric sales data yet',
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(
                            title: 'Orders by Fabric Type'),
                        AnalyticsBarChartCard(
                          title: 'Fabric Type Orders',
                          data: ordersByFabric,
                          isCurrency: false,
                          emptyLabel: 'No fabric order data yet',
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(title: 'Sales by Admin'),
                        AnalyticsBarChartCard(
                          title: 'Admin Revenue',
                          data: salesByAdmin,
                          isCurrency: true,
                          emptyLabel: 'No admin sales data yet',
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(title: 'Sales by State'),
                        AnalyticsBarChartCard(
                          title: 'State Revenue',
                          data: salesByState,
                          isCurrency: true,
                          emptyLabel: 'No state sales data yet',
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(title: 'Sales by Area'),
                        AnalyticsBarChartCard(
                          title: 'Area Revenue',
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
                          emptyLabel: 'No admin order data yet',
                        ),

                        const SizedBox(height: 20),
                        const AppSectionTitle(
                            title: 'Reassignments by Admin'),
                        AnalyticsBarChartCard(
                          title: 'Reassignment Count',
                          data: reassignmentsByAdmin,
                          isCurrency: false,
                          emptyLabel: 'No reassignment data yet',
                        ),

                        const SizedBox(height: 32),
                      ],
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
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    this.icon = Icons.bar_chart_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSurfaceCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: colors.brandPrimary.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}