import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class ApplicantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> application;
  const ApplicantDetailScreen({super.key, required this.application});

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  bool _isUpdating = false;
  late Map<String, dynamic> _app;

  @override
  void initState() {
    super.initState();
    _app = Map<String, dynamic>.from(widget.application);
  }

  Future<void> _openUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty || urlString == "Not Uploaded" || urlString.startsWith("Error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid document URL or file not uploaded')),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some platforms where canLaunchUrl returns false but we can still launch
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open document link: $e')),
      );
    }
  }

  void _confirmStatusUpdate(String status) {
    final isApprove = status == 'Approved';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            isApprove ? "Approve Application?" : "Reject Application?",
            style: TextStyle(color: isApprove ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isApprove
                ? "This will set the student's status to APPROVED. An automated admissions offer and welcome email will be dispatched to ${_app['Email']}."
                : "This will set the student's status to REJECTED. A status notification email will be dispatched to ${_app['Email']}.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.blueGrey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                isApprove ? "Confirm Approve" : "Confirm Reject",
                style: TextStyle(color: isApprove ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatus(status);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isUpdating = true;
    });

    final appId = _app['Application ID'] ?? '';
    try {
      final response = await ApiService.updateApplicationStatus(appId, status);
      if (response['status'] == 'success') {
        setState(() {
          _app['Status'] = status;
          _isUpdating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
            content: Text('Application status successfully updated to $status.'),
          ),
        );
      } else {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${response['message'] ?? 'Failed to update status'}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Network error: $e'),
        ),
      );
    }
  }

  String _normalizeStatus(dynamic status) {
    if (status == null) return 'pending';
    final s = status.toString().trim().toLowerCase();
    if (s == 'approved') return 'approved';
    if (s == 'rejected') return 'rejected';
    return 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final status = _normalizeStatus(_app['Status']);

    Color statusColor = Colors.amber;
    Color statusBg = Colors.amber.withValues(alpha: 0.15);
    if (status == 'approved') {
      statusColor = Colors.green;
      statusBg = Colors.green.withValues(alpha: 0.15);
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusBg = Colors.redAccent.withValues(alpha: 0.15);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B192C), // Premium Dark Navy
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if we changed status, return true so dashboard list updates
            final initialStatus = _normalizeStatus(widget.application['Status']);
            Navigator.pop(context, initialStatus != status);
          },
        ),
        title: const Text(
          "Applicant Details",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1000 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card with Name and Status
                    _buildOverviewCard(statusBg, statusColor, status),
                    const SizedBox(height: 24),

                    // Layout content responsive grid/split view
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    _buildPersonalSection(),
                                    const SizedBox(height: 24),
                                    _buildAcademicSection(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildDocumentSection(),
                                    const SizedBox(height: 24),
                                    _buildPaymentSection(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPersonalSection(),
                              const SizedBox(height: 24),
                              _buildAcademicSection(),
                              const SizedBox(height: 24),
                              _buildDocumentSection(),
                              const SizedBox(height: 24),
                              _buildPaymentSection(),
                            ],
                          ),
                    const SizedBox(height: 40),

                    // Action buttons (Approve / Reject)
                    if (status == 'pending') ...[
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Color statusBg, Color statusColor, String status) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_app['Student Name'] ?? '?').toString().isNotEmpty
                    ? (_app['Student Name'] ?? '?').toString()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _app['Student Name'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _app['Course Selected'] ?? 'N/A',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    const Text("|", style: TextStyle(color: Colors.white24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _app['Application ID'] ?? 'N/A',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final String displayValue = (value == null || value.toString().isEmpty) ? 'N/A' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _buildSectionCard(
      title: "Personal Details",
      icon: Icons.person_outline,
      children: [
        _buildInfoRow("Parents Name", _app['Parents Name']),
        _buildInfoRow("Date of Birth", _app['Date of Birth']),
        _buildInfoRow("Place of Birth", _app['Place of Birth']),
        _buildInfoRow("Sex", _app['Sex']),
        _buildInfoRow("Mother Tongue", _app['Mother Tongue']),
        _buildInfoRow("Nationality", _app['Nationality']),
        _buildInfoRow("Religion / Caste", "${_app['Religion'] ?? 'N/A'} / ${_app['Caste'] ?? 'N/A'}"),
        _buildInfoRow("Category Claimed", _app['Category Claimed']),
        const SizedBox(height: 8),
        const Divider(color: Colors.white10),
        const SizedBox(height: 8),
        _buildInfoRow("Email", _app['Email']),
        _buildInfoRow("Phone Number", _app['Phone Number']),
        _buildInfoRow("Mobile Number", _app['Mobile Number']),
        _buildInfoRow("Aadhaar Number", _app['Aadhaar Number']),
        _buildInfoRow("Present Address", _app['Present Address']),
        _buildInfoRow("Permanent Address", _app['Permanent Address']),
      ],
    );
  }

  Widget _buildAcademicSection() {
    // Collect semester marks pct
    final double pct1 = _parseDouble(_app['Sem 1 Pct']);
    final double pct2 = _parseDouble(_app['Sem 2 Pct']);
    final double pct3 = _parseDouble(_app['Sem 3 Pct']);
    final double pct4 = _parseDouble(_app['Sem 4 Pct']);
    final double pct5 = _parseDouble(_app['Sem 5 Pct']);
    final double pct6 = _parseDouble(_app['Sem 6 Pct']);
    final double pctGrand = _parseDouble(_app['Grand Percentage']);

    return _buildSectionCard(
      title: "Academic Marks Details",
      icon: Icons.school_outlined,
      children: [
        _buildInfoRow("Last Institution", _app['Last Attended Institution']),
        _buildInfoRow("Subjects Studied", _app['Subjects Studied']),
        const SizedBox(height: 12),
        const Text(
          "SEMESTER WISE PERCENTAGES",
          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        _buildMarksGrid(pct1, pct2, pct3, pct4, pct5, pct6),
        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("GRAND SECURED MARKS", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(
                    "${_app['Grand Secured Marks'] ?? '0'} / ${_app['Grand Total Marks'] ?? '0'}",
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text("AGGREGATE", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    "${pctGrand.toStringAsFixed(2)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Widget _buildMarksGrid(double p1, double p2, double p3, double p4, double p5, double p6) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildMarksCell("Sem 1", p1),
        _buildMarksCell("Sem 2", p2),
        _buildMarksCell("Sem 3", p3),
        _buildMarksCell("Sem 4", p4),
        _buildMarksCell("Sem 5", p5),
        _buildMarksCell("Sem 6", p6),
      ],
    );
  }

  Widget _buildMarksCell(String title, double value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value > 0 ? "${value.toStringAsFixed(1)}%" : "N/A",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return _buildSectionCard(
      title: "Uploaded Documents",
      icon: Icons.folder_shared_outlined,
      children: [
        _buildDocLinkRow("Student Photograph", _app['Photo URL']),
        _buildDocLinkRow("Marks Cards (PDF)", _app['Marks Cards URL']),
        _buildDocLinkRow("SSLC/PUC Certificate", _app['SSLC PUC Certificate URL']),
        _buildDocLinkRow("Character Certificate", _app['Character Certificate URL']),
        _buildDocLinkRow("Caste Certificate", _app['Caste Certificate URL']),
        _buildDocLinkRow("Income Certificate", _app['Income Certificate URL']),
        _buildDocLinkRow("Transfer Certificate (TC)", _app['Transfer Certificate URL']),
        _buildDocLinkRow("Aadhaar Card copy", _app['Aadhaar Card URL']),
      ],
    );
  }

  Widget _buildDocLinkRow(String label, dynamic url) {
    final String? urlString = url?.toString();
    final bool isUploaded = urlString != null && urlString.isNotEmpty && urlString != "Not Uploaded" && !urlString.startsWith("Error");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          isUploaded
              ? TextButton.icon(
                  onPressed: () => _openUrl(urlString),
                  icon: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF38BDF8)),
                  label: const Text(
                    "View File",
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              : const Text(
                  "Not Uploaded",
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _buildSectionCard(
      title: "Payment Receipt",
      icon: Icons.payments_outlined,
      children: [
        _buildInfoRow("SBI Ref Number", _app['SBI Collect Ref No']),
        _buildInfoRow("Payment Date", _app['Payment Date']),
        const SizedBox(height: 10),
        const Divider(color: Colors.white10),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "SBI Collect e-Receipt",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            TextButton.icon(
              onPressed: () => _openUrl(_app['Payment Receipt URL']),
              icon: const Icon(Icons.receipt_long, size: 14, color: Color(0xFF38BDF8)),
              label: const Text(
                "View Receipt",
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmStatusUpdate("Rejected"),
            icon: const Icon(Icons.highlight_off, color: Colors.white),
            label: const Text(
              "Reject Application",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmStatusUpdate("Approved"),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              "Approve Application",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom extensions for formatting
extension TextStyleColors on TextStyle {
  TextStyle get colorWhitee8 => copyWith(color: const Color(0xFFE2E8F0));
}
