import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/api_service.dart';
import 'admin_manage_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<dynamic>> _revenueFuture;
  late Future<Map<String, dynamic>> _bookingStatsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _api.getAdminDashboardStats();
    _revenueFuture = _api.getRevenueChart(days: 30);
    _bookingStatsFuture = _api.getBookingStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminManageScreen()),
              );
            },
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'Quản trị Admin',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _statsFuture = _api.getAdminDashboardStats();
            _revenueFuture = _api.getRevenueChart(days: 30);
            _bookingStatsFuture = _api.getBookingStats();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  return _buildSummaryCards(snapshot.data!);
                },
              ),
              const SizedBox(height: 24),
              _buildRevenueChartTitle(),
              const SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: _revenueFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  return _buildRevenueChart(snapshot.data!);
                },
              ),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: _bookingStatsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  return _buildRecentBookingsList(snapshot.data!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    final monthlyRevenue = (stats['monthlyRevenue'] ?? 0).toDouble();
    final monthlyBookings = stats['monthlyBookings'] ?? 0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Doanh thu tháng', monthlyRevenue.toStringAsFixed(0), Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Booking tháng', '$monthlyBookings', Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: stdColor(color, 50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stdColor(color, 100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: stdColor(color, 700), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: stdColor(color, 900), fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color stdColor(Color color, int shade) {
    if (color == Colors.green) return Colors.green[shade]!;
    if (color == Colors.blue) return Colors.blue[shade]!;
    if (color == Colors.red) return Colors.red[shade]!;
    return color;
  }

  Widget _buildRevenueChartTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Biểu đồ doanh thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Icon(Icons.bar_chart, color: Colors.grey),
      ],
    );
  }

  Widget _buildRevenueChart(List<dynamic> data) {
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      final deposit = (item['depositAmount'] ?? 0).toDouble() / 1000000;
      final payment = (item['paymentAmount'] ?? 0).toDouble() / 1000000;
      barGroups.add(makeGroupData(i, deposit, payment));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
               sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, _) => Text('${val.toInt()}M', style: const TextStyle(fontSize: 10)))
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('T${value.toInt() + 1}', style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.primary,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: y2,
          color: AppColors.error,
          width: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
      barsSpace: 4,
    );
  }

  Widget _buildRecentBookingsList(Map<String, dynamic> stats) {
    final total = stats['totalBookings'] ?? 0;
    final confirmed = stats['confirmedBookings'] ?? 0;
    final cancelled = stats['cancelledBookings'] ?? 0;
    final byMonth = (stats['bookingsByMonth'] as Map?)?.cast<String, dynamic>() ?? {};

    final months = byMonth.keys.toList()..sort();
    final lastMonths = months.length > 3 ? months.sublist(months.length - 3) : months;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Tổng', '$total', Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Xác nhận', '$confirmed', Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Hủy', '$cancelled', Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lastMonths.length,
          itemBuilder: (context, index) {
            final month = lastMonths[index];
            final count = byMonth[month] ?? 0;
            return ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text('Tháng $month'),
              trailing: Text('$count booking'),
            );
          },
        ),
      ],
    );
  }
}
