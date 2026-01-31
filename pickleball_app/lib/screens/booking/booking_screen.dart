import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../data/services/api_service.dart';
import '../../data/models/court_model.dart';
import '../../data/models/booking_model.dart';
import '../../servicers/signalr_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _api = ApiService();
  final SignalRService _signalR = SignalRService();
  bool _signalRInitialized = false;
  
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  List<CourtModel> _courts = [];
  List<BookingModel> _bookings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
    
    // Connect to SignalR
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _initSignalR(authProvider);
  }

  Future<void> _initSignalR(AuthProvider authProvider) async {
    if (_signalRInitialized) return;
    final token = await _api.getToken();
    if (token != null) {
      await _signalR.init(AppConfig.baseUrl, token);
      _signalR.listenToBookingUpdates((data) {
        _fetchBookings(); // Refresh on update
      });
      _signalRInitialized = true;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _fetchCourts();
    await _fetchBookings();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchCourts() async {
    try {
      final courts = await _api.getCourts();
      setState(() => _courts = courts);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchBookings() async {
    // Calculate start and end of the visible week
    final start = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final end = start.add(const Duration(days: 7));
    
    try {
      final bookings = await _api.getBookings(start, end);
      setState(() => _bookings = bookings);
    } catch (e) {
      // Handle error
    }
  }

  List<Map<String, dynamic>> _generateSlotsForDay(DateTime date) {
    List<Map<String, dynamic>> slots = [];
    if (_courts.isEmpty) return slots;
    final now = DateTime.now();
    
    // Operating hours: 7:00 - 22:00
    for (var court in _courts) {
      for (int hour = 7; hour < 22; hour++) {
        final slotStart = DateTime(date.year, date.month, date.day, hour);
        final slotEnd = slotStart.add(const Duration(hours: 1));
        
        // Find if this slot is booked
        final booking = _bookings.firstWhere(
          (b) => b.courtId == court.id && 
                 b.startTime.isBefore(slotEnd) && 
                 b.endTime.isAfter(slotStart) &&
                 b.status != 2, // Not cancelled
          orElse: () => BookingModel(
            id: -1,
            courtId: -1,
            courtName: '',
            startTime: DateTime(2000),
            endTime: DateTime(2000),
            status: -1,
            memberName: '',
            memberId: -1,
            holdUntil: null,
          ),
        );

        int status = 0; // Free
        if (booking.id != -1) {
           final authUser = Provider.of<AuthProvider>(context, listen: false).user;
           final isMine = authUser != null && booking.memberId == authUser.memberId;
           if (booking.status == 4) {
             status = isMine ? 3 : 4; // Holding by me / others
           } else {
             status = isMine ? 2 : 1; // Mine / Booked
           }
        }

        // Past slot: disable booking
        if (slotStart.isBefore(now)) {
          status = 5;
        }

        slots.add({
          'court': court,
          'time': '${hour.toString().padLeft(2, '0')}:00',
          'status': status,
          'start': slotStart,
          'end': slotEnd,
        });
      }
    }
    return slots;
  }

  Color _getSlotColor(int status) {
    switch (status) {
      case 1: return Colors.red.shade100;
      case 2: return Colors.green.shade100;
      case 3: return Colors.blue.shade100;
      case 4: return Colors.orange.shade100;
      case 5: return Colors.grey.shade200;
      default: return Colors.white;
    }
  }

  Color _getSlotBorderColor(int status) {
   switch (status) {
      case 1: return Colors.red;
      case 2: return Colors.green;
      case 3: return Colors.blue;
      case 4: return Colors.orange;
      case 5: return Colors.grey;
      default: return Colors.grey.shade300;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: return 'Đã đặt';
      case 2: return 'Của bạn';
      case 3: return 'Bạn đang giữ';
      case 4: return 'Đang giữ';
      case 5: return 'Đã qua';
      default: return 'Trống';
    }
  }

  void _showBookingBottomSheet(Map<String, dynamic> slot) async {
    if (slot['status'] == 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ đã qua, vui lòng chọn khung giờ khác.')),
      );
      return;
    }
    if (slot['status'] != 0) return;

    final CourtModel court = slot['court'];
    final timeStr = slot['time'];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final balance = authProvider.user?.walletBalance ?? 0;
    final durationMinutes = (slot['end'] as DateTime).difference(slot['start'] as DateTime).inMinutes;
    final totalPrice = (durationMinutes / 60) * court.pricePerHour;
    final hasEnoughBalance = balance >= totalPrice;

    try {
      final holdResponse = await _api.holdBooking(court.id, slot['start'], slot['end']);
      final holdId = holdResponse['holdId'] ?? holdResponse['HoldId'];
      final holdUntilRaw = holdResponse['holdUntil'] ?? holdResponse['HoldUntil'];
      final holdUntil = holdUntilRaw != null ? DateTime.tryParse(holdUntilRaw.toString()) : null;

      if (holdId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không giữ được slot. Vui lòng thử lại.')),
        );
        return;
      }

      bool confirmed = false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đặt sân - ${court.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Thời gian: $timeStr - ${_calculateEndTime(timeStr)}'),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Ngày: ${_selectedDay.toString().split(' ')[0]}'),
                ]),
                if (holdUntil != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Giữ chỗ đến: ${holdUntil.hour.toString().padLeft(2, '0')}:${holdUntil.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Chi phí:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${totalPrice.toStringAsFixed(0)} VNĐ', style: const TextStyle(fontSize: 18, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Số dư hiện tại: ${balance.toStringAsFixed(0)} VNĐ'),
                if (!hasEnoughBalance)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Số dư không đủ, vui lòng nạp thêm tiền.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasEnoughBalance ? () async {
                      try {
                        await _api.confirmBooking(holdId);
                        confirmed = true;
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân thành công!')));
                        _fetchBookings(); // Refresh
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.refreshUser();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Xác nhận đặt sân', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (!confirmed) {
        await _api.releaseHold(holdId);
        _fetchBookings();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
  
  String _calculateEndTime(String startTime) {
    int hour = int.parse(startTime.split(':')[0]);
    return '${(hour + 1).toString().padLeft(2, '0')}:00';
  }

  void _showRecurringBookingSheet() {
    if (_courts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có sân để đặt lịch định kỳ.')),
      );
      return;
    }

    CourtModel selectedCourt = _courts.first;
    DateTime startDate = _selectedDay ?? DateTime.now();
    DateTime recurUntil = startDate.add(const Duration(days: 30));
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 0);
    final Set<int> selectedDays = {};

    final dayOptions = const [
      {'label': 'T2', 'value': 1},
      {'label': 'T3', 'value': 2},
      {'label': 'T4', 'value': 3},
      {'label': 'T5', 'value': 4},
      {'label': 'T6', 'value': 5},
      {'label': 'T7', 'value': 6},
      {'label': 'CN', 'value': 0},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đặt lịch định kỳ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CourtModel>(
                      value: selectedCourt,
                      decoration: const InputDecoration(labelText: 'Chọn sân'),
                      items: _courts.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c.name));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedCourt = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày bắt đầu'),
                      subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setModalState(() => startDate = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Giờ bắt đầu'),
                      subtitle: Text('${startTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: startTime);
                        if (picked != null) setModalState(() => startTime = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Giờ kết thúc'),
                      subtitle: Text('${endTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: endTime);
                        if (picked != null) setModalState(() => endTime = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lặp đến ngày'),
                      subtitle: Text('${recurUntil.day}/${recurUntil.month}/${recurUntil.year}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: recurUntil,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setModalState(() => recurUntil = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Chọn ngày lặp', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: dayOptions.map((d) {
                        final value = d['value'] as int;
                        final selected = selectedDays.contains(value);
                        return FilterChip(
                          label: Text(d['label'] as String),
                          selected: selected,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedDays.add(value);
                              } else {
                                selectedDays.remove(value);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedDays.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng chọn ngày lặp.')),
                            );
                            return;
                          }

                          final startDateTime = DateTime(
                            startDate.year,
                            startDate.month,
                            startDate.day,
                            startTime.hour,
                            startTime.minute,
                          );
                          final endDateTime = DateTime(
                            startDate.year,
                            startDate.month,
                            startDate.day,
                            endTime.hour,
                            endTime.minute,
                          );

                          if (endDateTime.isBefore(startDateTime)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu.')),
                            );
                            return;
                          }

                          try {
                            await _api.createRecurringBooking(
                              courtId: selectedCourt.id,
                              startTime: startDateTime,
                              endTime: endDateTime,
                              recurUntil: recurUntil,
                              daysOfWeek: selectedDays.toList(),
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đặt lịch định kỳ thành công!')),
                            );
                            _fetchBookings();
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.refreshUser();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isVip = authProvider.user != null &&
        (authProvider.user!.tier.toLowerCase() == 'gold' || authProvider.user!.tier.toLowerCase() == 'diamond');
    final slots = _selectedDay != null ? _generateSlotsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đặt sân'),
        centerTitle: true,
        actions: [
          if (isVip)
            IconButton(
              onPressed: _showRecurringBookingSheet,
              icon: const Icon(Icons.repeat),
              tooltip: 'Đặt lịch định kỳ',
            ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
               if (_calendarFormat != format) setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchBookings();
            },
            calendarStyle:  const CalendarStyle(
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          if (_isLoading) 
            const LinearProgressIndicator() 
          else 
            Expanded(
              child: slots.isEmpty 
              ? const Center(child: Text('Không có sân hoặc đã hết giờ'))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final CourtModel court = slot['court'];
                return GestureDetector(
                  onTap: () => _showBookingBottomSheet(slot),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getSlotColor(slot['status']),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getSlotBorderColor(slot['status'])),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              court.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text('${slot['time']} - ${_calculateEndTime(slot['time'])}'),
                          ],
                        ),
                        Text(
                          _getStatusText(slot['status']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: slot['status'] == 0 ? Colors.black54 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
