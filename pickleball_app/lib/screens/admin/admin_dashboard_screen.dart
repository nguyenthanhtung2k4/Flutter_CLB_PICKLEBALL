import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildRevenueChartTitle(),
            const SizedBox(height: 16),
            _buildRevenueChart(),
            const SizedBox(height: 24),
            _buildRecentBookingsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Doanh thu tháng', '50.2M', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Booking tháng', '1,240', Colors.blue)),
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

  Widget _buildRevenueChart() {
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
          barGroups: [
            makeGroupData(0, 5, 2),
            makeGroupData(1, 6, 3),
            makeGroupData(2, 8, 4),
            makeGroupData(3, 7, 5),
            makeGroupData(4, 9, 4),
            makeGroupData(5, 12, 6),
          ],
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

  Widget _buildRecentBookingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('User ${index + 1}'),
              subtitle: Text('Booked Court ${index + 1} - 18:00'),
              trailing: const Text('Success', style: TextStyle(color: Colors.green)),
            );
          },
        ),
      ],
    );
  }
}
