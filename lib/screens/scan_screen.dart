import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; 

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? controller;
  bool isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      controller = CameraController(cameras[0], ResolutionPreset.high);
      controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      }).catchError((e) {
        print("Camera initialization error: $e");
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage(XFile image) async {
    setState(() {
      isAnalyzing = true;
    });

    try {
      // MOCK AI LOGIC
      await Future.delayed(const Duration(seconds: 3)); // simulate processing
      
      final random = Random();
      final isEye = random.nextDouble() > 0.1; // 90% chance it is recognized as an eye
      
      if (!isEye) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image is not recognized as an eye. Please retake.')));
        }
        return;
      }

      final hasGlaucoma = random.nextBool();
      final types = ["Open-angle", "Angle-closure", "Normal-tension"];
      final type = hasGlaucoma ? types[random.nextInt(types.length)] : "None";

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? historyString = prefs.getString('scan_history');
      List<dynamic> history = historyString != null ? json.decode(historyString) : [];
      
      history.add({
        "date": DateTime.now().toIso8601String().split('T')[0],
        "has_glaucoma": hasGlaucoma,
        "glaucoma_type": type,
        "image_path": image.path,
      });
      await prefs.setString('scan_history', json.encode(history));

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF131C24),
            title: Text(hasGlaucoma ? 'Glaucoma Risk Detected' : 'Healthy Eye', style: TextStyle(color: hasGlaucoma ? Colors.redAccent : Colors.greenAccent)),
            content: Text(hasGlaucoma ? 'Type: $type\n\nPlease visit a recommended ophthalmologist.' : 'No major signs of glaucoma detected.', style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Color(0xFF00CED1))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error analyzing image.')));
      }
    } finally {
      setState(() {
        isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CameraPreview(controller!),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FloatingActionButton.large(
                onPressed: isAnalyzing ? null : () async {
                  try {
                    final image = await controller!.takePicture();
                    await _analyzeImage(image);
                  } catch (e) {
                    print("Error taking picture: $e");
                  }
                },
                backgroundColor: isAnalyzing ? Colors.grey : const Color(0xFF006400),
                child: const Icon(Icons.camera_alt, size: 40, color: Colors.white),
              ),
            ),
          ],
        ),
        if (isAnalyzing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF006400)),
                  SizedBox(height: 16),
                  Text("Analyzing picture through AI model...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
