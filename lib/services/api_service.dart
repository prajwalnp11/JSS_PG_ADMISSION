import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admission_form.dart';
class ApiService {
  // Replace this URL with your real Google Apps Script web app URL after deployment.
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbzrPkxDp0Q69IlBWpLvSEZAKtiacSdVo7ch9l1JeLi8P7--9hu_jj_PYqul6vH4WGYr/exec';

  /// Requests an OTP for an email address from the Google Apps Script backend.
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    if (apiUrl.isEmpty) {
      return {
        'status': 'error',
        'message': 'API URL is not configured. Please contact the administrator.'
      };
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'sendOtp',
          'email': email,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Failed to send OTP. Server responded with status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network connection failed: ${e.toString()}'
      };
    }
  }

  /// Verifies the OTP for an email address with the Google Apps Script backend.
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    if (apiUrl.isEmpty) {
      return {
        'status': 'error',
        'message': 'API URL is not configured. Please contact the administrator.'
      };
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'verifyOtp',
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Verification failed. Server responded with status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network connection failed: ${e.toString()}'
      };
    }
  }

  /// Submits the PG admission form to the Google Apps Script backend.
  static Future<Map<String, dynamic>> submitApplication(AdmissionFormModel form) async {
    final payload = form.toJson();

    if (apiUrl.isEmpty) {
      return {
        'status': 'error',
        'message': 'API URL is not configured. Please contact the administrator.'
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

  /// Fetches all applications from Google Sheets.
  static Future<Map<String, dynamic>> fetchApplications() async {
    if (apiUrl.isEmpty) {
      return {
        'status': 'error',
        'message': 'API URL is not configured. Please contact the administrator.'
      };
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'fetchApplications',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Failed to fetch applications. Server status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network connection failed: ${e.toString()}'
      };
    }
  }

  /// Updates an application's review status (Approved/Rejected) and sends automated notifications.
  static Future<Map<String, dynamic>> updateApplicationStatus(String appId, String status) async {
    if (apiUrl.isEmpty) {
      return {
        'status': 'error',
        'message': 'API URL is not configured. Please contact the administrator.'
      };
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'updateStatus',
          'appId': appId,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update application status. Server status code: ${response.statusCode}'
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
