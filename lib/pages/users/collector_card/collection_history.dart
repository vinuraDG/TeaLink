import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


enum SortField { date, name, regNo, weight }
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
    final localizations = AppLocalizations.of(context)!;
    final CollectionReference notifyCollection =
        FirebaseFirestore.instance.collection('notify_for_collection');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: !_isSearching
              ? Text(
                  localizations.collectionHistory,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kWhite,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    autofocus: true,
                    style: const TextStyle(color: kWhite),
                    decoration: InputDecoration(
                      hintText: localizations.searchByNameOrReg,
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                  ),
                ),
          centerTitle: true,
          backgroundColor: kMainColor,
          elevation: 0,
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
            if (!_isSearching) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: kWhite, size: 20),
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PopupMenuButton<String>(
                  iconColor: kWhite,
                  icon: const Icon(Icons.tune),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        case "Weight":
                          _sortField = SortField.weight;
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
                    PopupMenuItem(
                      value: "Date",
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: kMainColor, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.sortByDate),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "Name",
                      child: Row(
                        children: [
                          Icon(Icons.person, color: kMainColor, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.sortByName),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "Reg No",
                      child: Row(
                        children: [
                          Icon(Icons.numbers, color: kMainColor, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.sortByRegNo),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "Weight",
                      child: Row(
                        children: [
                          Icon(Icons.scale, color: kMainColor, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.sortByWeight),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: "Ascending",
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.ascending),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "Descending",
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.descending),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: const BoxDecoration(
                color: kMainColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: TabBar(
                indicatorColor: kWhite,
                indicatorWeight: 3,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: kWhite),
                  insets: EdgeInsets.symmetric(horizontal: 50),
                ),
                labelColor: kWhite,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.today, size: 18),
                        const SizedBox(width: 6),
                        Text(localizations.today),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 18),
                        const SizedBox(width: 6),
                        Text(localizations.history),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: notifyCollection
              .where('collectorId', isEqualTo: widget.collectorId)
              .where('status', isEqualTo: 'Collected')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: kMainColor),
                    const SizedBox(height: 16),
                    Text(
                      localizations.loadingCollectionHistory,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.somethingWentWrong,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.unableToLoadHistory,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            final history = snapshot.data?.docs ?? [];

            // Sort by collectedAt in memory (descending - newest first)
            history.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>? ?? {};
              final dataB = b.data() as Map<String, dynamic>? ?? {};
              
              DateTime dateA = (dataA['collectedAt'] as Timestamp?)?.toDate() ??
                  (dataA['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              DateTime dateB = (dataB['collectedAt'] as Timestamp?)?.toDate() ??
                  (dataB['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              
              return dateB.compareTo(dateA);
            });

            // Apply search filter
            var filteredHistory = history.where((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final customerName = data['name']?.toString().toLowerCase() ?? '';
              final regNo = data['regNo']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return customerName.contains(query) || regNo.contains(query);
            }).toList();

            // Apply additional sorting based on user selection
            filteredHistory.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>? ?? {};
              final dataB = b.data() as Map<String, dynamic>? ?? {};

              int result = 0;
              switch (_sortField) {
                case SortField.date:
                  DateTime dateA = (dataA['collectedAt'] as Timestamp?)?.toDate() ??
                      (dataA['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  DateTime dateB = (dataB['collectedAt'] as Timestamp?)?.toDate() ??
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
                case SortField.weight:
                  double weightA = double.tryParse(dataA['weight']?.toString() ?? "0") ?? 0;
                  double weightB = double.tryParse(dataB['weight']?.toString() ?? "0") ?? 0;
                  result = weightA.compareTo(weightB);
                  break;
              }

              return _sortOrder == SortOrder.ascending ? result : -result;
            });

            DateTime today = DateTime.now();
            List<DocumentSnapshot> todayList = [];
            List<DocumentSnapshot> olderList = [];

            for (var doc in filteredHistory) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              DateTime collectedAt = (data['collectedAt'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              if (collectedAt.year == today.year &&
                  collectedAt.month == today.month &&
                  collectedAt.day == today.day) {
                todayList.add(doc);
              } else {
                olderList.add(doc);
              }
            }

            return TabBarView(
              children: [
                _buildList(todayList, isToday: true, localizations: localizations),
                _buildList(olderList, isToday: false, localizations: localizations),
              ],
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: kMainColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded, size: 24),
                label: localizations.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map_sharp, size: 24),
                label: localizations.map,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history, size: 24),
                label: localizations.history,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person, size: 24),
                label: localizations.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<DocumentSnapshot> docs, {bool isToday = false, required AppLocalizations localizations}) {
    if (docs.isEmpty) return _emptyState(isToday, localizations);

    // Filter by date range if Older tab
    List<DocumentSnapshot> filteredDocs = docs;
    if (!isToday && (_startDate != null || _endDate != null)) {
      filteredDocs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        DateTime collectedAt =
            (data['collectedAt'] as Timestamp?)?.toDate() ??
            (data['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now();

        if (_startDate != null && collectedAt.isBefore(_startDate!)) return false;
        if (_endDate != null && collectedAt.isAfter(_endDate!.add(const Duration(days: 1)))) return false;

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
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: kMainColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      localizations.filterByDateRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        label: _startDate != null ? _formatDate(_startDate!) : localizations.startDate,
                        icon: Icons.calendar_today,
                        onPressed: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        label: _endDate != null ? _formatDate(_endDate!) : localizations.endDate,
                        icon: Icons.event,
                        onPressed: () => _pickDate(isStart: false),
                      ),
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.clear, color: Colors.red[400]),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

        // Summary card for Today tab
        if (isToday)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kMainColor, kMainColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kMainColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.inventory_2,
                    title: localizations.totalCollections,
                    value: "$totalCollections",
                    subtitle: localizations.today,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.scale,
                    title: localizations.totalWeight,
                    value: "${totalWeight.toStringAsFixed(1)} kg",
                    subtitle: localizations.collected,
                  ),
                ),
              ],
            ),
          ),

        // Show filtered results count for Older tab with date range
        if (!isToday && (_startDate != null || _endDate != null))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Found ${filteredDocs.length} collections in selected date range",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final customerName = data['name']?.toString() ?? 'Unknown';
              final regNo = data['regNo']?.toString() ?? 'N/A';
              final weight = data['weight']?.toString() ?? 'N/A';
              DateTime collectedAt =
                  (data['collectedAt'] as Timestamp?)?.toDate() ??
                  (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              final date =
                  "${collectedAt.year}-${collectedAt.month.toString().padLeft(2, '0')}-${collectedAt.day.toString().padLeft(2, '0')}";
              final time =
                  "${collectedAt.hour.toString().padLeft(2, '0')}:${collectedAt.minute.toString().padLeft(2, '0')}";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDetailsDialog(data, localizations),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [kMainColor, kMainColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                customerName.isNotEmpty
                                    ? customerName[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      regNo,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.scale, size: 14, color: Colors.green[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$weight kg",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$date ${localizations.at}\n$time",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 11,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      localizations.collected,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(bool isToday, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              isToday ? Icons.today : Icons.history,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isToday ? localizations.noCollectionsToday : localizations.noCollectionHistory,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isToday 
                  ? localizations.noCollectionsTodayDescription
                  : localizations.noCollectionHistoryDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/collector_home'),
              icon: const Icon(Icons.add_location),
              label: Text(localizations.startCollecting),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
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

  void _showDetailsDialog(Map<String, dynamic> data, AppLocalizations localizations) {
    DateTime collectedAt =
        (data['collectedAt'] as Timestamp?)?.toDate() ??
        (data['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final date =
        "${collectedAt.year}-${collectedAt.month.toString().padLeft(2, '0')}-${collectedAt.day.toString().padLeft(2, '0')}";
    final time =
        "${collectedAt.hour.toString().padLeft(2, '0')}:${collectedAt.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar and name
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kMainColor, kMainColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        (data['name']?.toString() ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? localizations.collectionDetails,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations.completed,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Details section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.person,
                      label: localizations.customerName,
                      value: data['name'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.badge,
                      label: localizations.registrationNo,
                      value: data['regNo'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.scale,
                      label: localizations.weightCollected,
                      value: "${data['weight'] ?? 'N/A'} kg",
                      valueColor: Colors.green[700],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: localizations.collectionDate,
                      value: date,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: localizations.collectionTime,
                      value: time,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: localizations.collectedBy,
                      value: data['collectorName'] ?? localizations.collector,
                    ),
                    if (data['remarks'] != null && data['remarks'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.note,
                        label: localizations.remarks,
                        value: data['remarks'],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.close,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: kMainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: kMainColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: kMainColor,
            ),
          ),
          child: child!,
        );
      },
    );

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

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}