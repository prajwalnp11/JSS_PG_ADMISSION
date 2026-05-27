import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admission_form.dart';

class ApiService {
  // Replace this URL with your real Google Apps Script web app URL after deployment.
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbzIwjlL6o3ENpEqeNPPguyWgI5uRYrH8jZ_jWzx60uz2MR5nzpCsFJUX7lMfEPxMaj6Rg/exec';

  /// Submits the PG admission form to the Google Apps Script backend.
  /// 
  /// If the URL is not configured, it will simulate a successful submission
  /// and output the generated JSON payload to the developer console for debugging.
  static Future<Map<String, dynamic>> submitApplication(AdmissionFormModel form) async {
    final payload = form.toJson();

    if (apiUrl == 'YOUR_GOOGLE_APPS_SCRIPT_URL_HERE' || apiUrl.isEmpty) {
      // Simulate network request delay
      await Future.delayed(const Duration(seconds: 3));
      
      // Log the payload to console so the developer can see the structure
      print("--- JSS ADMISSION FORM SUBMISSION PAYLOAD ---");
      print(jsonEncode(payload));
      print("---------------------------------------------");

      // Generate a mock application ID
      final timestamp = DateTime.now();
      final mockAppId = "JSS-MOCK-${timestamp.year}-${1000 + (timestamp.millisecondsSinceEpoch % 9000)}";

      return {
        'status': 'success',
        'applicationId': mockAppId,
        'message': 'Mock Submission Successful! (Please configure your Apps Script URL in api_service.dart for live submission)'
      };
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'text/plain',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(minutes: 3)); // File uploads might take time, give a generous timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': 'Server responded with status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network connection failed: ${e.toString()}'
      };
    }
  }
}
