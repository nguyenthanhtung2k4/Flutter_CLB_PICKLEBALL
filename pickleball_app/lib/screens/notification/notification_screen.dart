import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = ApiService();
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await _api.markAllNotificationsAsRead();
                setState(() {}); // Refresh
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _currentPage = 1;
          });
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _api.getNotifications(page: _currentPage, pageSize: _pageSize),
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
                    Text('Lỗi: ${snapshot.error
}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final notifications = (data['data'] as List?) ?? [];
            final totalPages = data['totalPages'] ?? 1;

            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment:MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Chưa có thông báo nào', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length + (totalPages > _currentPage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  // Load more button
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentPage++;
                        });
                      },
                      child: const Text('Tải thêm'),
                    ),
                  );
                }

                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final id = notification['id'] ?? 0;
    final title = notification['title'] ?? '';
    final message = notification['message'] ?? '';
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 0; // 0=Info, 1=Success, 2=Warning, 3=Error
    final linkUrl = notification['linkUrl'];
    final createdDate = notification['createdDate'] ?? '';

    final IconData icon = type == 1
        ? Icons.check_circle_outline
        : type == 2
            ? Icons.warning_amber_outlined
            : type == 3
                ? Icons.error_outline
                : Icons.info_outline;

    final Color iconColor = type == 1
        ? Colors.green
        : type == 2
            ? Colors.orange
            : type == 3
                ? Colors.red
                : AppColors.primary;

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          try {
            await _api.markNotificationAsRead(id);
            setState(() {}); // Refresh to mark as read
          } catch (e) {
            // Ignore error
          }
        }

        // Navigate to linkUrl if exists
        if (linkUrl != null && linkUrl.isNotEmpty) {
          // You can use context.go(linkUrl) if it's a valid route
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  if (title.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(createdDate),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
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
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
