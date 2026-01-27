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
    // Assuming you have a way to get baseUrl. For now hardcode or use config
    // Actually SignalRService needs baseUrl. 
    // We can get token from ApiService logic or AuthProvider if it exposed token (it doesn't directly).
    // Let's us AppConfig.baseUrl
    final token = await _api.getToken();
    if (token != null) {
      await _signalR.init(AppConfig.baseUrl, token);
      // Note: for real device use specific IP. standard localhost port.
      // User is on Windows dev, so maybe localhost is fine for web/windows app.
      // But for Android emulator 10.0.2.2 is needed. 
      // Let's assume Windows/Web for now or use a config. 
      
      _signalR.listenToBookingUpdates((data) {
        _fetchBookings(); // Refresh on update
      });
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
          orElse: () => BookingModel(id: -1, courtId: -1, courtName: '', startTime: DateTime(2000), endTime: DateTime(2000), status: -1, memberName: ''),
        );

        int status = 0; // Free
        if (booking.id != -1) {
           // Check if it's mine
           final myName = Provider.of<AuthProvider>(context, listen: false).user?.fullName;
           if (booking.memberName == myName) status = 2; // Mine
           else status = 1; // Booked
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
      default: return Colors.white;
    }
  }

  Color _getSlotBorderColor(int status) {
     switch (status) {
      case 1: return Colors.red;
      case 2: return Colors.green;
      default: return Colors.grey.shade300;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: return 'Đã đặt';
      case 2: return 'Của bạn';
      default: return 'Trống';
    }
  }

  void _showBookingBottomSheet(Map<String, dynamic> slot) {
    if (slot['status'] != 0) return;

    final CourtModel court = slot['court'];
    final timeStr = slot['time'];

    showModalBottomSheet(
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
               const SizedBox(height: 24),
               const Text('Chi phí:', style: TextStyle(fontWeight: FontWeight.bold)),
               Text('${court.pricePerHour.toStringAsFixed(0)} VNĐ', style: const TextStyle(fontSize: 18, color: AppColors.primary)),
               const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () async {
                     try {
                        Navigator.pop(context); // Close sheet first
                        await _api.createBooking(court.id, slot['start'], slot['end']);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân thành công!')));
                        _fetchBookings(); // Refresh
                     } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                     }
                   },
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
  }
  
  String _calculateEndTime(String startTime) {
    int hour = int.parse(startTime.split(':')[0]);
    return '${(hour + 1).toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final slots = _selectedDay != null ? _generateSlotsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch đặt sân'), centerTitle: true),
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
