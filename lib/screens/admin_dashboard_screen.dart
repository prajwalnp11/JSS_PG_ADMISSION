import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'applicant_detail_screen.dart';
import 'dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allApplications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  // Tab indices
  static const int tabAll = 0;
  static const int tabPending = 1;
  static const int tabApproved = 2;
  static const int tabRejected = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadApplications();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.fetchApplications();
      if (response['status'] == 'success') {
        final List<dynamic> apps = response['applications'] ?? [];
        setState(() {
          _allApplications = apps.map((a) => Map<String, dynamic>.from(a)).toList();
          // Sort by timestamp descending by default (most recent first)
          _allApplications.sort((a, b) {
            final t1 = a['Timestamp'] ?? '';
            final t2 = b['Timestamp'] ?? '';
            return t2.compareTo(t1);
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load applications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredApplications {
    List<Map<String, dynamic>> list = [];
    
    // 1. Filter by Tab Status
    final int currentTab = _tabController.index;
    if (currentTab == tabAll) {
      list = _allApplications;
    } else if (currentTab == tabPending) {
      list = _allApplications.where((a) => _normalizeStatus(a['Status']) == 'pending').toList();
    } else if (currentTab == tabApproved) {
      list = _allApplications.where((a) => _normalizeStatus(a['Status']) == 'approved').toList();
    } else if (currentTab == tabRejected) {
      list = _allApplications.where((a) => _normalizeStatus(a['Status']) == 'rejected').toList();
    }

    // 2. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((a) {
        final name = (a['Student Name'] ?? '').toString().toLowerCase();
        final appId = (a['Application ID'] ?? '').toString().toLowerCase();
        final course = (a['Course Selected'] ?? '').toString().toLowerCase();
        final email = (a['Email'] ?? '').toString().toLowerCase();
        return name.contains(query) || appId.contains(query) || course.contains(query) || email.contains(query);
      }).toList();
    }

    return list;
  }

  String _normalizeStatus(dynamic status) {
    if (status == null) return 'pending';
    final s = status.toString().trim().toLowerCase();
    if (s == 'approved') return 'approved';
    if (s == 'rejected') return 'rejected';
    return 'pending'; // Default fallback
  }

  // Counts for statistics cards
  int get _countAll => _allApplications.length;
  int get _countPending => _allApplications.where((a) => _normalizeStatus(a['Status']) == 'pending').length;
  int get _countApproved => _allApplications.where((a) => _normalizeStatus(a['Status']) == 'approved').length;
  int get _countRejected => _allApplications.where((a) => _normalizeStatus(a['Status']) == 'rejected').length;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Log Out", style: TextStyle(color: Colors.white)),
          content: const Text("Are you sure you want to log out of the Staff Portal?", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.blueGrey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Slate Background matching screenshot
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          "Failed to Load Applications",
                          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadApplications,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try Again"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Deep Royal Blue Header matching screenshot
                    Container(
                      color: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.only(top: 40, bottom: 20, left: 16, right: 16),
                      child: Column(
                        children: [
                          // App Bar Header Row
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Staff Portal",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "PG Admissions 2026-27",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                tooltip: "Refresh Data",
                                onPressed: _loadApplications,
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white),
                                tooltip: "Logout",
                                onPressed: _handleLogout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Tab Bar
                          TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.white,
                            indicatorWeight: 3.0,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            tabs: [
                              _buildTab("All", _countAll),
                              _buildTab("Pending", _countPending),
                              _buildTab("Approved", _countApproved),
                              _buildTab("Rejected", _countRejected),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Statistics row
                          Row(
                            children: [
                              Expanded(child: _buildStatCard("Total", _countAll, const Color(0xFF1E88E5))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard("Pending", _countPending, const Color(0xFF6B7280))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard("Approved", _countApproved, const Color(0xFF0F766E))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard("Rejected", _countRejected, const Color(0xFF701A75))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Body with search bar & dynamic list
                    Expanded(
                      child: Column(
                        children: [
                          // Search Box
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: "Search by name, ID or course...",
                                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),

                          // Dynamic Applications List
                          Expanded(
                            child: _filteredApplications.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.folder_open, size: 48, color: Colors.black26),
                                        const SizedBox(height: 12),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? "No search results match '$_searchQuery'"
                                              : "No applications found in this tab",
                                          style: const TextStyle(color: Colors.black38, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: _filteredApplications.length,
                                    itemBuilder: (context, index) {
                                      final app = _filteredApplications[index];
                                      return _buildApplicantCard(app);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> app) {
    final status = _normalizeStatus(app['Status']);
    
    // Theme Colors based on Status
    Color avatarBg;
    Color avatarText;
    Color badgeColor;
    Color badgeBg;
    
    if (status == 'approved') {
      avatarBg = const Color(0xFFDCFCE7);
      avatarText = const Color(0xFF15803D);
      badgeColor = const Color(0xFF15803D);
      badgeBg = const Color(0xFFDCFCE7);
    } else if (status == 'rejected') {
      avatarBg = const Color(0xFFFEE2E2);
      avatarText = const Color(0xFFB91C1C);
      badgeColor = const Color(0xFFB91C1C);
      badgeBg = const Color(0xFFFEE2E2);
    } else {
      avatarBg = const Color(0xFFFEF3C7);
      avatarText = const Color(0xFFB45309);
      badgeColor = const Color(0xFFB45309);
      badgeBg = const Color(0xFFFEF3C7);
    }

    final String studentName = (app['Student Name'] ?? 'N/A').toString();
    final String courseSelected = (app['Course Selected'] ?? 'N/A').toString();
    final String appId = (app['Application ID'] ?? 'N/A').toString();
    
    // Parse aggregate percentage
    double pctGrand = 0.0;
    if (app['Grand Percentage'] != null) {
      pctGrand = double.tryParse(app['Grand Percentage'].toString()) ?? 0.0;
    }
    
    // Format timestamp to simple date (YYYY-MM-DD)
    String formattedDate = '';
    if (app['Timestamp'] != null && app['Timestamp'].toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(app['Timestamp'].toString());
        formattedDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      } catch (_) {
        formattedDate = app['Timestamp'].toString().split('T')[0];
      }
    } else {
      formattedDate = "2026-06-01";
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.02),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicantDetailScreen(application: app),
            ),
          ).then((updated) {
            if (updated == true) {
              _loadApplications(); // Refresh list on change
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Colored circular avatar containing first letter of name
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: avatarText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            studentName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseSelected,
                      style: const TextStyle(
                        color: Color(0xFF0D47A1), // Royal Blue
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "# $appId",
                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.school_outlined, size: 14, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          "${pctGrand.toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
