import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import 'dart:io';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController();
    XFile? transferImage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Text(
                    'Nạp tiền vào ví',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền nạp (VNĐ)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                   const SizedBox(height: 16),
                   GestureDetector(
                     onTap: () async {
                       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                       if (image != null) {
                         setState(() {
                           transferImage = image;
                         });
                       }
                     },
                     child: Container(
                       height: 150,
                       decoration: BoxDecoration(
                         color: Colors.grey[200],
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey[400]!),
                       ),
                       child: transferImage != null
                           ? ClipRRect(
                               borderRadius: BorderRadius.circular(12),
                               child: Image.file(
                                 File(transferImage!.path),
                                 fit: BoxFit.cover,
                               ),
                             )
                           : const Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                 SizedBox(height: 8),
                                 Text('Tải ảnh chuyển khoản (Bill)'),
                               ],
                             ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: () {
                       // Call API deposit
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Gửi yêu cầu nạp tiền thành công!')),
                       );
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                     ),
                     child: const Text('Xác nhận nạp tiền', style: TextStyle(color: Colors.white)),
                   ),
                   const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBalanceCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Lịch sử giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Lọc',
                  ),
                ],
              ),
            ),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Số dư khả dụng',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '2,500,000 VNĐ',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDepositDialog,
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text('Nạp tiền'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      {'title': 'Booking - Sân 1', 'date': '27/01/2026 10:00', 'amount': '-50,000', 'type': 'minus'},
      {'title': 'Nạp tiền (Banking)', 'date': '26/01/2026 14:30', 'amount': '+500,000', 'type': 'plus'},
      {'title': 'Tham gia giải đấu Summer', 'date': '20/01/2026 09:00', 'amount': '-200,000', 'type': 'minus'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isPlus = t['type'] == 'plus';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset:const Offset(0, 2))],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPlus ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                isPlus ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPlus ? Colors.green : Colors.red,
              ),
            ),
            title: Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(t['date']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Text(
              t['amount']!,
              style: TextStyle(
                color: isPlus ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
