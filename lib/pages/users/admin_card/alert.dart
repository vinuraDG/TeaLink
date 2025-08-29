// check_alerts_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckAlertsPage extends StatefulWidget {
  @override
  _CheckAlertsPageState createState() => _CheckAlertsPageState();
}

class _CheckAlertsPageState extends State<CheckAlertsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkForAlerts();
  }

  Future<void> _checkForAlerts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final harvestsSnapshot = await _firestore.collection('harvest_value').get();
      List<Map<String, dynamic>> newAlerts = [];
      
      // Group harvests by date and customer
      Map<String, Map<String, List<DocumentSnapshot>>> harvestsByDateAndCustomer = {};
      
      for (var doc in harvestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['createdAt'] as Timestamp?;
        final customerRegNo = data['customerRegNo']?.toString() ?? 'Unknown';
        
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month}-${date.day}';
          
          harvestsByDateAndCustomer[dateKey] ??= {};
          harvestsByDateAndCustomer[dateKey]![customerRegNo] ??= [];
          harvestsByDateAndCustomer[dateKey]![customerRegNo]!.add(doc);
        }
      }
      
      // Check for duplicate weights on same day
      harvestsByDateAndCustomer.forEach((date, customerMap) {
        customerMap.forEach((customer, harvests) {
          if (harvests.length > 1) {
            // Multiple entries for same customer on same day
            final weights = harvests.map((h) => (h.data() as Map<String, dynamic>)['weight']?.toString() ?? '0').toList();
            newAlerts.add({
              'type': 'duplicate_entries',
              'title': 'Multiple Entries Detected',
              'description': 'Customer $customer has ${harvests.length} entries on $date',
              'severity': 'high',
              'date': date,
              'customer': customer,
              'weights': weights,
            });
          }
          
          // Check for duplicate weights
          Map<String, int> weightCount = {};
          for (var harvest in harvests) {
            final weight = (harvest.data() as Map<String, dynamic>)['weight']?.toString() ?? '0';
            weightCount[weight] = (weightCount[weight] ?? 0) + 1;
          }
          
          weightCount.forEach((weight, count) {
            if (count > 1) {
              newAlerts.add({
                'type': 'duplicate_weight',
                'title': 'Duplicate Weight Alert',
                'description': 'Weight $weight kg appears $count times for customer $customer on $date',
                'severity': 'medium',
                'date': date,
                'customer': customer,
                'weight': weight,
                'count': count,
              });
            }
          });
        });
      });
      
      // Check for missed collections (no harvest for more than 7 days)
      final now = DateTime.now();
      final customersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'customer').get();
      
      for (var customerDoc in customersSnapshot.docs) {
        final customerData = customerDoc.data();
        final regNo = customerData['regNo']?.toString();
        
        if (regNo != null) {
          final lastHarvestQuery = await _firestore
              .collection('harvest_value')
              .where('customerRegNo', isEqualTo: regNo)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          if (lastHarvestQuery.docs.isNotEmpty) {
            final lastHarvest = lastHarvestQuery.docs.first;
            final lastHarvestDate = (lastHarvest.data()['createdAt'] as Timestamp).toDate();
            final daysDifference = now.difference(lastHarvestDate).inDays;
            
            if (daysDifference > 7) {
              newAlerts.add({
                'type': 'missed_collection',
                'title': 'Missed Collection Alert',
                'description': 'Customer $regNo has no collections for $daysDifference days',
                'severity': 'low',
                'customer': regNo,
                'daysMissed': daysDifference,
              });
            }
          } else {
            // Customer has never had any harvests
            newAlerts.add({
              'type': 'no_collection',
              'title': 'No Collections Found',
              'description': 'Customer $regNo has never had any collections',
              'severity': 'medium',
              'customer': regNo,
            });
          }
        }
      }
      
      if (mounted) {
        setState(() {
          alerts = newAlerts;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking alerts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Data Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Data Alerts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _checkForAlerts,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text('No alerts found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            Text('All data looks good!', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getAlertColor(alert['severity']),
                                child: Icon(
                                  _getAlertIcon(alert['type']),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                alert['title'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert['description']),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getAlertColor(alert['severity']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      alert['severity'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getAlertColor(alert['severity']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.yellow[700]!;
      default: return Colors.grey;
    }
  }

  IconData _getAlertIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'duplicate_entries': return Icons.content_copy;
      case 'duplicate_weight': return Icons.scale;
      case 'missed_collection': return Icons.schedule;
      case 'no_collection': return Icons.block;
      default: return Icons.warning;
    }
  }
}