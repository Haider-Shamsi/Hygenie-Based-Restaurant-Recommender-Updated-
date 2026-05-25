import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

// --- DATA MODELS ---

class AdminRestaurant {
  final String id;
  final String name;
  final String cuisine;
  final int hygieneScore;
  final int reviewsCount;
  final String status;
  final String lastInspection;
  final String location;
  final String phone;
  final String owner;
  final int recentReports;

  AdminRestaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.hygieneScore,
    required this.reviewsCount,
    required this.status,
    required this.lastInspection,
    required this.location,
    required this.phone,
    required this.owner,
    required this.recentReports,
  });
}

// --- WIDGET ---

class AdminRestaurantsPanel extends StatefulWidget {
  const AdminRestaurantsPanel({super.key});

  @override
  State<AdminRestaurantsPanel> createState() => _AdminRestaurantsPanelState();
}

class _AdminRestaurantsPanelState extends State<AdminRestaurantsPanel> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  // State Variables
  String _searchQuery = '';
  String _filterScore = 'all';
  String _filterStatus = 'all';
  String _filterCuisine = 'All';
  String _sortBy = 'name';
  Set<String> _selectedRestaurants = {};
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Mock Data
  late List<AdminRestaurant> _allRestaurants;
  final List<String> _cuisines = ['All', 'Chinese', 'Italian', 'American', 'Japanese', 'Mexican', 'Cafe', 'Indian', 'Greek'];

  @override
  void initState() {
    super.initState();
    _allRestaurants = [
      AdminRestaurant(id: '1', name: 'Dragon Wok', cuisine: 'Chinese', hygieneScore: 95, reviewsCount: 127, status: 'Active', lastInspection: 'Dec 10, 2025', location: '123 Main St, Downtown', phone: '(555) 123-4567', owner: 'Wei Chen', recentReports: 0),
      AdminRestaurant(id: '2', name: 'Pizza Palace', cuisine: 'Italian', hygieneScore: 88, reviewsCount: 203, status: 'Active', lastInspection: 'Dec 8, 2025', location: '456 Oak Ave, Midtown', phone: '(555) 234-5678', owner: 'Marco Rossi', recentReports: 1),
      AdminRestaurant(id: '3', name: 'Burger Joint', cuisine: 'American', hygieneScore: 72, reviewsCount: 89, status: 'Under Review', lastInspection: 'Dec 5, 2025', location: '789 Elm St, Uptown', phone: '(555) 345-6789', owner: 'John Smith', recentReports: 2),
      AdminRestaurant(id: '4', name: 'Sushi Bar', cuisine: 'Japanese', hygieneScore: 91, reviewsCount: 156, status: 'Active', lastInspection: 'Dec 12, 2025', location: '321 Pine Rd, Eastside', phone: '(555) 456-7890', owner: 'Yuki Tanaka', recentReports: 0),
      AdminRestaurant(id: '5', name: 'Taco Stand', cuisine: 'Mexican', hygieneScore: 65, reviewsCount: 74, status: 'Under Review', lastInspection: 'Nov 28, 2025', location: '654 Maple Dr, Westside', phone: '(555) 567-8901', owner: 'Carlos Rodriguez', recentReports: 3),
      AdminRestaurant(id: '6', name: 'Cafe Mocha', cuisine: 'Cafe', hygieneScore: 82, reviewsCount: 98, status: 'Active', lastInspection: 'Dec 3, 2025', location: '987 Coffee Ln, Downtown', phone: '(555) 678-9012', owner: 'Sarah Johnson', recentReports: 0),
      AdminRestaurant(id: '7', name: 'Spice Garden', cuisine: 'Indian', hygieneScore: 78, reviewsCount: 112, status: 'Active', lastInspection: 'Dec 1, 2025', location: '147 Curry St, Midtown', phone: '(555) 789-0123', owner: 'Raj Patel', recentReports: 0),
      AdminRestaurant(id: '8', name: 'Greek Taverna', cuisine: 'Greek', hygieneScore: 38, reviewsCount: 45, status: 'Suspended', lastInspection: 'Nov 15, 2025', location: '258 Zeus Ave, Uptown', phone: '(555) 890-1234', owner: 'Dimitri Papadopoulos', recentReports: 5),
    ];
  }

  // --- LOGIC ---

  List<AdminRestaurant> get _filteredAndSortedRestaurants {
    var filtered = _allRestaurants.where((r) {
      bool matchesSearch = _searchQuery.isEmpty || 
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          r.location.toLowerCase().contains(_searchQuery.toLowerCase());
          
      bool matchesScore = _filterScore == 'all' ||
          (_filterScore == 'excellent' && r.hygieneScore >= 80) ||
          (_filterScore == 'good' && r.hygieneScore >= 60 && r.hygieneScore < 80) ||
          (_filterScore == 'fair' && r.hygieneScore >= 40 && r.hygieneScore < 60) ||
          (_filterScore == 'poor' && r.hygieneScore < 40);
          
      bool matchesStatus = _filterStatus == 'all' || r.status.toLowerCase().replaceAll(' ', '-') == _filterStatus;
      
      bool matchesCuisine = _filterCuisine == 'All' || r.cuisine == _filterCuisine;
      
      return matchesSearch && matchesScore && matchesStatus && matchesCuisine;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'name') return a.name.compareTo(b.name);
      if (_sortBy == 'score-high') return b.hygieneScore.compareTo(a.hygieneScore);
      if (_sortBy == 'score-low') return a.hygieneScore.compareTo(b.hygieneScore);
      if (_sortBy == 'reviews') return b.reviewsCount.compareTo(a.reviewsCount);
      return 0;
    });

    return filtered;
  }

  void _toggleSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedRestaurants = _filteredAndSortedRestaurants.map((r) => r.id).toSet();
      } else {
        _selectedRestaurants.clear();
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedRestaurants.contains(id)) {
        _selectedRestaurants.remove(id);
      } else {
        _selectedRestaurants.add(id);
      }
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAndSortedRestaurants;
    final totalPages = (filteredList.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedList = filteredList.skip(startIndex).take(_itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
          child: TextField(
            onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
            decoration: const InputDecoration(
              hintText: "Search by name or location...",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDropdown(
                value: _filterScore,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text("All Scores")),
                  DropdownMenuItem(value: 'excellent', child: Text("Excellent (80+)")),
                  DropdownMenuItem(value: 'good', child: Text("Good (60-79)")),
                  DropdownMenuItem(value: 'fair', child: Text("Fair (40-59)")),
                  DropdownMenuItem(value: 'poor', child: Text("Poor (<40)")),
                ],
                onChanged: (val) => setState(() { _filterScore = val!; _currentPage = 1; }),
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text("All Status")),
                  DropdownMenuItem(value: 'active', child: Text("Active")),
                  DropdownMenuItem(value: 'suspended', child: Text("Suspended")),
                  DropdownMenuItem(value: 'under-review', child: Text("Under Review")),
                ],
                onChanged: (val) => setState(() { _filterStatus = val!; _currentPage = 1; }),
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _filterCuisine,
                items: _cuisines.map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Cuisines' : c))).toList(),
                onChanged: (val) => setState(() { _filterCuisine = val!; _currentPage = 1; }),
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text("Sort: Name")),
                  DropdownMenuItem(value: 'score-high', child: Text("Score (High→Low)")),
                  DropdownMenuItem(value: 'score-low', child: Text("Score (Low→High)")),
                  DropdownMenuItem(value: 'reviews', child: Text("Most Reviews")),
                ],
                onChanged: (val) => setState(() => _sortBy = val!),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showAddRestaurantModal,
                child: Container(
                  height: 40, width: 40,
                  decoration: BoxDecoration(color: _brandTeal, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Bulk Actions
        if (_selectedRestaurants.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: _brandTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandTeal.withOpacity(0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${_selectedRestaurants.length} restaurant(s) selected", style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text("Export"), style: OutlinedButton.styleFrom(foregroundColor: _brandTeal)),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.notifications_none, size: 16), label: const Text("Notify"), style: OutlinedButton.styleFrom(foregroundColor: _brandTeal)),
                  ],
                )
              ],
            ),
          ),

        // 4. Data Table
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  dataRowMaxHeight: 70,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: [
                    DataColumn(label: Checkbox(value: _selectedRestaurants.length == filteredList.length && filteredList.isNotEmpty, onChanged: _toggleSelectAll)),
                    const DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const DataColumn(label: Text("Cuisine", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const DataColumn(label: Text("Score", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const DataColumn(label: Text("Reviews", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const DataColumn(label: Text("Last Inspection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                  rows: paginatedList.map((restaurant) {
                    return DataRow(
                      selected: _selectedRestaurants.contains(restaurant.id),
                      onSelectChanged: (val) => _showRestaurantDetailModal(restaurant),
                      cells: [
                        DataCell(Checkbox(value: _selectedRestaurants.contains(restaurant.id), onChanged: (val) => _toggleSelect(restaurant.id))),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(restaurant.name, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 13)),
                              Text(restaurant.location.split(',')[0], style: TextStyle(color: _textGray, fontSize: 11)), // Truncated location
                            ],
                          ),
                        ),
                        DataCell(Text(restaurant.cuisine, style: TextStyle(color: _textDark, fontSize: 13))),
                        DataCell(_buildScoreBadge(restaurant.hygieneScore)),
                        DataCell(Text(restaurant.reviewsCount.toString(), style: TextStyle(color: _textDark, fontSize: 13))),
                        DataCell(_buildStatusBadge(restaurant.status)),
                        DataCell(Text(restaurant.lastInspection, style: TextStyle(color: _textDark, fontSize: 13))),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (val) {
                              if (val == 'view') _showRestaurantDetailModal(restaurant);
                              // Handle other actions
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 16), SizedBox(width: 8), Text("View Details")])),
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text("Edit")])),
                              const PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.block, size: 16, color: Colors.orange), SizedBox(width: 8), Text("Suspend", style: TextStyle(color: Colors.orange))])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. Pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Showing ${filteredList.isEmpty ? 0 : startIndex + 1} to ${math.min(startIndex + _itemsPerPage, filteredList.length)} of ${filteredList.length} restaurants", style: TextStyle(color: _textGray, fontSize: 12)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _brandTeal, borderRadius: BorderRadius.circular(6)),
                  child: Text("$_currentPage", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                ),
              ],
            )
          ],
        )
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          style: TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w500),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    Color color;
    if (score >= 80) { color = _brandTeal; } 
    else if (score >= 60) { color = Colors.amber; } 
    else if (score >= 40) { color = Colors.orange; } 
    else { color = Colors.red; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
      child: Text(score.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;
    if (status == 'Active') { color = _brandTeal; bg = _brandTeal.withOpacity(0.1); } 
    else if (status == 'Suspended') { color = Colors.red; bg = Colors.red.withOpacity(0.1); } 
    else { color = Colors.amber.shade700; bg = Colors.amber.withOpacity(0.1); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  // --- MODALS ---

  void _showAddRestaurantModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Add New Restaurant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _modalTextField("Restaurant Name", "Enter restaurant name"),
              const SizedBox(height: 12),
              const Text("Cuisine Type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _buildDropdown(value: 'All', items: _cuisines.map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'Select Cuisine' : c))).toList(), onChanged: (v){}),
              const SizedBox(height: 12),
              _modalTextField("Location", "Enter address"),
              const SizedBox(height: 12),
              _modalTextField("Phone", "Enter phone number"),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Cancel"))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Add Restaurant", style: TextStyle(color: Colors.white)))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalTextField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 13), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ],
    );
  }

  void _showRestaurantDetailModal(AdminRestaurant restaurant) {
    final List<FlSpot> mockHistory = const [FlSpot(0, 88), FlSpot(1, 90), FlSpot(2, 89), FlSpot(3, 92), FlSpot(4, 93), FlSpot(5, 95)];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(restaurant.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Grid
                      Wrap(
                        spacing: 24, runSpacing: 16,
                        children: [
                          _detailPair("Cuisine", restaurant.cuisine),
                          _detailPair("Status", restaurant.status, isBadge: true),
                          _detailPair("Location", restaurant.location),
                          _detailPair("Owner", restaurant.owner),
                          _detailPair("Phone", restaurant.phone),
                          _detailPair("Last Inspection", restaurant.lastInspection),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Chart
                      const Text("Hygiene Score History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [LineChartBarData(spots: mockHistory, isCurved: true, color: _brandTeal, barWidth: 2, dotData: const FlDotData(show: true))],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Admin Actions
                      const Text("Admin Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.trending_up, size: 16), label: const Text("Update Score"), style: OutlinedButton.styleFrom(foregroundColor: _textDark)),
                          OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.calendar_today, size: 16), label: const Text("Schedule Inspection"), style: OutlinedButton.styleFrom(foregroundColor: _textDark)),
                          OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.block, size: 16), label: const Text("Suspend"), style: OutlinedButton.styleFrom(foregroundColor: Colors.orange)),
                          OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.warning_amber_rounded, size: 16), label: const Text("Send Warning"), style: OutlinedButton.styleFrom(foregroundColor: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Notes
                      const Text("Admin Internal Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        decoration: InputDecoration(hintText: "Add internal notes...", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.save, size: 16, color: Colors.white), label: const Text("Save Notes", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailPair(String label, String value, {bool isBadge = false}) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: _textGray)),
          const SizedBox(height: 4),
          isBadge ? _buildStatusBadge(value) : Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
        ],
      ),
    );
  }
}