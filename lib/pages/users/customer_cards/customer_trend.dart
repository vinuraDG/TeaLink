import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerTrendsPage extends StatefulWidget {
  const CustomerTrendsPage({super.key});

  @override
  State<CustomerTrendsPage> createState() => _CustomerTrendsPageState();
}

class _CustomerTrendsPageState extends State<CustomerTrendsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String selectedFilter = "Weekly"; // Weekly, Monthly, Yearly
  List<FlSpot> chartData = [];

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    if (user == null) return;
    final regNumber = user!.uid; // using uid as reg number

    final query = await FirebaseFirestore.instance
        .collection("customers")
        .doc(regNumber)
        .collection("harvests")
        .orderBy("date", descending: false)
        .get();

    final docs = query.docs;
    List<FlSpot> spots = [];
    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data();
      spots.add(FlSpot(i.toDouble(), (data["weight"] ?? 0).toDouble()));
    }

    setState(() {
      chartData = spots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Harvest Trends"),
        backgroundColor: kMainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedFilter,
              items: ["Weekly", "Monthly", "Yearly"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() => selectedFilter = val!);
                _loadTrendData(); // can extend logic for monthly/yearly
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true),
                    )
                  ],
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
