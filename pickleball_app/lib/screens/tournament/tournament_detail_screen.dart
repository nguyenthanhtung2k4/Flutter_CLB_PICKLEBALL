import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final ApiService _api = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết giải đấu')),
      body: FutureBuilder<dynamic>(
        future: _api.getTournamentDetail(widget.tournamentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final data = snapshot.data as Map<String, dynamic>? ?? {};
          final tournament = data['tournament'] as Map<String, dynamic>? ?? {};
          final participants = (data['participants'] as List?) ?? [];
          final matches = (data['matches'] as List?) ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(tournament),
              const SizedBox(height: 16),
              _buildParticipantsCard(participants),
              const SizedBox(height: 16),
              _buildMatchesCard(matches),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> tournament) {
    final name = tournament['name'] ?? '';
    final startDate = tournament['startDate'] ?? '';
    final endDate = tournament['endDate'] ?? '';
    final entryFee = (tournament['entryFee'] ?? 0).toDouble();
    final prizePool = (tournament['prizePool'] ?? 0).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Thời gian: ${_formatDate(startDate)} - ${_formatDate(endDate)}'),
            const SizedBox(height: 4),
            Text('Phí tham gia: ${entryFee.toStringAsFixed(0)} VNĐ'),
            const SizedBox(height: 4),
            Text('Giải thưởng: ${prizePool.toStringAsFixed(0)} VNĐ'),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard(List<dynamic> participants) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thành viên tham gia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (participants.isEmpty)
              const Text('Chưa có thành viên tham gia.'),
            if (participants.isNotEmpty)
              ...participants.map((p) {
                final map = p as Map<String, dynamic>;
                final name = map['memberName'] ?? '';
                final team = map['teamName'] ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: Text(name),
                  subtitle: team.isNotEmpty ? Text('Đội: $team') : null,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesCard(List<dynamic> matches) {
    if (matches.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có lịch thi đấu.'),
        ),
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final m in matches) {
      final map = m as Map<String, dynamic>;
      final round = map['roundName'] ?? 'Round';
      grouped.putIfAbsent(round, () => []).add(map);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch thi đấu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...entry.value.map((m) {
                    final score1 = m['score1'] ?? 0;
                    final score2 = m['score2'] ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sports_tennis),
                      title: Text('Tỉ số: $score1 - $score2'),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
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
}
