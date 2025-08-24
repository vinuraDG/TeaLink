import 'package:TeaLink/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SortField { date, name, regNo }
enum SortOrder { ascending, descending }

class CollectionHistoryPage extends StatefulWidget {
  final String collectorId;

  const CollectionHistoryPage({super.key, required this.collectorId});

  @override
  _CollectionHistoryPageState createState() => _CollectionHistoryPageState();
}

class _CollectionHistoryPageState extends State<CollectionHistoryPage> {
  int _selectedIndex = 2;
  String _searchQuery = "";
  bool _isSearching = false;

  SortField _sortField = SortField.date;
  SortOrder _sortOrder = SortOrder.descending;

  // Date range filter for Older tab
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final CollectionReference notifyCollection =
        FirebaseFirestore.instance.collection('notify_for_collection');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: !_isSearching
              ? const Text(
                  "Collection History",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kWhite,
                  ),
                )
              : TextField(
                  autofocus: true,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                ),
          centerTitle: true,
          backgroundColor: kMainColor,
          leading: IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.arrow_back,
                color: kWhite),
            onPressed: () {
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchQuery = "";
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search, color: kWhite),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            PopupMenuButton<String>(
              iconColor: kWhite,
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() {
                  switch (value) {
                    case "Date":
                      _sortField = SortField.date;
                      break;
                    case "Name":
                      _sortField = SortField.name;
                      break;
                    case "Reg No":
                      _sortField = SortField.regNo;
                      break;
                    case "Ascending":
                      _sortOrder = SortOrder.ascending;
                      break;
                    case "Descending":
                      _sortOrder = SortOrder.descending;
                      break;
                  }
                });
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: "Date", child: Text("Sort by Date")),
                const PopupMenuItem(
                    value: "Name", child: Text("Sort by Name")),
                const PopupMenuItem(
                    value: "Reg No", child: Text("Sort by Reg No")),
                const PopupMenuDivider(),
                const PopupMenuItem(
                    value: "Ascending", child: Text("Ascending")),
                const PopupMenuItem(
                    value: "Descending", child: Text("Descending")),
              ],
            ),
          ],
          bottom: TabBar(
  indicatorColor: kWhite, // color of the underline indicator
  labelColor: kWhite, // selected tab text color
  unselectedLabelColor: Colors.white70, // unselected tab text color
  labelStyle: const TextStyle(
    fontWeight: FontWeight.bold, // make selected tab bold
    fontSize: 16, // optional: adjust font size
  ),
  unselectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.normal, // optional: unselected tab style
    fontSize: 16,
  ),
  tabs: const [
    Tab(text: "Today"),
    Tab(text: "Older"),
  ],
),

        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: notifyCollection
              .where('collectorId', isEqualTo: widget.collectorId)
              .where('status', isEqualTo: 'Collected')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final history = snapshot.data?.docs ?? [];

            // Apply search filter
            var filteredHistory = history.where((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final customerName =
                  data['name']?.toString().toLowerCase() ?? '';
              final regNo = data['regNo']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return customerName.contains(query) || regNo.contains(query);
            }).toList();

            // Apply sorting
            filteredHistory.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>? ?? {};
              final dataB = b.data() as Map<String, dynamic>? ?? {};

              int result = 0;
              switch (_sortField) {
                case SortField.date:
                  DateTime dateA =
                      (dataA['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  DateTime dateB =
                      (dataB['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  result = dateA.compareTo(dateB);
                  break;
                case SortField.name:
                  String nameA = (dataA['name'] ?? '').toString();
                  String nameB = (dataB['name'] ?? '').toString();
                  result = nameA.compareTo(nameB);
                  break;
                case SortField.regNo:
                  String regA = (dataA['regNo'] ?? '').toString();
                  String regB = (dataB['regNo'] ?? '').toString();
                  result = regA.compareTo(regB);
                  break;
              }

              return _sortOrder == SortOrder.ascending ? result : -result;
            });

            // Split into Today vs Older
            DateTime today = DateTime.now();
            List<DocumentSnapshot> todayList = [];
            List<DocumentSnapshot> olderList = [];

            for (var doc in filteredHistory) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              DateTime createdAt =
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              if (createdAt.year == today.year &&
                  createdAt.month == today.month &&
                  createdAt.day == today.day) {
                todayList.add(doc);
              } else {
                olderList.add(doc);
              }
            }

            return TabBarView(
              children: [
                _buildList(todayList, isToday: true),
                _buildList(olderList, isToday: false),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kMainColor,
          unselectedItemColor: Colors.black,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.grey[200],
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_sharp), label: 'Map'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<DocumentSnapshot> docs, {bool isToday = false}) {
    if (docs.isEmpty && !isToday) return _emptyState();

    // Filter by date range if Older tab
    List<DocumentSnapshot> filteredDocs = docs;
    if (!isToday && (_startDate != null || _endDate != null)) {
      filteredDocs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        DateTime createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        if (_startDate != null && createdAt.isBefore(_startDate!)) return false;
        if (_endDate != null && createdAt.isAfter(_endDate!)) return false;

        return true;
      }).toList();
    }

    // Today tab → calculate summary
    int totalCollections = 0;
    double totalWeight = 0;
    if (isToday) {
      totalCollections = filteredDocs.length;
      for (var doc in filteredDocs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        double weight = double.tryParse(data['weight']?.toString() ?? "0") ?? 0;
        totalWeight += weight;
      }
    }

    return Column(
      children: [
        // Date range filter UI for Older tab
        if (!isToday)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _pickDate(isStart: true),
                  child: Text(
                      _startDate != null ? _formatDate(_startDate!) : "Start Date",style: TextStyle(color: kBlack,fontWeight: FontWeight.w800),),
                ),
                ElevatedButton(
                  onPressed: () => _pickDate(isStart: false),
                  child:
                      Text(_endDate != null ? _formatDate(_endDate!) : "End Date",style: TextStyle(color: kBlack,fontWeight: FontWeight.w800),),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),

        // Summary card for Today tab
        if (isToday)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kMainColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Total Collections",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      "$totalCollections",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Total Weight",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      "${totalWeight.toStringAsFixed(2)} kg",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final customerName = data['name']?.toString() ?? 'Unknown';
              final regNo = data['regNo']?.toString() ?? 'N/A';
              DateTime createdAt =
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              final date =
                  "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
              final time =
                  "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: kMainColor,
                    radius: 25,
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(customerName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Reg No: $regNo",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      Text("Collected on: $date at $time",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => _showDetailsDialog(data),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No Collection History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("You have not marked any collection yet.",
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/collector_home');
        break;
      case 1:
        Navigator.pushNamed(context, '/collector_map');
        break;
      case 2:
        Navigator.pushNamed(context, '/collector_history');
        break;
      case 3:
        Navigator.pushNamed(context, '/collector_profile');
        break;
    }
  }

  void _showDetailsDialog(Map<String, dynamic> data) {
    DateTime createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final date =
        "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
    final time =
        "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['name'] ?? "Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reg No: ${data['regNo'] ?? 'N/A'}"),
            Text("Collected on: $date at $time"),
            Text("Weight: ${data['weight'] ?? 'N/A'} kg"),
            Text("Remarks: ${data['remarks'] ?? 'None'}"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2020);
    DateTime lastDate = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? initialDate) : (_endDate ?? initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
