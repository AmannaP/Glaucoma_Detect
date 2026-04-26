import 'package:flutter/material.dart';
import 'signup.dart';
import '../main.dart'; // To get MainNavigationHolder
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=login'),
        body: json.encode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html>')) {
        throw Exception("Server returned an error page (HTML). Please check if the backend URL is correct and the database is set up.");
      }
      
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user']['id']);
        await prefs.setString('user_name', data['user']['full_name']);
        await prefs.setString('user_email', data['user']['email']);
        String userRole = (data['user']['role'] ?? 'patient').toString().trim().toLowerCase();
        
        // HACK: Since the live backend currently omits the 'role' column in the JSON response,
        // we fallback to checking if the user's name starts with "Dr."
        String fullName = (data['user']['full_name'] ?? '').toString().trim();
        if (userRole == 'patient' && fullName.toLowerCase().startsWith('dr.')) {
          userRole = 'doctor';
        }

        await prefs.setString('user_role', userRole);
        print("Logged in as: $userRole"); // Debug role

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Login successful. Role: $userRole", style: const TextStyle(color: Colors.black)),
            backgroundColor: const Color(0xFF00C853),
            duration: const Duration(seconds: 2),
          ));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainNavigationHolder(initialRole: userRole)),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailResetController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool emailVerified = false;
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131C24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              emailVerified ? "Reset Password" : "Forgot Password",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!emailVerified) ...[
                  const Text("Enter your registered email to reset your password.", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailResetController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Email address",
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF00C853)),
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ] else ...[
                  const Text("Enter your new password below.", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "New Password",
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF00C853)),
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
              ),
              if (isResetting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C853))),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (!emailVerified) {
                      // Step 1: Check Email
                      if (emailResetController.text.isEmpty) return;
                      setDialogState(() => isResetting = true);
                      try {
                        final resp = await http.post(
                          Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=check_email'),
                          body: json.encode({"email": emailResetController.text.trim()}),
                        );
                        final data = json.decode(resp.body);
                        if (data['status'] == 'success') {
                          setDialogState(() {
                            emailVerified = true;
                            isResetting = false;
                          });
                        } else {
                          setDialogState(() => isResetting = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
                        }
                      } catch (e) {
                        setDialogState(() => isResetting = false);
                      }
                    } else {
                      // Step 2: Reset Password
                      if (newPasswordController.text.isEmpty) return;
                      setDialogState(() => isResetting = true);
                      try {
                        final resp = await http.post(
                          Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=reset_password'),
                          body: json.encode({
                            "email": emailResetController.text.trim(),
                            "new_password": newPasswordController.text.trim()
                          }),
                        );
                        final data = json.decode(resp.body);
                        if (data['status'] == 'success') {
                          if (mounted) Navigator.pop(ctx);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successfully!"), backgroundColor: Color(0xFF00C853)));
                        } else {
                          setDialogState(() => isResetting = false);
                        }
                      } catch (e) {
                        setDialogState(() => isResetting = false);
                      }
                    }
                  },
                  child: Text(emailVerified ? "Reset" : "Verify Email", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00C853);
    const Color cardBg = Color(0xFF131C24);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo and Brand Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryGreen, width: 2),
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Glaucoma Detect',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'serif', 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome back! Please enter your details.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 20),
              
              // Email Field
              _buildTextField(
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                controller: _emailController,
                cardBg: cardBg,
                primaryColor: primaryGreen,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!value.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureText,
                controller: _passwordController,
                onTogglePassword: () {
                  setState(() => _obscureText = !_obscureText);
                },
                cardBg: cardBg,
                primaryColor: primaryGreen,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.white60),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40), // Increased padding
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    required TextEditingController controller,
    required Color cardBg,
    required Color primaryColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && obscureText,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white30),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white30,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color bg) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }
}
