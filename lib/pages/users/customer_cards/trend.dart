import 'package:TeaLink/constants/colors.dart';
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
  String selectedPeriod = 'All Time';
  double totalHarvest = 0.0;
  double averageWeight = 0.0;
  int totalCollections = 0;
  
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  
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
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    
    _animationController!.forward();
  }

  Future<void> _fetchHarvestData() async {
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .where('customerId', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'Collected')
          .orderBy('collectedAt', descending: false)
          .get();

      final records = <HarvestRecord>[];
      final spots = <FlSpot>[];
      double total = 0.0;
      
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();
        
        final weight = (data['weight'] ?? 0.0).toDouble();
        final collectedAt = (data['collectedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        final record = HarvestRecord(
          weight: weight,
          date: collectedAt,
          customerName: data['name'] ?? 'Unknown',
          regNo: data['regNo'] ?? 'N/A',
        );
        
        records.add(record);
        spots.add(FlSpot(i.toDouble(), weight));
        total += weight;
      }

      setState(() {
        harvestRecords = records;
        chartData = spots;
        totalHarvest = total;
        totalCollections = records.length;
        averageWeight = records.isNotEmpty ? total / records.length : 0.0;
        isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Harvest Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: kMainColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchHarvestData,
          ),
        ],
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading harvest data...'),
                ],
              ),
            )
          : harvestRecords.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation!,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Harvest Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start collecting harvests to see trends',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredRecords = _getFilteredRecords();
    final filteredChartData = _getFilteredChartData();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics Cards
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Total Harvest', '${totalHarvest.toStringAsFixed(1)} kg', Icons.scale, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Collections', '$totalCollections', Icons.collections, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Average', '${averageWeight.toStringAsFixed(1)} kg', Icons.analytics, Colors.orange)),
              ],
            ),
          ),

          // Period Filter
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Period: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All Time', 'Last 7 Days', 'Last 30 Days', 'Last 3 Months']
                          .map((period) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(period),
                                  selected: selectedPeriod == period,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => selectedPeriod = period);
                                    }
                                  },
                                  selectedColor: kMainColor.withOpacity(0.2),
                                  checkmarkColor: kMainColor,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chart
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
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
                Text(
                  'Harvest Trends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Weight (kg) over time',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: filteredChartData.isEmpty
                      ? Center(
                          child: Text(
                            'No data for selected period',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
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
                                  color: Colors.grey[300]!,
                                  strokeWidth: 0.5,
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
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('MM/dd').format(record.date),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
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
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}kg',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
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
                                gradient: LinearGradient(
                                  colors: [kMainColor, kMainColor.withOpacity(0.8)],
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: kMainColor,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
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

          // Recent Collections List
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
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
                Text(
                  'Recent Collections',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                ...filteredRecords.reversed
                    .take(5)
                    .map((record) => _buildCollectionItem(record))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kMainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.scale, color: kMainColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(record.date),
                  style: TextStyle(
                    fontSize: 12,
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
}

class HarvestRecord {
  final double weight;
  final DateTime date;
  final String customerName;
  final String regNo;

  HarvestRecord({
    required this.weight,
    required this.date,
    required this.customerName,
    required this.regNo,
  });
}