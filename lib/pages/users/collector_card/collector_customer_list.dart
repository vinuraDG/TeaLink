import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorCustomerListPage extends StatelessWidget {
  final String collectorId;

  const CollectorCustomerListPage({super.key, required this.collectorId});

  @override
  Widget build(BuildContext context) {
    // Define start and end of today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Today's Customer List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('collectors')
            .doc(collectorId)
            .collection('todayHarvest')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .orderBy('timestamp', descending: false) // oldest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No customers have notified today.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final customers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: customers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = customers[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? "Unknown";
              final regNo = data['regNo'] ?? "N/A";
              final status = data['status'] ?? "Pending";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: status == "Collected"
                        ? Colors.grey
                        : Colors.green[700],
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("RegNo: $regNo"),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              "Status: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              status,
                              style: TextStyle(
                                color: status == "Collected"
                                    ? Colors.grey[700]
                                    : Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: status == "Collected"
    ? const Icon(Icons.check_circle, color: Colors.grey, size: 30)
    : IconButton(
        icon: const Icon(Icons.check_circle,
            color: Colors.green, size: 32),
        tooltip: "Mark as Collected",
        onPressed: () async {
          final docId = customers[index].id; // use Firestore doc ID
          await FirebaseFirestore.instance
              .collection('collectors')
              .doc(collectorId)
              .collection('todayHarvest')
              .doc(docId)
              .update({'status': "Collected"});
        },
      ),

                ),
              );
            },
          );
        },
      ),
    );
  }
}
