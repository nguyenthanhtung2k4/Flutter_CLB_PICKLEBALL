import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Giải đấu'),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Đang mở'),
              Tab(text: 'Đang diễn ra'),
              Tab(text: 'Đã kết thúc'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTournamentList(context, 'Open'),
            _buildTournamentList(context, 'Ongoing'),
            _buildTournamentList(context, 'Finished'),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList(BuildContext context, String status) {
    final List<Map<String, dynamic>> tournaments = [
      {
        'name': 'Pickleball Summer Open 2026',
        'date': '20/07/2026',
        'participants': '16/32',
        'fee': '200,000 VNĐ',
        'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgE1KSYzh6nHpi5FUZBzC0nvLPbtsJH4M5Og&s', 
      },
      {
        'name': 'Community Cup',
        'date': '15/08/2026',
        'participants': '8/16',
        'fee': '100,000 VNĐ',
         'image': 'https://via.placeholder.com/150',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final t = tournaments[index];
        return Card(
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
                  // image: DecorationImage(image: NetworkImage(t['image']), fit: BoxFit.cover),
                ),
                child: const Center(child:  Icon(Icons.emoji_events, size: 50, color: Colors.grey)), 
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(t['date'], style: const TextStyle(color: Colors.grey)),
                        const Spacer(),
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(t['participants'], style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t['fee'],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                             _showJoinDialog(context, t['name'], t['fee']);
                          },
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
        );
      },
    );
  }

  void _showJoinDialog(BuildContext context, String name, String fee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tham gia $name'),
        content: Text('Xác nhận tham gia giải đấu?\nPhí tham dự: $fee sẽ được trừ vào ví của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đăng ký thành công!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
