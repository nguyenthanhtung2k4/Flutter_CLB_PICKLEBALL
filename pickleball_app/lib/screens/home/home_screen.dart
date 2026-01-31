import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:badges/badges.dart' as badges;
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _upcomingMatchesFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _api.getMyProfile();
    _upcomingMatchesFuture = _api.getUpcomingMatches();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          // Safe check, though router handles it
          if (user == null) return const Center(child: CircularProgressIndicator());

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, user.fullName, user.walletBalance, user.avatarUrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Thống kê hạng (Rank)'),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildRankChart(_buildRankSpots([], user.rankLevel));
                          }

                          final data = snapshot.data ?? {};
                          final history = (data['rankHistory'] as List?) ?? [];
                          return _buildRankChart(_buildRankSpots(history, user.rankLevel));
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Lịch thi đấu sắp tới'),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              _buildUpcomingMatchesList(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name, double balance, String? avatarUrl) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                  ? const Icon(Icons.person, color: AppColors.primary) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${balance.toStringAsFixed(0)} VNĐ',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: FutureBuilder<int>(
            future: context.read<AuthProvider>().user != null 
                ? ApiService().getUnreadNotificationsCount() 
                : Future.value(0),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              return IconButton(
                icon: unreadCount > 0
                    ? badges.Badge(
                        badgeContent: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white),
                      )
                    : const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  context.push('/notifications');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  Widget _buildRankChart(List<FlSpot> spots) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
             rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0: return const Text('WK1', style: TextStyle(fontSize: 10));
                    case 2: return const Text('WK2', style: TextStyle(fontSize: 10));
                    case 4: return const Text('WK3', style: TextStyle(fontSize: 10));
                    case 6: return const Text('WK4', style: TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? const [FlSpot(0, 0)] : spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildRankSpots(List<dynamic> history, double fallbackRank) {
    if (history.isEmpty) {
      return [FlSpot(0, fallbackRank)];
    }

    final items = history.reversed.toList();
    final maxPoints = items.length > 7 ? 7 : items.length;
    final List<FlSpot> spots = [];

    for (int i = 0; i < maxPoints; i++) {
      final item = items[i] as Map<String, dynamic>;
      final value = (item['newRank'] ?? item['NewRank'] ?? fallbackRank).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  Widget _buildUpcomingMatchesList() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<dynamic>>(
        future: _upcomingMatchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Không tải được lịch thi đấu.')),
            );
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Chưa có lịch thi đấu sắp tới.')),
            );
          }

          return Column(
            children: matches.map((m) {
              final map = m as Map<String, dynamic>;
              final title = map['tournamentName'] ?? 'Trận đấu';
              final round = map['roundName'] ?? '';
              final start = map['startDateTime'] ?? '';
              final team1 = (map['team1'] as List?)?.join(', ') ?? '';
              final team2 = (map['team2'] as List?)?.join(', ') ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.sports_tennis, color: AppColors.primary),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${_formatDateTime(start)} ${round.isNotEmpty ? "- $round" : ""}'),
                        const SizedBox(height: 2),
                        Text('$team1 vs. $team2', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: Chip(
                      label: const Text('Sắp đấu', style: TextStyle(color: Colors.white, fontSize: 10)),
                      backgroundColor: AppColors.warning,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
