import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prescription_form.dart';
import '../services/notification_service.dart';
import '../main.dart'; // To access the cameras list

class VideoCallScreen extends StatefulWidget {
  final String remoteName;
  final bool isIncoming;
  final int? appointmentId; // used to update status when patient marks complete

  const VideoCallScreen({
    super.key,
    required this.remoteName,
    this.isIncoming = false,
    this.appointmentId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _controller;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _callStarted = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    if (!widget.isIncoming) {
      _sendSignal("[CALL_REQUEST]"); // Notify receiver
      _startCallWaitPoller(); // Caller waits for acceptance
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _signalingPoller?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // Signaling Logic
  // ─────────────────────────────────────────────────────────

  Timer? _signalingPoller;

  void _startCallWaitPoller() {
    _signalingPoller = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkCallResponse();
    });
  }

  Future<void> _checkCallResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final url = Uri.parse(
        'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/messages.php?action=fetch&user_id=$userId&other_name=${Uri.encodeComponent(widget.remoteName)}'
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> messages = data['messages'] ?? [];
          if (messages.isEmpty) return;

          final latest = messages.last;
          final String content = latest['message'] ?? "";
          final int senderId = latest['sender_id'];

          if (senderId != userId) {
            if (content.startsWith("[CALL_ACCEPTED]")) {
              _signalingPoller?.cancel();
              setState(() {
                _callStarted = true;
                _startTimer();
              });
            } else if (content.startsWith("[CALL_DECLINED]")) {
              _signalingPoller?.cancel();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Call declined by user."), backgroundColor: Colors.red),
                );
                Navigator.pop(context);
              }
            }
          }
        }
      }
    } catch (e) { /* ignore */ }
  }

  Future<void> _sendSignal(String signal) async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');
    final String? otherName = widget.remoteName;
    if (userId == null || otherName == null) return;

    try {
      await http.post(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/messages.php?action=send'),
        body: json.encode({
          "sender_id": userId,
          "receiver_name": otherName,
          "message": signal,
        }),
      );
    } catch (e) { /* fail silent */ }
  }

  Future<void> _onEndCall() async {
    _timer?.cancel();
    _signalingPoller?.cancel();
    
    // Notify other end call ended
    await _sendSignal("[CALL_DECLINED]");

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'patient';

    if (role == 'doctor') {
      // Doctor ends call → go to prescription form
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PrescriptionFormScreen(
              patientName: widget.remoteName,
              patientEmail: "patient@glaucoma.com",
            ),
          ),
        );
      }
    } else {
      // Patient ends call → ask if consultation was completed
      if (mounted) {
        _showCompletionDialog();
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Consultation Complete?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Was the consultation with your doctor completed successfully?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // No — leave as pending so patient can chat to reschedule
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // close video call
            },
            child: const Text("No, Extend",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          // Yes — update status to 'completed' on backend
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _markCompleted();
            },
            child: const Text("Yes, Completed",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _markCompleted() async {
    if (widget.appointmentId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/appointments.php?action=update_status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': widget.appointmentId, 'status': 'completed'}),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        await NotificationService.addNotification(
          title: '✅ Consultation Completed',
          body:
              'Your consultation with ${widget.remoteName} has been marked as completed.',
          type: 'info',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Consultation marked as completed!"),
              backgroundColor: Color(0xFF00C853),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Remote Video (Background)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF131C24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: const Color(0xFF00C853).withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 100, color: Color(0xFF00C853)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.remoteName,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isIncoming && !_callStarted
                        ? "Incoming Video Call..."
                        : _formatTime(_secondsElapsed),
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Real Local Video (Small Overlay)
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _controller != null &&
                      _controller!.value.isInitialized &&
                      !_isVideoOff
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : const Center(
                      child: Icon(Icons.person, color: Colors.white24, size: 40),
                    ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallAction(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.white24 : Colors.white12,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _buildCallAction(
                  icon: Icons.call_end,
                  color: Colors.red,
                  iconColor: Colors.white,
                  size: 70,
                  onTap: _onEndCall,
                ),
                _buildCallAction(
                  icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                  color: _isVideoOff ? Colors.white24 : Colors.white12,
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
              ],
            ),
          ),

          // Accept/Decline (Only if incoming and call not yet started)
          if (widget.isIncoming && !_callStarted)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Incoming Call",
                        style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(widget.remoteName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallAction(
                          icon: Icons.close,
                          color: Colors.red,
                          onTap: () async {
                            await _sendSignal("[CALL_DECLINED]");
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                        _buildCallAction(
                          icon: Icons.videocam,
                          color: const Color(0xFF00C853),
                          onTap: () async {
                            await _sendSignal("[CALL_ACCEPTED]");
                            setState(() {
                              _callStarted = true;
                              _startTimer();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
