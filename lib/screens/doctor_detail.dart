import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

            // Book Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _selectedDay == null
                      ? null
                      : () {
                          _showBookingConfirmation();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Confirm Appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
