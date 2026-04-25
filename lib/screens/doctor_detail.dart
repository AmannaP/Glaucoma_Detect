import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'messages.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTime;
  List<String> _busySlots = [];
  bool _isBooking = false;
  bool _isLoadingSlots = false;

  final List<String> _allTimeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM",
    "01:00 PM", "02:00 PM", "03:00 PM",
    "04:00 PM", "05:00 PM"
  ];

  Future<void> _fetchBusySlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
    });

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/glaucoma_backend/appointments.php?doctor_name=${widget.doctor['name']}&date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _busySlots = List<String>.from(data['busy_slots']);
          });
        }
      }
    } catch (e) {
      print("Error fetching slots: $e");
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1; // Fallback for demo
      final dateStr = _selectedDay!.toIso8601String().split('T')[0];

      final response = await http.post(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/glaucoma_backend/appointments.php'),
        body: json.encode({
          "user_id": userId,
          "doctor_name": widget.doctor['name'],
          "specialty": widget.doctor['specialty'],
          "date": dateStr,
          "time": _selectedTime
        }),
      );

      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        _showBookingConfirmation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    const accentGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Doctor Details"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 50, color: primaryGreen),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor['name'],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.doctor['specialty'],
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.doctor['rating'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(width: 15),
                            Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 4),
                            Text(widget.doctor['distance'], style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
                                  appBar: AppBar(title: Text(widget.doctor['name']), backgroundColor: Colors.black, foregroundColor: primaryGreen),
                                  body: const MessagesScreen(),
                                )));
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text("Message"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF131C24),
                                foregroundColor: primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ).copyWith(side: WidgetStateProperty.all(const BorderSide(color: Colors.white10))),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, color: Colors.white70),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calling...")));
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF131C24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Bio
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("About", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 10),
                  Text(
                    "Experienced ${widget.doctor['specialty']} with over 10 years of experience in diagnosing and treating various eye conditions, including advanced glaucoma management.",
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),

            // Booking Calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text("Book Appointment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
            ),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white),
                weekendStyle: TextStyle(color: Colors.white60),
              ),
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                formatButtonDecoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: Colors.white30)),
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _fetchBusySlots(selectedDay);
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: primaryGreen.withOpacity(0.3), shape: BoxShape.circle),
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white60),
                outsideTextStyle: const TextStyle(color: Colors.white24),
              ),
            ),

            const SizedBox(height: 20),

            // Time Slots
            if (_selectedDay != null) ...[
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Select Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
                    if (_isLoadingSlots) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _allTimeSlots.length,
                  itemBuilder: (context, index) {
                    final time = _allTimeSlots[index];
                    final isBusy = _busySlots.contains(time);
                    final isSelected = _selectedTime == time;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: isBusy ? null : (selected) {
                          setState(() {
                            _selectedTime = selected ? time : null;
                          });
                        },
                        selectedColor: primaryGreen,
                        backgroundColor: const Color(0xFF131C24),
                        disabledColor: Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isBusy ? Colors.red : (isSelected ? Colors.black : Colors.white),
                          decoration: isBusy ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Book Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedDay == null || _selectedTime == null || _isBooking)
                      ? null
                      : () {
                          _bookAppointment();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isBooking 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Confirm Appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Booking Successful"),
        content: Text("Your appointment with ${widget.doctor['name']} has been scheduled for ${_selectedDay.toString().split(' ')[0]}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Great!")),
        ],
      ),
    );
  }
}

const accentBlue = Color(0xFF1976D2);
