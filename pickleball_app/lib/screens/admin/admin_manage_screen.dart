import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_service.dart';

class AdminManageScreen extends StatefulWidget {
  const AdminManageScreen({super.key});

  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  // Pending deposits state
  int _depositPage = 1;
  final int _depositPageSize = 10;
  bool _depositLoading = false;
  bool _depositHasMore = true;
  List<dynamic> _pendingDeposits = [];

  // Members state
  final TextEditingController _searchController = TextEditingController();
  int _memberPage = 1;
  final int _memberPageSize = 10;
  bool _memberLoading = false;
  bool _memberHasMore = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingDeposits(reset: true);
    _loadMembers(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingDeposits({bool reset = false}) async {
    if (_depositLoading) return;
    setState(() => _depositLoading = true);

    if (reset) {
      _depositPage = 1;
      _depositHasMore = true;
      _pendingDeposits = [];
    }

    try {
      final res = await _api.getPendingDeposits(page: _depositPage, pageSize: _depositPageSize);
      final data = (res['data'] as List?) ?? [];
      final totalPages = res['totalPages'] ?? 1;

      setState(() {
        _pendingDeposits.addAll(data);
        _depositHasMore = _depositPage < totalPages;
        _depositPage++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _depositLoading = false);
    }
  }

  Future<void> _approveDeposit(int transactionId) async {
    try {
      await _api.approveDeposit(transactionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã duyệt nạp tiền.'), backgroundColor: Colors.green),
      );
      await _loadPendingDeposits(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadMembers({bool reset = false}) async {
    if (_memberLoading) return;
    setState(() => _memberLoading = true);

    if (reset) {
      _memberPage = 1;
      _memberHasMore = true;
      _members = [];
    }

    try {
      final res = await _api.getMembers(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _memberPage,
        pageSize: _memberPageSize,
      );
      final data = (res['data'] as List?) ?? [];
      final totalPages = res['totalPages'] ?? 1;

      setState(() {
        _members.addAll(data);
        _memberHasMore = _memberPage < totalPages;
        _memberPage++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _memberLoading = false);
    }
  }

  Future<void> _promoteMember(int memberId) async {
    try {
      await _api.promoteMemberToAdmin(memberId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cấp quyền Admin.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showCreateAdminDialog() async {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Admin mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Họ tên (tùy chọn)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.createAdminMember(
                  username: usernameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  fullName: fullNameController.text.trim().isEmpty ? null : fullNameController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tạo admin thành công.'), backgroundColor: Colors.green),
                );
                await _loadMembers(reset: true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị Admin'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Duyệt nạp tiền'),
            Tab(text: 'Quyền Admin'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showCreateAdminDialog,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Tạo Admin',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingDeposits(),
          _buildAdminMembers(),
        ],
      ),
    );
  }

  Widget _buildPendingDeposits() {
    if (_pendingDeposits.isEmpty && _depositLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: () => _loadPendingDeposits(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingDeposits.length + 1,
        itemBuilder: (context, index) {
          if (index == _pendingDeposits.length) {
            if (!_depositHasMore) return const SizedBox(height: 16);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton(
                onPressed: _depositLoading ? null : () => _loadPendingDeposits(),
                child: _depositLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tải thêm'),
              ),
            );
          }

          final d = _pendingDeposits[index] as Map<String, dynamic>;
          final id = d['transactionId'] ?? 0;
          final memberName = d['memberName'] ?? '';
          final amount = (d['amount'] ?? 0).toDouble();
          final created = d['createdDate'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Số tiền: ${amount.toStringAsFixed(0)} VNĐ\nNgày: $created'),
              trailing: ElevatedButton(
                onPressed: () => _approveDeposit(id),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminMembers() {
    return Column(
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
                  if (!_memberHasMore) return const SizedBox(height: 16);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: ElevatedButton(
                      onPressed: _memberLoading ? null : () => _loadMembers(),
                      child: _memberLoading
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
                final id = m['id'] ?? 0;
                final tier = m['tier']?.toString() ?? 'Standard';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tier: $tier | ID: $id'),
                  trailing: ElevatedButton(
                    onPressed: () => _promoteMember(id),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Cấp Admin', style: TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
