import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_pages.dart'; 

class CandidateDashboard extends StatefulWidget {
  final String userEmail;
  const CandidateDashboard({super.key, required this.userEmail});

  @override
  _CandidateDashboardState createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  List _jobs = [];
  Set<int> _selectedJobIds = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final res = await http.get(Uri.parse("http://192.168.0.167:5000/get_jobs"));
      if (res.statusCode == 200) setState(() => _jobs = jsonDecode(res.body));
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _handleBulkApply() async {
    if (_selectedJobIds.isEmpty) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isProcessing = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse("http://192.168.0.167:5000/apply_bulk"));
        request.files.add(http.MultipartFile.fromBytes(
          'resume',
          result.files.single.bytes!,
          filename: result.files.single.name,
        ));
        request.fields['email'] = widget.userEmail;
        request.fields['job_ids'] = jsonEncode(_selectedJobIds.toList());

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Applied! Check your email."), backgroundColor: Colors.green),
          );
          setState(() => _selectedJobIds.clear());
        } else {
          _showError("Server Error! Status: ${response.statusCode}");
        }
      } catch (e) {
        _showError("Connection Failed!");
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  } 

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Jobs"),
        backgroundColor: Colors.teal,
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
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return CheckboxListTile(
                  title: Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${job['location']} | Exp: ${job['experience']} yrs"),
                  value: _selectedJobIds.contains(job['id']),
                  onChanged: (val) {
                    setState(() {
                      val! ? _selectedJobIds.add(job['id']) : _selectedJobIds.remove(job['id']);
                    });
                  },
                );
              },
            ),
          ),
          if (_selectedJobIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(15),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleBulkApply,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                ),
                child: Text(_isProcessing ? "Processing Resume..." : "Apply for ${_selectedJobIds.length} Jobs"),
              ),
            ),
        ],
      ),
    );
  }
}