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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadHarvests();
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

      // Load harvests manually if admin
      await _loadHarvests();

    } catch (e) {
      print('Error in _checkAdminAndLoadHarvests: $e');
      setState(() {
        _errorMessage = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHarvests() async {
    if (!_isAdmin) {
      setState(() {
        _errorMessage = 'Admin access required';
        _isLoading = false;
      });
      return;
    }

    try {
      print('Loading harvests...');
      final harvestsSnapshot = await _firestore
          .collection('harvest_value')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('Harvests loaded successfully: ${harvestsSnapshot.docs.length} documents');
      
      setState(() {
        _harvests = harvestsSnapshot.docs;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('View Harvests', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  'Harvests Management',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (_harvests.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_harvests.length} records',
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
                  onPressed: _isAdmin ? _loadHarvests : _checkAdminAndLoadHarvests,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
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
            Text('Loading harvests...'),
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

    if (_harvests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No harvests found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Harvest records will appear here once collectors start recording data', 
                 style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHarvests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _harvests.length,
        itemBuilder: (context, index) {
          final harvest = _harvests[index];
          final harvestData = harvest.data() as Map<String, dynamic>;
          
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.eco, color: Colors.white),
              ),
              title: Text(
                'Weight: ${harvestData['weight'] ?? 0} kg',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Customer Reg: ${harvestData['customerRegNo'] ?? 'N/A'}'),
                  Text('Customer ID: ${harvestData['customerId'] ?? 'N/A'}'),
                  Text('Collector ID: ${harvestData['collectorId'] ?? 'N/A'}'),
                  if (harvestData['createdAt'] != null)
                    Text('Date: ${_formatTimestamp(harvestData['createdAt'])}'),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ID: ${harvest.id}',
                      style: TextStyle(fontSize: 10, color: Colors.green[700]),
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
                    _viewHarvestDetails(harvest.id, harvestData);
                  } else if (value == 'edit') {
                    _editHarvest(harvest.id, harvestData);
                  } else if (value == 'delete') {
                    _deleteHarvest(harvest.id);
                  }
                },
              ),
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
                await _loadHarvests(); // Refresh the list
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
                await _loadHarvests(); // Refresh the list
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