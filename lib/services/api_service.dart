import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admission_form.dart';
class ApiService {
  // Replace this URL with your real Google Apps Script web app URL after deployment.
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbyQ95NICBperPmKrQBdlyXmdBHdfJjxNo6GvqEAeb3aC4uwCviMGiLenaUyB1NrFJnE/exec';

  // In-memory store for mock OTPs during development
  static String? _mockOtp;

  /// Requests an OTP for an email address from the Google Apps Script backend.
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    if (apiUrl == 'YOUR_GOOGLE_APPS_SCRIPT_URL_HERE' || apiUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      _mockOtp = '123456';
      return {
        'status': 'success',
        'otp': _mockOtp,
        'message': 'Mock Mode: OTP is 123456.'
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
    if (apiUrl == 'YOUR_GOOGLE_APPS_SCRIPT_URL_HERE' || apiUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (otp == '123456') {
        return {
          'status': 'success',
          'message': 'Mock OTP verified successfully.'
        };
      } else {
        return {
          'status': 'error',
          'message': 'Invalid verification code. Please enter 123456 for testing.'
        };
      }
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

  // In-memory list to track mock application updates
  static List<Map<String, dynamic>>? _mockApplications;

  /// Fetches all applications from Google Sheets.
  static Future<Map<String, dynamic>> fetchApplications() async {
    if (apiUrl == 'YOUR_GOOGLE_APPS_SCRIPT_URL_HERE' || apiUrl.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      _initializeMockApplications();
      return {
        'status': 'success',
        'applications': List<Map<String, dynamic>>.from(_mockApplications!)
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
    if (apiUrl == 'YOUR_GOOGLE_APPS_SCRIPT_URL_HERE' || apiUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      _initializeMockApplications();
      
      // Update in-memory mock data
      final index = _mockApplications!.indexWhere((a) => a['Application ID'] == appId);
      if (index != -1) {
        _mockApplications![index]['Status'] = status;
        return {
          'status': 'success',
          'message': 'Mock Status updated successfully to $status for $appId.'
        };
      } else {
        return {
          'status': 'error',
          'message': 'Mock Application ID not found: $appId'
        };
      }
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

  static void _initializeMockApplications() {
    if (_mockApplications != null) return;
    _mockApplications = [
      {
        'Application ID': 'JSS-PG-2026-1001',
        'Timestamp': '2026-06-02T10:00:00.000Z',
        'Course Selected': 'MCA',
        'Student Name': 'Rohan Kumar',
        'Parents Name': 'Suresh Kumar & Meena Kumar',
        'Date of Birth': '2004-05-15',
        'Place of Birth': 'Mysuru',
        'Nationality': 'Indian',
        'Religion': 'Hindu',
        'Caste': 'General',
        'Sex': 'Male',
        'Mother Tongue': 'Kannada',
        'Present Address': '123, 4th Cross, Gokulam, Mysuru - 570002',
        'Permanent Address': '123, 4th Cross, Gokulam, Mysuru - 570002',
        'Aadhaar Number': '123456789012',
        'Phone Number': '+919876543210',
        'Mobile Number': '+919876543210',
        'Email': 'rohan.kumar@gmail.com',
        'Last Attended Institution': 'JSS College, Ooty Road',
        'Subjects Studied': 'BSc (Computer Science, Physics, Mathematics)',
        'Sem 1 Total': 600.0, 'Sem 1 Secured': 480.0, 'Sem 1 Pct': 80.0,
        'Sem 2 Total': 600.0, 'Sem 2 Secured': 510.0, 'Sem 2 Pct': 85.0,
        'Sem 3 Total': 600.0, 'Sem 3 Secured': 495.0, 'Sem 3 Pct': 82.5,
        'Sem 4 Total': 600.0, 'Sem 4 Secured': 520.0, 'Sem 4 Pct': 86.67,
        'Sem 5 Total': 600.0, 'Sem 5 Secured': 530.0, 'Sem 5 Pct': 88.33,
        'Sem 6 Total': 600.0, 'Sem 6 Secured': 540.0, 'Sem 6 Pct': 90.0,
        'Grand Total Marks': 3600.0, 'Grand Secured Marks': 3075.0, 'Grand Percentage': 85.42,
        'Category Claimed': 'GM',
        'Parents Occupation': 'Business',
        'Parents Annual Income': '5,00,000',
        'Photo URL': 'https://drive.google.com/open?id=123',
        'Marks Cards URL': 'https://drive.google.com/open?id=456',
        'Character Certificate URL': 'https://drive.google.com/open?id=789',
        'SSLC PUC Certificate URL': 'https://drive.google.com/open?id=abc',
        'Income Certificate URL': 'https://drive.google.com/open?id=def',
        'Caste Certificate URL': 'https://drive.google.com/open?id=ghi',
        'Transfer Certificate URL': 'https://drive.google.com/open?id=jkl',
        'Aadhaar Card URL': 'https://drive.google.com/open?id=mno',
        'SBI Collect Ref No': 'DU12345678',
        'Payment Date': '2026-06-01',
        'Payment Receipt URL': 'https://drive.google.com/open?id=pqr',
        'Status': 'Pending'
      },
      {
        'Application ID': 'JSS-PG-2026-1002',
        'Timestamp': '2026-06-02T11:15:00.000Z',
        'Course Selected': 'MSc Computer Science',
        'Student Name': 'Ananya R',
        'Parents Name': 'Ramachandra & Shanti',
        'Date of Birth': '2004-08-22',
        'Place of Birth': 'Bengaluru',
        'Nationality': 'Indian',
        'Religion': 'Hindu',
        'Caste': 'OBC - Cat 2A',
        'Sex': 'Female',
        'Mother Tongue': 'Kannada',
        'Present Address': '45, 2nd Main, Vijayanagar, Bengaluru - 560040',
        'Permanent Address': '45, 2nd Main, Vijayanagar, Bengaluru - 560040',
        'Aadhaar Number': '987654321098',
        'Phone Number': '+918765432109',
        'Mobile Number': '+918765432109',
        'Email': 'ananya.r@gmail.com',
        'Last Attended Institution': 'PES University, Bengaluru',
        'Subjects Studied': 'BCA (Computer Applications)',
        'Sem 1 Total': 700.0, 'Sem 1 Secured': 610.0, 'Sem 1 Pct': 87.14,
        'Sem 2 Total': 700.0, 'Sem 2 Secured': 630.0, 'Sem 2 Pct': 90.0,
        'Sem 3 Total': 700.0, 'Sem 3 Secured': 595.0, 'Sem 3 Pct': 85.0,
        'Sem 4 Total': 700.0, 'Sem 4 Secured': 640.0, 'Sem 4 Pct': 91.43,
        'Sem 5 Total': 700.0, 'Sem 5 Secured': 650.0, 'Sem 5 Pct': 92.86,
        'Sem 6 Total': 700.0, 'Sem 6 Secured': 665.0, 'Sem 6 Pct': 95.0,
        'Grand Total Marks': 4200.0, 'Grand Secured Marks': 3790.0, 'Grand Percentage': 90.24,
        'Category Claimed': 'IIA',
        'Parents Occupation': 'Government Employee',
        'Parents Annual Income': '7,50,000',
        'Photo URL': 'https://drive.google.com/open?id=aaa',
        'Marks Cards URL': 'https://drive.google.com/open?id=bbb',
        'Character Certificate URL': 'https://drive.google.com/open?id=ccc',
        'SSLC PUC Certificate URL': 'https://drive.google.com/open?id=ddd',
        'Income Certificate URL': 'https://drive.google.com/open?id=eee',
        'Caste Certificate URL': 'https://drive.google.com/open?id=fff',
        'Transfer Certificate URL': 'https://drive.google.com/open?id=ggg',
        'Aadhaar Card URL': 'https://drive.google.com/open?id=hhh',
        'SBI Collect Ref No': 'DU87654321',
        'Payment Date': '2026-06-02',
        'Payment Receipt URL': 'https://drive.google.com/open?id=iii',
        'Status': 'Approved'
      }
    ];
  }
}
