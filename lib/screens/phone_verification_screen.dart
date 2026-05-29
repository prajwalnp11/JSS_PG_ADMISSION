import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'form_wizard_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  
  // Timer for OTP Resend
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.sendOtp(phone);
      setState(() {
        _isLoading = false;
      });

      if (res['status'] == 'success') {
        setState(() {
          _isOtpSent = true;
        });
        _startTimer();
        
        // Show mock OTP code in a SnackBar for easier developer testing
        final devCode = res['otp'];
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully! [Dev Mock Code: $devCode or 123456]'),
            backgroundColor: const Color(0xFF0D47A1),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Copy Code',
              textColor: Colors.amber,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: devCode ?? ''));
              },
            ),
          ),
        );
      } else {
        _showError(res['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Connection error: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.verifyOtp(phone, otp);
      setState(() {
        _isLoading = false;
      });

      if (res['status'] == 'success') {
        _timer?.cancel();
        
        // Navigate to the form and pass verified number
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FormWizardScreen(verifiedMobileNumber: phone),
          ),
        );
      } else {
        _showError(res['message'] ?? 'Incorrect OTP code.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Connection error: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mobile Verification',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background details
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                
                // Form Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isOtpSent ? Icons.sms_outlined : Icons.phone_android_outlined,
                                  color: const Color(0xFF0D47A1),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                _isOtpSent ? "Enter OTP Code" : "Verification Required",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          if (!_isOtpSent) ...[
                            const Text(
                              "To start your PG Admission Form, please verify your mobile number first. We will send a 6-digit OTP code to this number.",
                              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            
                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                labelText: "10-Digit Mobile Number *",
                                hintText: "Enter mobile number",
                                prefixText: "+91 ",
                                prefixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Mobile number is required";
                                }
                                if (val.trim().length < 10) {
                                  return "Please enter a valid 10-digit number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Center(
                                child: Text(
                                  "Send OTP Code",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              "Enter the 6-digit code sent to +91 ${_phoneController.text}.",
                              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            
                            // OTP input field
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 12.0,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              decoration: InputDecoration(
                                hintText: "000000",
                                hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 10),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Center(
                                child: Text(
                                  "Verify & Proceed",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Resend timer and button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _canResend && !_isLoading ? _sendOtp : null,
                                  child: Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                      color: _canResend ? const Color(0xFF0D47A1) : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!_canResend)
                                  Text(
                                    "Resend in ${_secondsRemaining.toString().padLeft(2, '0')}s",
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                });
                              },
                              icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0D47A1)),
                              label: const Text(
                                "Change Phone Number",
                                style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
