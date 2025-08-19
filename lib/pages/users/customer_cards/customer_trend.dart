import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    String collectionPath =
        widget.userType == "customer" ? "customers" : "collectors";

    final query = await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(widget.userId)
        .collection("harvests")
        .orderBy("date", descending: false)
        .get();

    final docs = query.docs;
    Map<String, double> grouped = {}; // key = period, value = total weight

    for (var doc in docs) {
      final data = doc.data();
      final timestamp = (data["date"] as Timestamp).toDate();
      final weight = (data["weight"] ?? 0).toDouble();

      String key;
      if (selectedFilter == "Weekly") {
        final week = ((int.parse(DateFormat("D").format(timestamp)) - 1) ~/ 7) + 1;
        key = "${timestamp.year}-W$week";
      } else if (selectedFilter == "Monthly") {
        key = DateFormat("yyyy-MM").format(timestamp);
      } else {
        key = DateFormat("yyyy").format(timestamp);
      }

      grouped[key] = (grouped[key] ?? 0) + weight;
    }

    // convert to spots
    List<FlSpot> spots = [];
    List<String> xLabels = [];
    int i = 0;
    grouped.forEach((key, value) {
      spots.add(FlSpot(i.toDouble(), value));
      xLabels.add(key);
      i++;
    });

    setState(() {
      chartData = spots;
      labels = xLabels;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        title: const Text("Harvest Trends"),
        backgroundColor: kMainColor,
        elevation: 0,
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
                  setState(() => selectedFilter = val!);
                  _loadTrendData();
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
                child: chartData.isEmpty
                    ? const Center(
                        child: Text(
                          "No data available",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) =>
                                    Text("${value.toInt()}kg",
                                        style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < labels.length) {
                                    return Text(
                                      labels[index],
                                      style: const TextStyle(fontSize: 10),
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
                              color: kMainColor,
                              belowBarData: BarAreaData(
                                show: true,
                                color: kMainColor.withOpacity(0.2),
                              ),
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
