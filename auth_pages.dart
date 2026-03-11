import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'candidate_dash.dart'; 
import 'admin_dash.dart'; 

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _showMsg("Please fill all fields", Colors.orange);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse("http://192.168.0.167:5000//login"), 
        headers: {"Content-Type": "application/json",
        "Accept": "application/json"},
        body: jsonEncode({"email": _email.text.trim(), "password": _pass.text}),
      );
      setState(() => _loading = false);
      if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    String role = data['role'];
    if (role == 'Admin') {
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(builder: (c) => AdminDashboard()) 
  );
} else {
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(
      builder: (c) => CandidateDashboard(userEmail: _email.text.trim()) 
    )
  );
}
} else {
        _showMsg("Invalid Email or Password", Colors.red);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showMsg("Server Connection Error!", Colors.red);
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.psychology_outlined, size: 100, color: Colors.indigo), 
              const SizedBox(height: 10),
              Text("AI Resume Pro", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text("Login to your account", style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 40),
              _buildField("Email", _email, Icons.email_outlined, false),
              const SizedBox(height: 15),
              _buildField("Password", _pass, Icons.lock_outline, true),
              const SizedBox(height: 30),
              _loading ? const CircularProgressIndicator() : SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _login, 
                  child: Text("LOGIN", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18))
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpPage())), child: Text("Don't have an account? Sign Up", style: GoogleFonts.poppins())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, IconData icon, bool hide) {
    return TextField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigo),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- SIGN UP PAGE WITH ALL FIELDS ---
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  String _role = 'Candidate';
  bool _loading = false;

  Future<void> _register() async {

    if (_name.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) {
    _showMsg("Please fill all fields", Colors.orange);
    return;
  }

    if (_pass.text != _confirmPass.text) {
      _showMsg("Passwords do not match!", Colors.red);
      return;
    }
    setState(() => _loading = true);
    try {
    final res = await http.post(
      Uri.parse("http://192.168.0.167:5000/signup"), 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _name.text.trim(),
        "email": _email.text.trim(),
        "password": _pass.text,
        "role": _role
      }),
    );
    setState(() => _loading = false);
    if (res.statusCode == 201) {
      _showMsg("Account created! Please login", Colors.green);
      Navigator.pop(context); 
    } else {
      
      final errorMsg = jsonDecode(res.body)['message'];
      _showMsg(errorMsg ?? "Registration Failed", Colors.red);
    }
  } catch (e) {
    setState(() => _loading = false); 
    _showMsg("Connection Error!", Colors.red);
    print("Signup Error: $e");
  }
}

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Account", style: GoogleFonts.poppins())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            _signupField("Full Name", _name, Icons.person_outline, false), // username
            const SizedBox(height: 15),
            _signupField("Email", _email, Icons.email_outlined, false), // email
            const SizedBox(height: 15),
            _signupField("Password", _pass, Icons.lock_outline, true), // password
            const SizedBox(height: 15),
            _signupField("Confirm Password", _confirmPass, Icons.lock_reset, true), // confirm password
            const SizedBox(height: 20),
            Row(
              children: [
                Text("Select Role: ", style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _role,
                  items: ["Candidate", "Admin"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), // role (Admin/Candidate)
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _loading ? const CircularProgressIndicator() : SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _register, 
                child: Text("SIGN UP", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signupField(String hint, TextEditingController controller, IconData icon, bool hide) {
    return TextField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigo),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}