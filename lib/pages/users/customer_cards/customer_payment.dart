import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CustomerPaymentPage extends StatefulWidget {
  final String customerId;
  
  const CustomerPaymentPage({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<PaymentSlipData> _paymentSlips = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _customerName = '';
  String _filterStatus = 'all'; // all, verified, pending

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
    _loadPaymentSlips();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.customerId).get();
      if (userDoc.exists) {
        setState(() {
          _customerName = userDoc.data()?['name'] ?? 'Customer';
        });
      }
    } catch (e) {
      print('Error loading customer info: $e');
    }
  }

  Future<void> _loadPaymentSlips() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<PaymentSlipData> slips = [];

      // Load payment records from Firestore
      // Note: Ensure customer_code matches the customerId being passed
      print('Loading payments for customer: ${widget.customerId}');
      
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('customer_code', isEqualTo: widget.customerId)
          .get();
      
      print('Found ${paymentsQuery.docs.length} payment documents');

      // Sort manually after fetching
      final sortedDocs = paymentsQuery.docs;
      sortedDocs.sort((a, b) {
        final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime); // Descending order
      });

      for (var doc in sortedDocs) {
        final data = doc.data();
        final paymentId = data['paymentId'] ?? doc.id;
        final slipUrl = data['slipUrl'] as String?;
        final storagePath = data['storagePath'] as String?;
        final status = data['status'] ?? 'pending';
        final notes = data['notes'] ?? '';
        
        String? downloadUrl;
        String? fileName;
        int fileSize = 0;
        DateTime? uploadedDate;

        // Try to get file from Storage if storagePath exists
        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            final ref = _storage.ref().child(storagePath);
            downloadUrl = await ref.getDownloadURL();
            final metadata = await ref.getMetadata();
            fileName = metadata.name;
            fileSize = metadata.size ?? 0;
            uploadedDate = metadata.timeCreated;
          } catch (e) {
            print('Error loading storage file: $e');
            // Use slipUrl as fallback
            if (slipUrl != null && slipUrl.isNotEmpty) {
              downloadUrl = slipUrl;
              fileName = 'Payment_$paymentId.pdf';
            }
          }
        } else if (slipUrl != null && slipUrl.isNotEmpty) {
          downloadUrl = slipUrl;
          fileName = 'Payment_$paymentId.pdf';
        }

        if (downloadUrl != null) {
          slips.add(PaymentSlipData(
            paymentId: paymentId,
            fileName: fileName ?? 'Payment_$paymentId',
            downloadUrl: downloadUrl,
            uploadedDate: uploadedDate ?? (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            fileSize: fileSize,
            status: status,
            notes: notes,
            storagePath: storagePath ?? '',
          ));
        }
      }
      
      setState(() {
        _paymentSlips = slips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading payment slips: $e';
        _isLoading = false;
      });
      print('Error in _loadPaymentSlips: $e');
    }
  }

  List<PaymentSlipData> get _filteredSlips {
    if (_filterStatus == 'all') return _paymentSlips;
    return _paymentSlips.where((slip) => slip.status == _filterStatus).toList();
  }

  Future<void> _downloadFile(PaymentSlipData slip) async {
    try {
      final Uri uri = Uri.parse(slip.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Downloading ${slip.fileName}...'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not launch download';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showPaymentDetails(PaymentSlipData slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(slip.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(slip.status),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(slip.status),
                              color: _getStatusColor(slip.status),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              slip.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(slip.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Payment ID
                    _buildDetailRow(
                      'Payment ID',
                      slip.paymentId,
                      Icons.receipt_long,
                    ),
                    const Divider(height: 30),
                    
                    // File Name
                    _buildDetailRow(
                      'File Name',
                      slip.fileName,
                      Icons.description,
                    ),
                    const Divider(height: 30),
                    
                    // Upload Date
                    _buildDetailRow(
                      'Upload Date',
                      DateFormat('MMM dd, yyyy • hh:mm a').format(slip.uploadedDate),
                      Icons.calendar_today,
                    ),
                    const Divider(height: 30),
                    
                    // File Size
                    _buildDetailRow(
                      'File Size',
                      _formatFileSize(slip.fileSize),
                      Icons.storage,
                    ),
                    
                    if (slip.notes.isNotEmpty) ...[
                      const Divider(height: 30),
                      _buildDetailRow(
                        'Notes',
                        slip.notes,
                        Icons.note,
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Download Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadFile(slip);
                        },
                        icon: const Icon(Icons.download, size: 24),
                        label: const Text(
                          'Download Payment Slip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.blue[700],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Payment Slips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(100, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[700]!,
                      Colors.blue[500]!,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.receipt_long,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPaymentSlips,
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Body
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading payment slips...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loadPaymentSlips,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[700]!, Colors.indigo[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.account_circle,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customerName.isNotEmpty ? _customerName : 'Customer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.customerId,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_paymentSlips.length}',
                      style: TextStyle(
                        color: Colors.indigo[700],
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _paymentSlips.length == 1 ? 'Slip' : 'Slips',
                      style: TextStyle(
                        color: Colors.indigo[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filter Chips
        if (_paymentSlips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _paymentSlips.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Verified',
                  'verified',
                  _paymentSlips.where((s) => s.status == 'verified').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Pending',
                  'pending',
                  _paymentSlips.where((s) => s.status == 'pending').length,
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Payment Slips List
        if (_filteredSlips.isEmpty)
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus == 'all'
                        ? 'No Payment Slips Yet'
                        : 'No ${_filterStatus.toUpperCase()} slips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment slips will appear here\nonce uploaded by the admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredSlips.length,
            itemBuilder: (context, index) {
              return _buildPaymentSlipCard(_filteredSlips[index]);
            },
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: FilterChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSlipCard(PaymentSlipData slip) {
    final statusColor = _getStatusColor(slip.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentDetails(slip),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator & Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.8),
                        statusColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Payment info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              slip.fileName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              slip.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(slip.uploadedDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.storage,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFileSize(slip.fileSize),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Download button
                IconButton(
                  onPressed: () => _downloadFile(slip),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.download,
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentSlipData {
  final String paymentId;
  final String fileName;
  final String downloadUrl;
  final DateTime uploadedDate;
  final int fileSize;
  final String status;
  final String notes;
  final String storagePath;

  PaymentSlipData({
    required this.paymentId,
    required this.fileName,
    required this.downloadUrl,
    required this.uploadedDate,
    required this.fileSize,
    required this.status,
    required this.notes,
    required this.storagePath,
  });
}