import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:intl/intl.dart';

class TrendPage extends StatefulWidget {
  final String userId;      // pass customer/collector id
  final String userType;    // "customer" or "collector"

  const TrendPage({super.key, required this.userId, required this.userType});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  String selectedFilter = "Weekly"; // Weekly, Monthly, Yearly
  List<FlSpot> chartData = [];
  List<String> labels = []; // for bottom axis labels
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    setState(() => isLoading = true);

    try {
      // Fetch data from notify_for_collection where weight data is actually stored
      final query = await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .where('customerId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'Collected')
          .orderBy('collectedAt', descending: false)
          .get();

      final docs = query.docs;
      print('Found ${docs.length} documents for user ${widget.userId}'); // Debug log
      
      Map<String, double> grouped = {}; // key = period, value = total weight

      for (var doc in docs) {
        final data = doc.data();
        
        // Get the collection timestamp
        final collectedAt = (data['collectedAt'] as Timestamp?)?.toDate();
        if (collectedAt == null) continue;
        
        // Get the weight
        final weight = (data['weight'] ?? 0).toDouble();
        if (weight <= 0) continue;

        String key;
        if (selectedFilter == "Weekly") {
          // Calculate week number within the month
          final dayOfMonth = collectedAt.day;
          final week = ((dayOfMonth - 1) ~/ 7) + 1;
          key = "${collectedAt.year}-${collectedAt.month.toString().padLeft(2, '0')}-W$week";
        } else if (selectedFilter == "Monthly") {
          key = DateFormat("yyyy-MM").format(collectedAt);
        } else {
          key = DateFormat("yyyy").format(collectedAt);
        }

        grouped[key] = (grouped[key] ?? 0) + weight;
      }

      // Convert to spots and sort by date
      List<MapEntry<String, double>> sortedEntries = grouped.entries.toList();
      
      // Sort entries by date
      sortedEntries.sort((a, b) {
        try {
          if (selectedFilter == "Weekly") {
            // Extract year, month, week from format "2024-01-W1"
            final aParts = a.key.split('-');
            final bParts = b.key.split('-');
            final aYear = int.parse(aParts[0]);
            final bYear = int.parse(bParts[0]);
            if (aYear != bYear) return aYear.compareTo(bYear);
            
            final aMonth = int.parse(aParts[1]);
            final bMonth = int.parse(bParts[1]);
            if (aMonth != bMonth) return aMonth.compareTo(bMonth);
            
            final aWeek = int.parse(aParts[2].substring(1)); // Remove 'W'
            final bWeek = int.parse(bParts[2].substring(1));
            return aWeek.compareTo(bWeek);
          } else {
            return a.key.compareTo(b.key);
          }
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });

      List<FlSpot> spots = [];
      List<String> xLabels = [];
      
      for (int i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        spots.add(FlSpot(i.toDouble(), entry.value));
        
        // Format label for display
        String displayLabel;
        if (selectedFilter == "Weekly") {
          displayLabel = entry.key; // Keep full format for weekly
        } else if (selectedFilter == "Monthly") {
          final date = DateTime.parse("${entry.key}-01");
          displayLabel = DateFormat("MMM yyyy").format(date);
        } else {
          displayLabel = entry.key;
        }
        
        xLabels.add(displayLabel);
      }

      setState(() {
        chartData = spots;
        labels = xLabels;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading trend data: $e');
      setState(() {
        chartData = [];
        labels = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        title: const Text(
          "Harvest Trends",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔽 Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: selectedFilter,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down),
                isExpanded: true,
                items: ["Weekly", "Monthly", "Yearly"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedFilter = val);
                    _loadTrendData();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // 🔽 Chart Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(2, 6),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Loading trend data...", 
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : chartData.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.trending_up, 
                                    size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "No harvest data available",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Start collecting harvests to see trends",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Harvest Weight Trends ($selectedFilter)",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _calculateYInterval(),
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[300]!,
                                          strokeWidth: 0.5,
                                        );
                                      },
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey.shade300),
                                        left: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 45,
                                          interval: _calculateYInterval(),
                                          getTitlesWidget: (value, meta) =>
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Text(
                                                  "${value.toInt()}kg",
                                                  style: const TextStyle(
                                                      fontSize: 12, color: Colors.grey),
                                                ),
                                              ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: _calculateXInterval(),
                                          getTitlesWidget: (value, meta) {
                                            int index = value.toInt();
                                            if (index >= 0 && index < labels.length) {
                                              String label = labels[index];
                                              // Truncate long labels
                                              if (label.length > 8) {
                                                label = label.substring(0, 8) + "...";
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  label,
                                                  style: const TextStyle(
                                                      fontSize: 10, color: Colors.grey),
                                                ),
                                              );
                                            }
                                            return const Text("");
                                          },
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: chartData,
                                        isCurved: true,
                                        barWidth: 3,
                                        gradient: LinearGradient(
                                          colors: [kMainColor, kMainColor.withOpacity(0.8)],
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
                                        isStrokeCapRound: true,
                                      ),
                                    ],
                                    minY: 0,
                                    maxY: _calculateMaxY(),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateYInterval() {
    if (chartData.isEmpty) return 1;
    final maxY = chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return (maxY / 5).ceilToDouble();
  }

  double _calculateXInterval() {
    if (chartData.length <= 5) return 1;
    if (chartData.length <= 10) return 2;
    return (chartData.length / 5).ceilToDouble();
  }

  double _calculateMaxY() {
    if (chartData.isEmpty) return 10;
    final maxValue = chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }
}