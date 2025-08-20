import 'package:TeaLink/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorNotificationPage extends StatelessWidget {
  final String collectorId;

  const CollectorNotificationPage({super.key, required this.collectorId});

  @override
  Widget build(BuildContext context) {
    final CollectionReference notifyCollection =
        FirebaseFirestore.instance.collection('notify_for_collection');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Customer Notifications",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kWhite,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: kMainColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notifyCollection
            .where('collectorId', isEqualTo: collectorId)
            .where('status', isEqualTo: 'Pending')
            // Use startAt to avoid errors if some docs are missing createdAt
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Failed to load notifications.\nError: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No pending notifications",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "All customers have been collected today",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final customerName = data['name']?.toString() ?? 'Unknown';
              final regNo = data['regNo']?.toString() ?? 'N/A';

              // Safely parse createdAt
              DateTime createdAt;
              try {
                createdAt = (data['createdAt'] as Timestamp).toDate();
              } catch (_) {
                createdAt = DateTime.now();
              }

              final date =
                  "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
              final time =
                  "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.green[700],
                    child: Text(
                      customerName.isNotEmpty ? customerName[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    customerName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Reg No: $regNo', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Requested: $date at $time', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      "Mark as Collected",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onPressed: () async {
                      try {
                        await doc.reference.update({'status': 'Collected'});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$customerName marked as Collected'), duration: const Duration(seconds: 1)),
                        );
                        // StreamBuilder auto-updates
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e'), duration: const Duration(seconds: 2)),
                        );
                      }
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
