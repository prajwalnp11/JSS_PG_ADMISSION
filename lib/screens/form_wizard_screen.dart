import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/admission_form.dart';
import '../services/api_service.dart';

class FormWizardScreen extends StatefulWidget {
  const FormWizardScreen({super.key});

  @override
  State<FormWizardScreen> createState() => _FormWizardScreenState();
}

class _FormWizardScreenState extends State<FormWizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final AdmissionFormModel _formData = AdmissionFormModel();

  // Controllers for text fields
  final _nameCtrl = TextEditingController();
  final _parentsNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _placeOfBirthCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _casteCtrl = TextEditingController();
  final _motherTongueCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _lastInstCtrl = TextEditingController();
  final _parentOccCtrl = TextEditingController();
  final _parentIncomeCtrl = TextEditingController();
  final _payRefCtrl = TextEditingController();
  final _payDateCtrl = TextEditingController();
  final _signatureCtrl = TextEditingController();

  // List of subject controllers
  final List<TextEditingController> _subjectCtrls = List.generate(6, (_) => TextEditingController());

  // Marks Table Controllers
  final Map<String, Map<String, TextEditingController>> _marksCtrls = {};

  @override
  void initState() {
    super.initState();
    _initMarksControllers();
  }

  void _initMarksControllers() {
    final sems = ['sem1', 'sem2', 'sem3', 'sem4', 'sem5', 'sem6'];
    for (var sem in sems) {
      _marksCtrls[sem] = {
        'total': TextEditingController(text: ''),
        'secured': TextEditingController(text: ''),
      };
      
      // Add listeners to auto-calculate percentages and grand totals
      _marksCtrls[sem]!['total']!.addListener(() => _calculateSemMarks(sem));
      _marksCtrls[sem]!['secured']!.addListener(() => _calculateSemMarks(sem));
    }
  }

  void _calculateSemMarks(String semKey) {
    final totalStr = _marksCtrls[semKey]!['total']!.text;
    final securedStr = _marksCtrls[semKey]!['secured']!.text;

    final total = double.tryParse(totalStr) ?? 0.0;
    final secured = double.tryParse(securedStr) ?? 0.0;

    double percentage = 0.0;
    if (total > 0 && secured <= total) {
      percentage = (secured / total) * 100;
    }

    // Update form model values
    SemesterMarks semMarks;
    switch (semKey) {
      case 'sem1': semMarks = _formData.marks.sem1; break;
      case 'sem2': semMarks = _formData.marks.sem2; break;
      case 'sem3': semMarks = _formData.marks.sem3; break;
      case 'sem4': semMarks = _formData.marks.sem4; break;
      case 'sem5': semMarks = _formData.marks.sem5; break;
      case 'sem6': semMarks = _formData.marks.sem6; break;
      default: return;
    }
    
    semMarks.total = total;
    semMarks.secured = secured;
    semMarks.percentage = percentage;

    _calculateGrandTotal();
  }

  void _calculateGrandTotal() {
    double grandTotal = 0.0;
    double grandSecured = 0.0;

    final list = [
      _formData.marks.sem1,
      _formData.marks.sem2,
      _formData.marks.sem3,
      _formData.marks.sem4,
      _formData.marks.sem5,
      _formData.marks.sem6
    ];

    for (var sem in list) {
      grandTotal += sem.total;
      grandSecured += sem.secured;
    }

    double grandPercentage = 0.0;
    if (grandTotal > 0) {
      grandPercentage = (grandSecured / grandTotal) * 100;
    }

    setState(() {
      _formData.marks.grand.total = grandTotal;
      _formData.marks.grand.secured = grandSecured;
      _formData.marks.grand.percentage = grandPercentage;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _parentsNameCtrl.dispose();
    _dobCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    _religionCtrl.dispose();
    _casteCtrl.dispose();
    _motherTongueCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _aadhaarCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _lastInstCtrl.dispose();
    _parentOccCtrl.dispose();
    _parentIncomeCtrl.dispose();
    _payRefCtrl.dispose();
    _payDateCtrl.dispose();
    _signatureCtrl.dispose();
    for (var ctrl in _subjectCtrls) {
      ctrl.dispose();
    }
    _marksCtrls.forEach((key, map) {
      map['total']!.dispose();
      map['secured']!.dispose();
    });
    super.dispose();
  }

  // Auto fill mock data for quick testing
  void _fillMockData() {
    setState(() {
      _nameCtrl.text = "Prajwal N P";
      _parentsNameCtrl.text = "Prakash & Nirmala";
      _dobCtrl.text = "2003-05-15";
      _placeOfBirthCtrl.text = "Mysore";
      _religionCtrl.text = "Hindu";
      _casteCtrl.text = "General";
      _motherTongueCtrl.text = "Kannada";
      
      _presentAddressCtrl.text = "123, 4th Cross, Gokulam, Mysuru - 570002";
      _permanentAddressCtrl.text = "123, 4th Cross, Gokulam, Mysuru - 570002";
      
      _aadhaarCtrl.text = "564738291012";
      _phoneCtrl.text = "08212411234";
      _mobileCtrl.text = "9876543210";
      _emailCtrl.text = "prajwal.np@example.com";
      
      _lastInstCtrl.text = "JSS College of Arts, Commerce and Science, Mysuru";
      _parentOccCtrl.text = "Agriculturist";
      _parentIncomeCtrl.text = "250000";

      // Subjects
      _subjectCtrls[0].text = "Mathematics";
      _subjectCtrls[1].text = "Computer Science";
      _subjectCtrls[2].text = "Physics";
      _subjectCtrls[3].text = "Electronics";
      _subjectCtrls[4].text = "English";
      _subjectCtrls[5].text = "Kannada";

      // Marks
      final sems = ['sem1', 'sem2', 'sem3', 'sem4', 'sem5', 'sem6'];
      for (var i = 0; i < sems.length; i++) {
        _marksCtrls[sems[i]]!['total']!.text = "600";
        _marksCtrls[sems[i]]!['secured']!.text = "${450 + (i * 10)}"; // 450, 460, 470, etc.
      }

      _payRefCtrl.text = "DU84739201";
      _payDateCtrl.text = "2026-05-26";
      _signatureCtrl.text = "Prajwal N P";

      // Pick dummy base64 contents for files to pass validation
      final dummyBase64 = base64Encode(utf8.encode("dummy file contents"));
      _formData.files.forEach((key, value) {
        value.base64 = dummyBase64;
        value.fileName = "$key.pdf";
        value.mimeType = "application/pdf";
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mock Data Filled! Upload fields populated with placeholder files.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Opens date picker and sets controller text
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // 20 years ago default
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Choose file logic
  Future<void> _pickFile(String key) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final base64String = base64Encode(file.bytes!);
          
          setState(() {
            _formData.files[key] = FormFile(
              base64: base64String,
              fileName: file.name,
              mimeType: _getMimeType(file.extension ?? ''),
            );
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file.name} uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  // Validates current step
  bool _validateStep() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.isEmpty || _parentsNameCtrl.text.isEmpty || _dobCtrl.text.isEmpty) {
        _showValidationError("Please fill out Name, Parents Name, and Date of Birth");
        return false;
      }
    } else if (_currentStep == 1) {
      if (_presentAddressCtrl.text.isEmpty || _mobileCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
        _showValidationError("Address, Mobile, and Email are required");
        return false;
      }
      if (_aadhaarCtrl.text.length != 12) {
        _showValidationError("Aadhaar Number must be exactly 12 digits");
        return false;
      }
    } else if (_currentStep == 2) {
      if (_lastInstCtrl.text.isEmpty) {
        _showValidationError("Last attended institution is required");
        return false;
      }
      // Check if some marks are filled but total is missing
      final sems = ['sem1', 'sem2', 'sem3', 'sem4', 'sem5', 'sem6'];
      for (var sem in sems) {
        final t = double.tryParse(_marksCtrls[sem]!['total']!.text) ?? 0.0;
        final s = double.tryParse(_marksCtrls[sem]!['secured']!.text) ?? 0.0;
        if (s > t) {
          _showValidationError("Secured marks cannot exceed total marks in any semester");
          return false;
        }
      }
    } else if (_currentStep == 3) {
      // Validate mandatory file uploads: photo and marksCards
      if (!_formData.files['photo']!.isUploaded) {
        _showValidationError("Stamp Size Photo is mandatory");
        return false;
      }
      if (!_formData.files['marksCards']!.isUploaded) {
        _showValidationError("Marks Cards attachment is mandatory");
        return false;
      }
    } else if (_currentStep == 4) {
      if (_payRefCtrl.text.isEmpty || _payDateCtrl.text.isEmpty) {
        _showValidationError("SBI Collect Reference Number and Date of Payment are required");
        return false;
      }
      if (!_payRefCtrl.text.toUpperCase().startsWith("DU")) {
        _showValidationError("Reference number typically starts with 'DU' (SBI Collect)");
        return false;
      }
      if (!_formData.files['paymentReceipt']!.isUploaded) {
        _showValidationError("Payment Receipt upload is mandatory");
        return false;
      }
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Opens SBI Collect URL
  Future<void> _launchSBICollect() async {
    final Uri url = Uri.parse('https://onlinesbi.sbi.bank.in/sbicollect/icollecthome.htm');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SBI Collect portal.')),
      );
    }
  }

  // Prepares data and submits to backend
  Future<void> _submitForm() async {
    if (_signatureCtrl.text.isEmpty) {
      _showValidationError("Please sign the application by typing your name in the Signature field");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Populate model text data from controllers
    _formData.name = _nameCtrl.text;
    _formData.parentsName = _parentsNameCtrl.text;
    _formData.dob = _dobCtrl.text;
    _formData.placeOfBirth = _placeOfBirthCtrl.text;
    _formData.religion = _religionCtrl.text;
    _formData.caste = _casteCtrl.text;
    _formData.motherTongue = _motherTongueCtrl.text;
    _formData.presentAddress = _presentAddressCtrl.text;
    _formData.permanentAddress = _permanentAddressCtrl.text;
    _formData.aadhaarNo = _aadhaarCtrl.text;
    _formData.phoneNo = _phoneCtrl.text;
    _formData.mobileNo = _mobileCtrl.text;
    _formData.email = _emailCtrl.text;
    _formData.lastInstitution = _lastInstCtrl.text;
    
    _formData.subjectsStudied = _subjectCtrls.map((c) => c.text).toList();
    _formData.parentOccupation = _parentOccCtrl.text;
    _formData.parentAnnualIncome = _parentIncomeCtrl.text;
    
    _formData.payment.refNo = _payRefCtrl.text;
    _formData.payment.date = _payDateCtrl.text;

    final result = await ApiService.submitApplication(_formData);

    setState(() {
      _isSubmitting = false;
    });

    if (result['status'] == 'success') {
      _showSuccessDialog(result['applicationId'], result['message']);
    } else {
      _showErrorDialog(result['message']);
    }
  }

  void _showSuccessDialog(String appId, String serverMsg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 12),
              Text("Submission Successful", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your application has been received by JSS College."),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "APPLICATION NUMBER",
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      appId,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                serverMsg,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop form wizard back to dashboard
              },
              child: const Text("Go to Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 12),
              Text("Submission Failed", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Color(0xFF0D47A1))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PG Admission Form',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Developer Quick Fill Button
          TextButton.icon(
            onPressed: _fillMockData,
            icon: const Icon(Icons.flash_on, color: Colors.amber, size: 18),
            label: const Text(
              "Mock Data",
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0D47A1), // Stepper connector & circles
              ),
            ),
            child: Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                onStepContinue: () {
                  if (_validateStep()) {
                    if (_currentStep < 5) {
                      setState(() => _currentStep += 1);
                    } else {
                      _submitForm();
                    }
                  }
                },
                onStepTapped: (step) {
                  // Only allow jumping backward, require validations to move forward
                  if (step < _currentStep) {
                    setState(() => _currentStep = step);
                  }
                },
                controlsBuilder: (BuildContext context, ControlsDetails details) {
                  final isLastStep = _currentStep == 5;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isLastStep ? 'SUBMIT APPLICATION' : 'CONTINUE',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0D47A1)),
                                foregroundColor: const Color(0xFF0D47A1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('BACK', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  _buildStepPersonal(),
                  _buildStepContact(),
                  _buildStepAcademic(),
                  _buildStepDocuments(),
                  _buildStepPayment(),
                  _buildStepDeclaration(),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Submitting Application...",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Uploading files and recording details",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- STEP 1: Personal Info ---
  Step _buildStepPersonal() {
    return Step(
      title: const Text('Personal'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.editing,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Course & Personal Info"),
            
            // Program Selection
            DropdownButtonFormField<String>(
              initialValue: _formData.course,
              decoration: const InputDecoration(
                labelText: "Postgraduate Programme Selection *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: [
                'MCA', 'M.Sc Physics', 'M.Sc Chemistry', 'M.Sc Mathematics', 
                'M.Sc Computer Science', 'M.Sc Biochemistry', 'M.Sc Biotechnology', 
                'M.Sc Botany', 'M.Sc Zoology', 'M.A. in Kannada', 'M.A. in English', 
                'M.S.W', 'M.Com', 'M.Voc (Food Processing & Engineering)', 
                'M.Voc (Software Development)'
              ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) {
                setState(() => _formData.course = val ?? 'MCA');
              },
            ),
            const SizedBox(height: 16),

            // Student Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Name of the Applicant (In Block Letters) *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Parents Name
            TextFormField(
              controller: _parentsNameCtrl,
              decoration: const InputDecoration(
                labelText: "Father & Mother Name *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth & Gender
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobCtrl,
                    readOnly: true,
                    onTap: () => _selectDate(context, _dobCtrl),
                    decoration: const InputDecoration(
                      labelText: "Date of Birth *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _formData.sex,
                    decoration: const InputDecoration(
                      labelText: "Gender *",
                      border: OutlineInputBorder(),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _formData.sex = val ?? 'Male');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Place of birth & Nationality
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _placeOfBirthCtrl,
                    decoration: const InputDecoration(
                      labelText: "Place of Birth",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _formData.nationality,
                    decoration: const InputDecoration(
                      labelText: "Nationality *",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _formData.nationality = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Religion, Caste, Mother Tongue
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _religionCtrl,
                    decoration: const InputDecoration(
                      labelText: "Religion",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _casteCtrl,
                    decoration: const InputDecoration(
                      labelText: "Caste",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _motherTongueCtrl,
                    decoration: const InputDecoration(
                      labelText: "Mother Tongue",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: Address & Contact ---
  Step _buildStepContact() {
    return Step(
      title: const Text('Contact'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1
          ? StepState.complete
          : (_currentStep == 1 ? StepState.editing : StepState.indexed),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Contact & Communication Address"),
            
            // Present Address
            TextFormField(
              controller: _presentAddressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Present Address for Communication *",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 8),

            // Same as Present Address Checkbox
            CheckboxListTile(
              title: const Text("Permanent Address is same as Present Address", style: TextStyle(fontSize: 13)),
              value: _presentAddressCtrl.text == _permanentAddressCtrl.text && _presentAddressCtrl.text.isNotEmpty,
              activeColor: const Color(0xFF0D47A1),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                if (value == true) {
                  setState(() {
                    _permanentAddressCtrl.text = _presentAddressCtrl.text;
                  });
                }
              },
            ),

            // Permanent Address
            TextFormField(
              controller: _permanentAddressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Permanent Address *",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.home_work),
              ),
            ),
            const SizedBox(height: 16),

            // Aadhaar Card Number
            TextFormField(
              controller: _aadhaarCtrl,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: "Aadhaar Card Number *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fingerprint),
                counterText: "",
              ),
            ),
            const SizedBox(height: 16),

            // Mobile & Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Mobile Number *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Ph. No. (with Std Code)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-mail Address *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 3: Academic Records ---
  Step _buildStepAcademic() {
    return Step(
      title: const Text('Academic'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2
          ? StepState.complete
          : (_currentStep == 2 ? StepState.editing : StepState.indexed),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Academic Records"),
            
            // Last Attended Institution
            TextFormField(
              controller: _lastInstCtrl,
              decoration: const InputDecoration(
                labelText: "Institution & University Last Attended *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 16),

            // Subjects Studied (6 items)
            const Text(
              "Subjects Studied in Qualifying Degree:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 10,
                childAspectRatio: 3.5,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return TextFormField(
                  controller: _subjectCtrls[index],
                  decoration: InputDecoration(
                    labelText: "Subject ${index + 1}",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Marks Obtained Table
            const Text(
              "Marks Obtained in Degree (Semesters I to VI):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 8),
            
            // Dynamic Table
            Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1, borderRadius: BorderRadius.circular(8)),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.3),
              },
              children: [
                // Table Header
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFECEFF1)),
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Semester", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Total Marks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Secured Marks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                    TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Percentage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                  ],
                ),
                
                // Sem Rows
                _buildSemTableRow("I Semester", "sem1"),
                _buildSemTableRow("II Semester", "sem2"),
                _buildSemTableRow("III Semester", "sem3"),
                _buildSemTableRow("IV Semester", "sem4"),
                _buildSemTableRow("V Semester", "sem5"),
                _buildSemTableRow("VI Semester", "sem6"),
                
                // Grand Total Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50),
                  children: [
                    const TableCell(child: Padding(padding: EdgeInsets.all(10.0), child: Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                    TableCell(child: Padding(padding: const EdgeInsets.all(10.0), child: Text(_formData.marks.grand.total.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                    TableCell(child: Padding(padding: const EdgeInsets.all(10.0), child: Text(_formData.marks.grand.secured.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                    TableCell(child: Padding(padding: const EdgeInsets.all(10.0), child: Text("${_formData.marks.grand.percentage.toStringAsFixed(2)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 13)))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Admission Category
            DropdownButtonFormField<String>(
              initialValue: _formData.category,
              decoration: const InputDecoration(
                labelText: "Category under which seat is claimed *",
                border: OutlineInputBorder(),
              ),
              items: ['GM', 'SC', 'ST', 'CAT-I', 'IIA', 'IIB', 'IIIA', 'IIIB']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                setState(() => _formData.category = val ?? 'GM');
              },
            ),
            const SizedBox(height: 16),

            // Parent Occupation & Income
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _parentOccCtrl,
                    decoration: const InputDecoration(
                      labelText: "Parent's Occupation",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _parentIncomeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Parent's Annual Income (₹)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildSemTableRow(String semName, String semKey) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(semName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextFormField(
              controller: _marksCtrls[semKey]!['total'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
                hintText: "0",
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextFormField(
              controller: _marksCtrls[semKey]!['secured'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
                hintText: "0",
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _getSemPercentageText(semKey),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
        ),
      ],
    );
  }

  String _getSemPercentageText(String semKey) {
    double pct = 0.0;
    switch (semKey) {
      case 'sem1': pct = _formData.marks.sem1.percentage; break;
      case 'sem2': pct = _formData.marks.sem2.percentage; break;
      case 'sem3': pct = _formData.marks.sem3.percentage; break;
      case 'sem4': pct = _formData.marks.sem4.percentage; break;
      case 'sem5': pct = _formData.marks.sem5.percentage; break;
      case 'sem6': pct = _formData.marks.sem6.percentage; break;
    }
    return pct > 0 ? "${pct.toStringAsFixed(2)}%" : "0.00%";
  }

  // --- STEP 4: Enclosures (Documents) ---
  Step _buildStepDocuments() {
    return Step(
      title: const Text('Documents'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3
          ? StepState.complete
          : (_currentStep == 3 ? StepState.editing : StepState.indexed),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Enclosures (Documents Upload)"),
            const Text(
              "Please upload scanned copies of original documents. Accepted formats: PDF, JPG, PNG. Max file size: 2MB.",
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            
            // Document rows
            _buildDocUploadRow("Stamp Size Photo *", "photo"),
            _buildDocUploadRow("Marks Cards of All Semesters *", "marksCards"),
            _buildDocUploadRow("Character Certificate", "characterCert"),
            _buildDocUploadRow("S.S.L.C. / PUC Marks Cards", "sslcPucCard"),
            _buildDocUploadRow("Income Certificate", "incomeCert"),
            _buildDocUploadRow("Caste Certificate", "casteCert"),
            _buildDocUploadRow("Transfer Certificate", "transferCert"),
            _buildDocUploadRow("Aadhaar Card", "aadhaarCard"),
          ],
        ),
      ),
    );
  }

  Widget _buildDocUploadRow(String label, String key) {
    final file = _formData.files[key];
    final isUploaded = file?.isUploaded ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        color: isUploaded ? Colors.green.shade50.withValues(alpha: 0.4) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isUploaded ? Colors.green.shade200 : Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                isUploaded ? Icons.check_circle : Icons.upload_file,
                color: isUploaded ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUploaded ? (file!.fileName ?? 'Uploaded') : 'No file selected',
                      style: TextStyle(
                        fontSize: 11,
                        color: isUploaded ? Colors.green.shade700 : Colors.grey,
                        fontStyle: isUploaded ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _pickFile(key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploaded ? Colors.green : const Color(0xFFECEFF1),
                  foregroundColor: isUploaded ? Colors.white : Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isUploaded ? "Change" : "Choose File", style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 5: Payment Page ---
  Step _buildStepPayment() {
    return Step(
      title: const Text('Payment'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4
          ? StepState.complete
          : (_currentStep == 4 ? StepState.editing : StepState.indexed),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Application Fee Payment"),
            
            // Callout Card
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.payment, color: Color(0xFF0D47A1)),
                        SizedBox(width: 12),
                        Text(
                          "Fee Details",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D47A1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "All postgraduate applicants must pay an application fee of ₹400 via SBI Collect before submitting this form.",
                      style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _launchSBICollect,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text("Pay via SBI Collect"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Enter Payment Transaction Details:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF263238)),
            ),
            const SizedBox(height: 12),

            // Ref No
            TextFormField(
              controller: _payRefCtrl,
              decoration: const InputDecoration(
                labelText: "SBI Collect Reference Number * (e.g. DUXXXXXXXX)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Payment Date
            TextFormField(
              controller: _payDateCtrl,
              readOnly: true,
              onTap: () => _selectDate(context, _payDateCtrl),
              decoration: const InputDecoration(
                labelText: "Date of Payment *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt upload
            _buildDocUploadRow("Upload Payment Receipt (PDF/Image) *", "paymentReceipt"),
          ],
        ),
      ),
    );
  }

  // --- STEP 6: Declaration ---
  Step _buildStepDeclaration() {
    return Step(
      title: const Text('Submit'),
      isActive: _currentStep >= 5,
      state: _currentStep == 5 ? StepState.editing : StepState.indexed,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Declaration & Sign-off"),
            
            // Declaration Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "DECLARATION",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.0),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "I hereby solemnly and sincerely affirm that the statements made and information furnished in my application form and also in the enclosures thereto submitted by me are true. Should it, however, be found that any information furnished therein is untrue in material particulars, I realise that, I am liable to criminal prosecution and the seat given to me shall be liable to be forfeited.",
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF37474F), fontStyle: FontStyle.italic),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Checkbox
            CheckboxListTile(
              title: const Text(
                "I accept the declaration statements above *",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _signatureCtrl.text.isNotEmpty,
              onChanged: (bool? val) {
                setState(() {
                  if (val == true && _nameCtrl.text.isNotEmpty) {
                    _signatureCtrl.text = _nameCtrl.text;
                  } else {
                    _signatureCtrl.text = '';
                  }
                });
              },
              activeColor: const Color(0xFF0D47A1),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 10),

            // Signature input
            TextFormField(
              controller: _signatureCtrl,
              decoration: const InputDecoration(
                labelText: "Digital Signature * (Type applicant name to sign)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gesture),
                helperText: "Typing your name acts as a legally binding signature.",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}
