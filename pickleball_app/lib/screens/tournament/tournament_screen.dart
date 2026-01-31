import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'tournament_detail_screen.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Đang mở'),
            Tab(text: 'Đang diễn ra'),
            Tab(text: 'Đã kết thúc'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTournamentList('Open'),
          _buildTournamentList('Ongoing'),
          _buildTournamentList('Finished'),
        ],
      ),
    );
  }

  Widget _buildTournamentList(String status) {
    return FutureBuilder<List<dynamic>>(
      future: _api.getTournaments(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final tournaments = snapshot.data ?? [];

        if (tournaments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Chưa có giải đấu nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tournaments.length,
          itemBuilder: (context, index) {
            final t = tournaments[index];
            return _buildTournamentCard(t);
          },
        );
      },
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    final id = tournament['id'] ?? 0;
    final name = tournament['name'] ?? 'Unnamed Tournament';
    final startDate = tournament['startDate'] ?? '';
    final endDate = tournament['endDate'] ?? '';
    final currentParticipants = tournament['currentParticipants'] ?? 0;
    final maxParticipants = tournament['maxParticipants'];
    final entryFee = (tournament['entryFee'] ?? 0.0).toDouble();
    final format = _formatTournamentFormat(tournament['format']);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: id)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(child: Icon(Icons.emoji_events, size: 50, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      maxParticipants != null ? '$currentParticipants/$maxParticipants' : '$currentParticipants',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        format,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entryFee.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showJoinDialog(id, name, entryFee),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Tham gia'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTournamentFormat(dynamic format) {
    if (format is int) {
      switch (format) {
        case 0:
          return 'Round Robin';
        case 1:
          return 'Knockout';
        case 2:
          return 'Hybrid';
        default:
          return 'Unknown';
      }
    }
    return format?.toString() ?? 'Unknown';
  }

  void _showJoinDialog(int tournamentId, String name, double fee) {
    final teamNameController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final balance = authProvider.user?.walletBalance ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tham gia $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phí tham dự: ${fee.toStringAsFixed(0)} VNĐ'),
            Text('Số dư hiện tại: ${balance.toStringAsFixed(0)} VNĐ'),
            if (balance < fee)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ Số dư không đủ! Vui lòng nạp thêm tiền.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: 'Tên đội (Tùy chọn)',
                hintText: 'Nhập tên đội của bạn',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: balance < fee
                ? null
                : () async {
                    try {
                      Navigator.pop(context);
                      await _api.joinTournament(
                        tournamentId,
                        teamName: teamNameController.text.trim().isEmpty ? null : teamNameController.text.trim(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đăng ký tham gia giải đấu thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh the list
                      setState(() {});
                      // Refresh user data to update balance
                      await authProvider.refreshUser();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: balance < fee ? Colors.grey : AppColors.primary,
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
