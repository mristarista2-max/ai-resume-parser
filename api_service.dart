import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Emulator or your Laptop IP for Real Device
  static const String baseUrl = "http://192.168.0.167:5000";

  static Future<Map<String, dynamic>> uploadResume(String path, String job, String skills) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/parse'));
    request.files.add(await http.MultipartFile.fromPath('resume', path));
    request.fields['job_title'] = job;
    request.fields['skills'] = skills;

    var response = await request.send();
    var resData = await http.Response.fromStream(response);
    return json.decode(resData.body);
  }
}