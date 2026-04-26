import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; 
import 'scan_detail.dart';
import '../services/notification_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? controller;
  bool isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  int _cameraIndex = 0; // 0 for back, 1 for front

  void _initializeCamera() {
    if (cameras.isNotEmpty) {
      // Ensure we don't go out of bounds if only one camera exists
      int index = _cameraIndex < cameras.length ? _cameraIndex : 0;
      controller = CameraController(cameras[index], ResolutionPreset.high);
      controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      }).catchError((e) {
        print("Camera initialization error: $e");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    controller?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _analyzeImage(image);
    }
  }

  Future<void> _analyzeImage(XFile image) async {
    setState(() {
      isAnalyzing = true;
    });

    int retryCount = 0;
    const int maxRetries = 2;

    Future<void> performAnalysis() async {
      try {
        final backendUrl = 'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/detect.php';
        var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
        
        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          
          if (result['status'] == 'success') {
            final prefs = await SharedPreferences.getInstance();
            final String? historyString = prefs.getString('scan_history');
            List<dynamic> history = historyString != null ? json.decode(historyString) : [];
            
            final scanData = {
              "date": DateTime.now().toIso8601String().split('T')[0],
              "has_glaucoma": result['prediction'] == "Glaucoma Detected",
              "glaucoma_type": result['glaucoma_type'],
              "risk_score": result['risk_score'],
              "image_path": image.path,
            };
            
            history.add(scanData);
            await prefs.setString('scan_history', json.encode(history));

            // Add real notification
            await NotificationService.addNotification(
              title: "New Scan Result",
              body: "Your eye scan analysis is complete. Result: ${result['prediction']}",
              type: "alert"
            );

            if (mounted) {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => ScanDetailScreen(scanData: scanData))
              );
            }
          } else {
            throw Exception(result['message'] ?? 'Detection failed');
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          print("Retrying analysis ($retryCount/$maxRetries)...");
          await performAnalysis();
        } else {
          rethrow;
        }
      }
    }

    try {
      await performAnalysis();
    } catch (e) {
      print("Analysis error: $e");
      if (mounted) {
        String errorMsg = e.toString().contains('TimeoutException') 
          ? "Connection timed out. Please check your internet and try again." 
          : "Scanning failed: ${e.toString()}";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: "Retry", 
              textColor: Colors.white,
              onPressed: () => _analyzeImage(image)
            ),
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Eye"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(controller!),
          ),
          
          // HUD Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Align your eye within the circle",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, size: 30, color: Colors.white),
                      onPressed: isAnalyzing ? null : _pickImage,
                    ),
                    GestureDetector(
                      onTap: isAnalyzing ? null : () async {
                        try {
                          final image = await controller!.takePicture();
                          await _analyzeImage(image);
                        } catch (e) {
                          print("Error taking picture: $e");
                        }
                      },
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _cameraIndex == 0 ? Icons.camera_front : Icons.camera_rear, 
                        size: 30, 
                        color: Colors.white
                      ),
                      onPressed: () {
                        if (cameras.length > 1) {
                          setState(() {
                            _cameraIndex = _cameraIndex == 0 ? 1 : 0;
                          });
                          controller?.dispose();
                          _initializeCamera();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Only one camera available'))
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Analyzing image with AI...",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width * 0.35));

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(Path.combine(PathOperation.difference, fullPath, circlePath), paint);

    final borderPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.35, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
