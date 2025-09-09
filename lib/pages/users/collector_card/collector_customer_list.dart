import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/pages/users/collector_card/add_weight.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorNotificationPage extends StatefulWidget {
  final String collectorId;

  const CollectorNotificationPage({super.key, required this.collectorId});

  @override
  _CollectorNotificationPageState createState() =>
      _CollectorNotificationPageState();
}

class _CollectorNotificationPageState extends State<CollectorNotificationPage> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final CollectionReference notifyCollection =
        FirebaseFirestore.instance.collection('notify_for_collection');

    // ✅ Get start & end of today
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

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
        actions: [
          // ✅ Notification count for TODAY only
          StreamBuilder<QuerySnapshot>(
            stream: notifyCollection
                .where('collectorId', isEqualTo: widget.collectorId)
                .where('status', isEqualTo: 'Pending')
                .where('createdAt',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('createdAt',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.red : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ Notifications list for TODAY only
        stream: notifyCollection
            .where('collectorId', isEqualTo: widget.collectorId)
            .where('status', isEqualTo: 'Pending')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading notifications..."),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Failed to load notifications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: kMainColor),
                    child: const Text("Retry",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off,
                      size: 60,
                      color: Colors.green[300],
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "All Caught Up!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "No pending collection requests",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "All customers have been collected today",
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kMainColor, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: kMainColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "${notifications.length} Pending Collection${notifications.length > 1 ? 's' : ''}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Notifications list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(
                        const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};

                      final customerName =
                          data['name']?.toString() ?? 'Unknown';
                      final regNo = data['regNo']?.toString() ?? 'N/A';

                      DateTime createdAt;
                      try {
                        createdAt =
                            (data['createdAt'] as Timestamp).toDate();
                      } catch (_) {
                        createdAt = DateTime.now();
                      }

                      final date =
                          "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
                      final time =
                          "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

                      final now = DateTime.now();
                      final difference = now.difference(createdAt);
                      String timeAgo;
                      if (difference.inMinutes < 60) {
                        timeAgo = "${difference.inMinutes}m ago";
                      } else if (difference.inHours < 24) {
                        timeAgo = "${difference.inHours}h ago";
                      } else {
                        timeAgo = "${difference.inDays}d ago";
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(
                                left: 16, top: 8, bottom: 8, right: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.green[700],
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
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              customerName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Reg No: $regNo',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 12,
                                        color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                          '$timeAgo • $date at $time',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 70,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  "Collect",
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddWeightPage(
                                        customerName: customerName,
                                        regNo: regNo,
                                        docReference: doc.reference,
                                        customerId:
                                            data['customerId'] ?? 'unknown',
                                      ),
                                    ),
                                  );

                                  // ✅ REMOVED DUPLICATE WEEKLY DATA UPDATE
                                  // The weekly data is now handled entirely in AddWeightPage
                                  if (result is Map<String, dynamic> && result['success'] == true) {
                                    if (!mounted) return;
                                    
                                    double weight = result['weight']?.toDouble() ?? 0.0;
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$customerName collected successfully (${weight}kg)',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(
                                            bottom: 80,
                                            left: 16,
                                            right: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  } else if (result == true) {
                                    // Fallback for old return format
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$customerName collected successfully',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration:
                                            const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(
                                            bottom: 80,
                                            left: 16,
                                            right: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
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
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: kMainColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 26),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_sharp, size: 26),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history, size: 26),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 26),
                label: 'Profile',
              ),
            ],
          ),
        ),
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
}