// view_harvests_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewHarvestsPage extends StatefulWidget {
  @override
  _ViewHarvestsPageState createState() => _ViewHarvestsPageState();
}

class _ViewHarvestsPageState extends State<ViewHarvestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _harvests = [];
  Map<String, List<Map<String, dynamic>>> _customerHarvests = {};
  Map<String, String> _customerNames = {};
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadHarvests();
    // Auto refresh every minute to update data
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Refresh data every 60 seconds
    Stream.periodic(Duration(seconds: 60)).listen((_) {
      if (mounted && _isAdmin) {
        _loadTodayHarvests();
      }
    });
  }

  Future<void> _checkAdminAndLoadHarvests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if current user is admin
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User document not found';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role']?.toString().toLowerCase() ?? '';
      
      if (role != 'admin') {
        setState(() {
          _errorMessage = 'Access denied. Admin privileges required.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isAdmin = true;
      });

      // Load today's harvests by default
      await _loadTodayHarvests();

    } catch (e) {
      print('Error in _checkAdminAndLoadHarvests: $e');
      setState(() {
        _errorMessage = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodayHarvests() async {
    if (!_isAdmin) {
      setState(() {
        _errorMessage = 'Admin access required';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('Loading today\'s harvests...');
      
      // Get start and end of selected date
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      
      // Query harvests for the selected date
      // First try with date filtering, fallback to all data if permissions fail
      List<QueryDocumentSnapshot> harvestDocs;
      try {
        final harvestsSnapshot = await _firestore
            .collection('harvest_value')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .orderBy('createdAt', descending: true)
            .get();
        harvestDocs = harvestsSnapshot.docs;
      } catch (e) {
        print('Date query failed, trying simple query: $e');
        // Fallback: get all harvests and filter locally
        final harvestsSnapshot = await _firestore
            .collection('harvest_value')
            .orderBy('createdAt', descending: true)
            .get();
        
        // Filter locally for the selected date
        harvestDocs = harvestsSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] == null) return false;
          
          final docDate = (data['createdAt'] as Timestamp).toDate();
          return docDate.year == _selectedDate.year &&
                 docDate.month == _selectedDate.month &&
                 docDate.day == _selectedDate.day;
        }).toList();
      }
      
      print('Harvests loaded successfully: ${harvestDocs.length} documents for ${_selectedDate.toString().split(' ')[0]}');
      
      // Group harvests by customer and get customer names
      await _groupHarvestsByCustomer(harvestDocs);
      
      setState(() {
        _harvests = harvestDocs;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Error loading harvests: $e');
      setState(() {
        _errorMessage = 'Error loading harvests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _groupHarvestsByCustomer(List<QueryDocumentSnapshot> harvests) async {
    Map<String, List<Map<String, dynamic>>> customerHarvests = {};
    Map<String, String> customerNames = {};
    
    for (var harvest in harvests) {
      final harvestData = harvest.data() as Map<String, dynamic>;
      final customerId = harvestData['customerId'] ?? '';
      final customerRegNo = harvestData['customerRegNo'] ?? '';
      
      if (customerId.isNotEmpty) {
        // Add harvest to customer group
        if (!customerHarvests.containsKey(customerId)) {
          customerHarvests[customerId] = [];
        }
        
        customerHarvests[customerId]!.add({
          'id': harvest.id,
          'data': harvestData,
        });
        
        // Get customer name if not already fetched
        if (!customerNames.containsKey(customerId)) {
          try {
            final customerDoc = await _firestore.collection('users').doc(customerId).get();
            if (customerDoc.exists) {
              final customerData = customerDoc.data() as Map<String, dynamic>;
              final name = customerData['name'] ?? 'Unknown Customer';
              customerNames[customerId] = '$name (Reg: $customerRegNo)';
            } else {
              customerNames[customerId] = 'Unknown Customer (Reg: $customerRegNo)';
            }
          } catch (e) {
            print('Error fetching customer name for $customerId: $e');
            customerNames[customerId] = 'Unknown Customer (Reg: $customerRegNo)';
          }
        }
      }
    }
    
    setState(() {
      _customerHarvests = customerHarvests;
      _customerNames = customerNames;
    });
  }

  // Keep the original _loadHarvests method for legacy refresh button
  Future<void> _loadHarvests() async {
    await _loadTodayHarvests();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadTodayHarvests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Daily Harvest Report', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Customer Harvest Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    if (_customerHarvests.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_customerHarvests.length} customers',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _isAdmin ? _loadTodayHarvests : _checkAdminAndLoadHarvests,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Date: ${_selectedDate.toString().split(' ')[0]}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _selectDate,
                      icon: Icon(Icons.date_range, size: 16),
                      label: Text('Change Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total: ${_harvests.length} records',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTodayHarvests,
        backgroundColor: Colors.green[600],
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh Today\'s Data',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading daily harvest data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkAdminAndLoadHarvests,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_customerHarvests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No harvests found for ${_selectedDate.toString().split(' ')[0]}', 
                 style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Harvest records for the selected date will appear here', 
                 style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodayHarvests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _customerHarvests.length,
        itemBuilder: (context, index) {
          final customerId = _customerHarvests.keys.elementAt(index);
          final customerHarvests = _customerHarvests[customerId]!;
          final customerName = _customerNames[customerId] ?? 'Unknown Customer';
          
          // Calculate total weight for this customer
          double totalWeight = 0;
          for (var harvest in customerHarvests) {
            totalWeight += (harvest['data']['weight'] ?? 0).toDouble();
          }
          
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[600],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                customerName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Total Weight: ${totalWeight.toStringAsFixed(1)} kg'),
                  Text('Collections: ${customerHarvests.length}'),
                ],
              ),
              children: customerHarvests.map((harvest) {
                final harvestData = harvest['data'] as Map<String, dynamic>;
                final harvestId = harvest['id'] as String;
                
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    'Weight: ${harvestData['weight'] ?? 0} kg',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Collector ID: ${harvestData['collectorId'] ?? 'N/A'}'),
                      if (harvestData['createdAt'] != null)
                        Text('Time: ${_formatTimestamp(harvestData['createdAt'])}'),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${harvestId.substring(0, 8)}...',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.green),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _viewHarvestDetails(harvestId, harvestData);
                      } else if (value == 'edit') {
                        _editHarvest(harvestId, harvestData);
                      } else if (value == 'delete') {
                        _deleteHarvest(harvestId);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _viewHarvestDetails(String harvestId, Map<String, dynamic> harvestData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Harvest Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Harvest ID:', harvestId),
              _buildDetailRow('Weight:', '${harvestData['weight'] ?? 'N/A'} kg'),
              _buildDetailRow('Customer Reg No:', harvestData['customerRegNo'] ?? 'N/A'),
              _buildDetailRow('Customer ID:', harvestData['customerId'] ?? 'N/A'),
              _buildDetailRow('Collector ID:', harvestData['collectorId'] ?? 'N/A'),
              _buildDetailRow('Created At:', _formatTimestamp(harvestData['createdAt'])),
              if (harvestData['updatedAt'] != null)
                _buildDetailRow('Updated At:', _formatTimestamp(harvestData['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editHarvest(String harvestId, Map<String, dynamic> harvestData) {
    final weightController = TextEditingController(text: harvestData['weight']?.toString() ?? '');
    final regNoController = TextEditingController(text: harvestData['customerRegNo'] ?? '');
    final customerIdController = TextEditingController(text: harvestData['customerId'] ?? '');
    final collectorIdController = TextEditingController(text: harvestData['collectorId'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Harvest'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12),
              TextField(
                controller: regNoController,
                decoration: InputDecoration(
                  labelText: 'Customer Reg No',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_membership),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: customerIdController,
                decoration: InputDecoration(
                  labelText: 'Customer ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: collectorIdController,
                decoration: InputDecoration(
                  labelText: 'Collector ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightController.text);
              if (weight == null || weight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid weight')),
                );
                return;
              }

              if (regNoController.text.trim().isEmpty || 
                  customerIdController.text.trim().isEmpty || 
                  collectorIdController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              try {
                await _firestore.collection('harvest_value').doc(harvestId).update({
                  'weight': weight,
                  'customerRegNo': regNoController.text.trim(),
                  'customerId': customerIdController.text.trim(),
                  'collectorId': collectorIdController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Harvest updated successfully')),
                );
                await _loadTodayHarvests(); // Refresh the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating harvest: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteHarvest(String harvestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Harvest'),
        content: Text('Are you sure you want to delete this harvest record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('harvest_value').doc(harvestId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Harvest deleted successfully')),
                );
                await _loadTodayHarvests(); // Refresh the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting harvest: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}