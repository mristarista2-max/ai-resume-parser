import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      return const Center(child: Text("No applications found in DB."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        // to check shortlist
        bool isShortlisted = app['status'] == "Shortlisted";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isShortlisted ? Colors.green : Colors.redAccent,
              child: Text("${app['score']}%", style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
            // show email
            title: Text(app['email'] ?? "No Email", style: const TextStyle(fontWeight: FontWeight.bold)),
            
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