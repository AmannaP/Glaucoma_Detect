import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prescription_form.dart';
import '../main.dart'; // To access the cameras list

class VideoCallScreen extends StatefulWidget {
  final String remoteName;
  final bool isIncoming;

  const VideoCallScreen({super.key, required this.remoteName, this.isIncoming = false});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _controller;
  bool _isMuted = false;
  bool _isVideoOff = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    if (!widget.isIncoming) {
      _startTimer();
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
      print("Camera initialization error: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
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
    _controller?.dispose();
    super.dispose();
  }

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
                    backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
                    child: const Icon(Icons.person, size: 100, color: Color(0xFF00C853)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.remoteName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isIncoming ? "Incoming Video Call..." : _formatTime(_secondsElapsed),
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
              child: _controller != null && _controller!.value.isInitialized && !_isVideoOff
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
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final role = prefs.getString('user_role') ?? 'patient';
                    
                    if (mounted) {
                      if (role == 'doctor') {
                        // Navigate to prescription form
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => PrescriptionFormScreen(
                              patientName: widget.remoteName,
                              patientEmail: "patient@glaucoma.com", // Simulated autofill
                            )
                          )
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                _buildCallAction(
                  icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                  color: _isVideoOff ? Colors.white24 : Colors.white12,
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
              ],
            ),
          ),

          // Accept/Decline (Only if incoming)
          if (widget.isIncoming && _secondsElapsed == 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Incoming Call", style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(widget.remoteName, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallAction(
                          icon: Icons.close,
                          color: Colors.red,
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildCallAction(
                          icon: Icons.videocam,
                          color: const Color(0xFF00C853),
                          onTap: () {
                            setState(() {
                              // Accept call
                            });
                            _startTimer();
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
