import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HarvestTrendsPage extends StatefulWidget {
  const HarvestTrendsPage({super.key});

  @override
  State<HarvestTrendsPage> createState() => _HarvestTrendsPageState();
}

class _HarvestTrendsPageState extends State<HarvestTrendsPage> 
    with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  List<FlSpot> chartData = [];
  List<HarvestRecord> harvestRecords = [];
  bool isLoading = true;
  String selectedPeriod = 'Last 30 Days';
  double totalHarvest = 0.0;
  double averageWeight = 0.0;
  int totalCollections = 0;
  double highestHarvest = 0.0;
  int _selectedIndex = 1;
  
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchHarvestData();
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // Safe type conversion function
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing weight string "$value": $e');
        return 0.0;
      }
    }
    return 0.0;
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
    
    _animationController!.forward();
  }

  Future<void> _fetchHarvestData() async {
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      // Query with better error handling and debugging
      print('Fetching data for user: ${user!.uid}');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .where('customerId', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'Collected')
          .get();

      print('Found ${querySnapshot.docs.length} collected records');

      final records = <HarvestRecord>[];
      double total = 0.0;
      double highest = 0.0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print('Document data: $data'); // Debug print
        
        // Use safe conversion instead of direct toDouble()
        final weight = _safeToDouble(data['weight']);
        final collectedAt = (data['collectedAt'] as Timestamp?)?.toDate() ?? 
                          (data['createdAt'] as Timestamp?)?.toDate() ?? 
                          DateTime.now();
        
        if (weight > 0) { // Only add records with valid weight
          final record = HarvestRecord(
            weight: weight,
            date: collectedAt,
            customerName: data['name'] ?? 'Unknown',
            regNo: data['regNo'] ?? 'N/A',
            collectorId: data['collectorId'] ?? 'Unknown',
          );
          
          records.add(record);
          total += weight;
          if (weight > highest) highest = weight;
        }
      }

      // Sort records by date
      records.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        harvestRecords = records;
        totalHarvest = total;
        totalCollections = records.length;
        averageWeight = records.isNotEmpty ? total / records.length : 0.0;
        highestHarvest = highest;
        isLoading = false;
      });
      
      print('Updated state: ${records.length} records, total: $total kg');
    } catch (e) {
      print('Error fetching harvest data: $e');
      setState(() => isLoading = false);
    }
  }

  List<HarvestRecord> _getFilteredRecords() {
    final now = DateTime.now();
    DateTime cutoffDate;
    
    switch (selectedPeriod) {
      case 'Last 7 Days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case 'Last 3 Months':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case 'Last 6 Months':
        cutoffDate = now.subtract(const Duration(days: 180));
        break;
      default:
        return harvestRecords;
    }
    
    return harvestRecords.where((record) => record.date.isAfter(cutoffDate)).toList();
  }

  List<FlSpot> _getFilteredChartData() {
    final filteredRecords = _getFilteredRecords();
    return filteredRecords
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weight))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          loc.harvestTrends,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: kMainColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchHarvestData,
          ),
        ],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kMainColor, kMainColor.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState(loc)
          : harvestRecords.isEmpty
              ? _buildEmptyState(loc)
              : FadeTransition(
                  opacity: _fadeAnimation!,
                  child: _buildContent(loc),
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: kMainColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded, size: 24),
                label: loc.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.trending_up, size: 24),
                label: loc.trends,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.payments, size: 24),
                label: loc.payments,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person, size: 24),
                label: loc.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            loc.startuptitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.startupdescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.teal.shade200,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.trending_up,
                size: 60,
                color: kMainColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              loc.totalHarvest,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.harvestTrendsDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.contactCollector,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    final filteredRecords = _getFilteredRecords();
    final filteredChartData = _getFilteredChartData();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Enhanced Statistics Cards
          Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      loc.totalHarvest, 
                      '${totalHarvest.toStringAsFixed(1)} kg', 
                      Icons.eco, 
                      Colors.green,
                      '${totalCollections} collections'
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
                      loc.averageWeight, 
                      '${averageWeight.toStringAsFixed(1)} kg', 
                      Icons.analytics_outlined, 
                      Colors.blue,
                      'per collection'
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      loc.highestHarvest, 
                      '${highestHarvest.toStringAsFixed(1)} kg', 
                      Icons.trending_up, 
                      Colors.orange,
                      'single collection'
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
                      loc.collections, 
                      '$totalCollections', 
                      Icons.calendar_month, 
                      Colors.purple,
                      'total records'
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Enhanced Period Filter
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      loc.timePeriod,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last 6 Months', 'All Time']
                        .map((period) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  period,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: selectedPeriod == period ? Colors.white : Colors.grey[700],
                                  ),
                                ),
                                selected: selectedPeriod == period,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => selectedPeriod = period);
                                  }
                                },
                                selectedColor: kMainColor,
                                backgroundColor: Colors.grey[100],
                                checkmarkColor: Colors.white,
                                elevation: selectedPeriod == period ? 2 : 0,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Chart
          ScaleTransition(
            scale: _scaleAnimation!,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kMainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.show_chart,
                          color: kMainColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harvest Trends',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Weight (kg) over time \n$selectedPeriod',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 320,
                    child: filteredChartData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No data for selected period',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try selecting a different time period',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: _calculateInterval(filteredChartData),
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: _calculateBottomInterval(filteredChartData.length),
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < filteredRecords.length) {
                                        final record = filteredRecords[value.toInt()];
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Text(
                                            DateFormat('MM/dd').format(record.date),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: _calculateInterval(filteredChartData),
                                    reservedSize: 45,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          '${value.toInt()}kg',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                  left: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: filteredChartData,
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  gradient: LinearGradient(
                                    colors: [
                                      kMainColor,
                                      kMainColor.withOpacity(0.8),
                                    ],
                                  ),
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 6,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                        strokeColor: kMainColor,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        kMainColor.withOpacity(0.3),
                                        kMainColor.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              minY: 0,
                              maxY: _calculateMaxY(filteredChartData),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Enhanced Recent Collections
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Collections',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (filteredRecords.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No recent collections',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredRecords.reversed
                      .take(5)
                      .map((record) => _buildCollectionItem(record))
                      .toList(),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(HarvestRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kMainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.eco, color: kMainColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${record.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Collected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM dd, yyyy - h:mm a').format(record.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1;
    final maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return (maxY / 5).ceilToDouble();
  }

  double _calculateBottomInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    if (dataLength <= 20) return 4;
    return (dataLength / 5).ceilToDouble();
  }

  double _calculateMaxY(List<FlSpot> data) {
    if (data.isEmpty) return 10;
    final maxValue = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

 void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/customer_home');
        break;
      case 1:
        Navigator.pushNamed(context, '/customer_trends');
        break;
      case 2:
        Navigator.pushNamed(context, '/customer_payments');
        break;
      case 3:
        Navigator.pushNamed(context, '/customer_profile');
        break;
    }
  }
}

class HarvestRecord {
  final double weight;
  final DateTime date;
  final String customerName;
  final String regNo;
  final String collectorId;

  HarvestRecord({
    required this.weight,
    required this.date,
    required this.customerName,
    required this.regNo,
    required this.collectorId,
  });
}