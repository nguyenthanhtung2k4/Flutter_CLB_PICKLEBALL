import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  int _page = 1;
  final int _pageSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers(reset: true);
  }

  Future<void> _loadMembers({bool reset = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (reset) {
      _page = 1;
      _hasMore = true;
      _members = [];
    }

    try {
      final res = await _api.getMembers(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _page,
        pageSize: _pageSize,
      );

      final data = (res['data'] as List?) ?? [];
      final totalPages = res['totalPages'] ?? 1;

      setState(() {
        _members.addAll(data);
        _hasMore = _page < totalPages;
        _page++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách thành viên'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _loadMembers(reset: true),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _loadMembers(reset: true),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadMembers(reset: true),
              child: ListView.builder(
                itemCount: _members.length + 1,
                itemBuilder: (context, index) {
                  if (index == _members.length) {
                    if (!_hasMore) {
                      return const SizedBox(height: 16);
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _loadMembers(),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Tải thêm'),
                      ),
                    );
                  }

                  final m = _members[index] as Map<String, dynamic>;
                  final name = m['fullName'] ?? '';
                  final tier = m['tier']?.toString() ?? 'Standard';
                  final rank = m['rankLevel']?.toString() ?? '0';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tier: $tier | Rank: $rank'),
                    trailing: Text('#${m['id'] ?? ''}'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
