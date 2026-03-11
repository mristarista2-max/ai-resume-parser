import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_pages.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AdminHome(),
    PostJobScreen(),
    ManageJobsScreen(),
    ReviewApplications(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Console", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        // admin_dash.dart
actions: [
  IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), 
        (route) => false,
      );
    },
  )
],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Overview"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Post Job"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Manage"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Review"),
        ],
      ),
    );
  }
}

// --- 1. OVERVIEW SCREEN ---
class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int totalJobs = 0;
  int totalApplicants = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await http.get(Uri.parse("http://192.168.0.167:5000/get_stats"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          totalJobs = data['total_jobs'];
          totalApplicants = data['total_applicants'];
        });
      }
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome Admin,", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            children: [
              _statCard("Total Jobs", totalJobs.toString(), Colors.orange),
              _statCard("Applicants", totalApplicants.toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String count, Color color) {
    return Expanded(
      child: Card(
        color: color,
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(count, style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. POST JOB SCREEN ---
class PostJobScreen extends StatefulWidget {
  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _skills = TextEditingController();
  final _loc = TextEditingController();
  int _exp = 0;
  double _threshold = 70;

  Future<void> _submitJob() async {
  // 1. Mandatory fields check cheyyunnu
  if (_title.text.isEmpty || _skills.text.isEmpty || _loc.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All fields are required!"), backgroundColor: Colors.orange),
    );
    return;
  }

  try {
    final res = await http.post(
      Uri.parse("http://192.168.0.167:5000/add_job"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": _title.text.trim(),
        "skills": _skills.text.trim(),
        "experience": _exp,
        "location": _loc.text.trim(),
        "threshold": _threshold.toInt(),
      }),
    );

    if (res.statusCode == 201) {
      // 2. Success message kaanikkan (SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job Posted Successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 3. Ellaa fields-um clear aakkunnu
      setState(() {
        _title.clear();
        _skills.clear();
        _loc.clear();
        _exp = 0; // Dropdown reset
        _threshold = 70.0; // Slider reset
      });
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to post job!"), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Connection Error!"), backgroundColor: Colors.red),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: _title, decoration: InputDecoration(labelText: "Job Title", border: OutlineInputBorder())),
          SizedBox(height: 10),
          TextField(controller: _skills, decoration: InputDecoration(labelText: "Skills (comma separated)", border: OutlineInputBorder())),
          SizedBox(height: 10),
          TextField(controller: _loc, decoration: InputDecoration(labelText: "Location", border: OutlineInputBorder())),
          SizedBox(height: 15),
          DropdownButtonFormField<int>(
            value: _exp,
            decoration: InputDecoration(labelText: "Min Experience (Years)", border: OutlineInputBorder()),
            items: [0, 1, 2, 3, 4, 5, 10].map((e) => DropdownMenuItem(value: e, child: Text("$e Years"))).toList(),
            onChanged: (v) => setState(() => _exp = v!),
          ),
          SizedBox(height: 25),
          Text("Selection Threshold Score: ${_threshold.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _threshold,
            min: 0, max: 100, activeColor: Colors.indigo,
            onChanged: (v) => setState(() => _threshold = v),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitJob, 
            child: Text("PUBLISH JOB", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }
}

// --- 3. MANAGE JOBS SCREEN (Edit / Delete) ---
class ManageJobsScreen extends StatefulWidget {
  @override
  _ManageJobsScreenState createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> {
  List _jobs = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchJobs(); }

  Future<void> _fetchJobs() async {
    try {
      final res = await http.get(Uri.parse("http://192.168.0.167:5000/get_jobs"));
      if (res.statusCode == 200) setState(() { _jobs = jsonDecode(res.body); _isLoading = false; });
    } catch (e) { print(e); }
  }

  Future<void> _deleteJob(int id) async {
    await http.delete(Uri.parse("http://192.168.0.167:5000/delete_job/$id"));
    _fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    return _jobs.isEmpty ? Center(child: Text("No jobs found")) : ListView.builder(
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return Card(
          margin: EdgeInsets.all(10),
          child: ListTile(
            title: Text(job['title'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${job['location']} | Exp: ${job['experience']} yrs"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteJob(job['id'])),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- 4. REVIEW APPLICATIONS SCREEN (Updated) ---
class ReviewApplications extends StatefulWidget {
  @override
  _ReviewApplicationsState createState() => _ReviewApplicationsState();
}

class _ReviewApplicationsState extends State<ReviewApplications> {
  List _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      
      final res = await http.get(Uri.parse("http://192.168.0.167:5000/get_applications"));
      if (res.statusCode == 200) {
        setState(() {
          _applications = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Flutter Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey),
            Text("No applications found in Database."),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        bool isShortlisted = app['status'] == "Shortlisted";

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isShortlisted ? Colors.green : Colors.redAccent,
              child: Text("${app['score']}%", style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
            title: Text(app['email'] ?? "No Email", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text("Job: ${app['job']}"),
            trailing: Chip(
              label: Text(app['status'], style: const TextStyle(fontSize: 11)),
              backgroundColor: isShortlisted ? Colors.green.shade100 : Colors.red.shade100,
            ),
          ),
        );
      },
    );
  }
}