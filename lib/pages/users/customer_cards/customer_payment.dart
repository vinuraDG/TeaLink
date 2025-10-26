import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:TeaLink/pages/users/customer_cards/collector_info.dart';
import 'package:TeaLink/pages/users/customer_cards/customer_profile.dart';
import 'package:TeaLink/pages/users/customer_cards/trend.dart';
import 'package:TeaLink/pages/users/customer_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class CustomerPaymentSlipPage extends StatefulWidget {
  const CustomerPaymentSlipPage({super.key});

  @override
  State<CustomerPaymentSlipPage> createState() => _CustomerPaymentSlipPageState();
}

class _CustomerPaymentSlipPageState extends State<CustomerPaymentSlipPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PaymentSlipData> _paymentSlips = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _customerName = '';
  String _customerRegNo = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please login to view payment slips';
          _isLoading = false;
        });
        return;
      }

      // Get customer data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data()!;
      _customerName = userData['name'] ?? 'Customer';
      
      // Get registration number from unique_reg_nos collection
      final regNoQuery = await _firestore
          .collection('unique_reg_nos')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (regNoQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Registration number not found';
          _isLoading = false;
        });
        return;
      }

      _customerRegNo = regNoQuery.docs.first.id;
      
      await _loadPaymentSlips();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading customer data: $e';
        _isLoading = false;
      });
    }
  }

Future<void> _loadPaymentSlips() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<PaymentSlipData> slips = [];

    // Method 1: Load from Firestore payments collection
    final paymentsQuery = await _firestore
        .collection('payments')
        .where('customerRegNo', isEqualTo: _customerRegNo)
        .get();

    for (var doc in paymentsQuery.docs) {
      final data = doc.data();
      final paymentId = data['paymentId'] ?? doc.id;
      final slipUrl = data['slipUrl'] as String?;
      final storagePath = data['storagePath'] as String?;
      final status = (data['status'] ?? 'pending').toString().toLowerCase();
      final notes = data['notes'] ?? '';
      final fileName = data['fileName'] ?? 'Payment_$paymentId';

      String? downloadUrl = slipUrl;
      int fileSize = 0;
      DateTime? uploadedDate;

      // Try to get metadata from storage if path exists
      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          final ref = _storage.ref().child(storagePath);
          final metadata = await ref.getMetadata();
          fileSize = metadata.size ?? 0;
          uploadedDate = metadata.timeCreated;
          
          // Get fresh download URL
          downloadUrl = await ref.getDownloadURL();
        } catch (e) {
          print('Error fetching storage metadata: $e');
          // Use URL from Firestore if storage fetch fails
        }
      }

      // Use Firestore timestamp if storage timestamp not available
      if (uploadedDate == null) {
        final timestamp = data['uploadDate'] as Timestamp?;
        uploadedDate = timestamp?.toDate() ?? DateTime.now();
      }

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        slips.add(PaymentSlipData(
          paymentId: paymentId,
          fileName: fileName,
          downloadUrl: downloadUrl,
          uploadedDate: uploadedDate,
          fileSize: fileSize,
          status: status,
          notes: notes,
          storagePath: storagePath ?? '',
          uploadedBy: data['uploadedByEmail'] ?? 'Admin',
        ));
      }
    }

    // Method 2: Also check storage directly (backup method)
    if (slips.isEmpty) {
      try {
        final storageRef = _storage.ref().child('payment_slips/$_customerRegNo');
        final listResult = await storageRef.listAll();

        for (var item in listResult.items) {
          try {
            final metadata = await item.getMetadata();
            final downloadUrl = await item.getDownloadURL();
            
            slips.add(PaymentSlipData(
              paymentId: 'SLIP_${metadata.timeCreated?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
              fileName: metadata.name ?? 'Unknown',
              downloadUrl: downloadUrl,
              uploadedDate: metadata.timeCreated ?? DateTime.now(),
              fileSize: metadata.size ?? 0,
              status: 'verified',
              notes: '',
              storagePath: item.fullPath,
              uploadedBy: metadata.customMetadata?['uploadedBy'] ?? 'Admin',
            ));
          } catch (e) {
            print('Error processing storage item: $e');
          }
        }
      } catch (e) {
        print('Error loading from storage: $e');
      }
    }

    // Sort after fetching (newest first)
    slips.sort((a, b) => b.uploadedDate.compareTo(a.uploadedDate));

    setState(() {
      _paymentSlips = slips;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Error loading payment slips: $e';
      _isLoading = false;
    });
  }
}

  List<PaymentSlipData> get _sortedSlips {
    List<PaymentSlipData> sorted = List.from(_paymentSlips);

    // Sort
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => _sortAscending
            ? a.fileName.compareTo(b.fileName)
            : b.fileName.compareTo(a.fileName));
        break;
      case 'date':
      default:
        sorted.sort((a, b) => _sortAscending
            ? a.uploadedDate.compareTo(b.uploadedDate)
            : b.uploadedDate.compareTo(a.uploadedDate));
    }

    return sorted;
  }

  Future<void> _downloadFile(PaymentSlipData slip) async {
    final localizations = AppLocalizations.of(context)!;
    
    try {
      final Uri uri = Uri.parse(slip.downloadUrl);
      
      // Try to launch with externalApplication mode first
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('ExternalApplication mode failed: $e');
      }

      if (!launched) {
        // If that fails, try platformDefault mode
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          print('PlatformDefault mode failed: $e');
        }
      }

      if (!launched) {
        // Last attempt with externalNonBrowserApplication
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          print('ExternalNonBrowserApplication mode failed: $e');
        }
      }
        
      if (!launched) {
        throw Exception('Could not open the file. Please check if you have a browser installed.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Opening ${slip.fileName}...')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
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
                  child: Text(
                    'Failed to open file: ${e.toString()}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _sharePaymentDetails(PaymentSlipData slip) {
    final text = '''Payment Slip Details
Payment ID: ${slip.paymentId}
Date: ${DateFormat('MMM dd, yyyy').format(slip.uploadedDate)}
File: ${slip.fileName}''';

    Share.share(text);
  }

  void _showPaymentDetails(PaymentSlipData slip) {
    final localizations = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kMainColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: kMainColor,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildDetailRow(localizations.paymentId, slip.paymentId, Icons.receipt_long),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      localizations.date,
                      DateFormat('MMM dd, yyyy • hh:mm a').format(slip.uploadedDate),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(localizations.fileName, slip.fileName, Icons.description),
                    const SizedBox(height: 16),
                    _buildDetailRow(localizations.fileSize, _formatFileSize(slip.fileSize), Icons.storage),
                    const SizedBox(height: 16),
                    _buildDetailRow(localizations.uploadedBy, slip.uploadedBy, Icons.person),
                    if (slip.notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.note, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.notes,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    slip.notes,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadFile(slip);
                        },
                        icon: const Icon(Icons.download),
                        label: Text(localizations.download),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _sharePaymentDetails(slip);
                        },
                        icon: const Icon(Icons.share),
                        label: Text(localizations.share),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[600],
                          side: BorderSide(color: Colors.green[600]!, width: 2),
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
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green[700], size: 20),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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

  void _showSortBottomSheet() {
    final localizations = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.sortBy,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._buildSortOptions(localizations, setModalState),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.order,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SegmentedButton<bool>(
                            segments: <ButtonSegment<bool>>[
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(localizations.descending),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(localizations.ascending),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                            ],
                            selected: <bool>{_sortAscending},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _sortAscending = newSelection.first;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            localizations.apply,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  List<Widget> _buildSortOptions(AppLocalizations localizations, StateSetter setModalState) {
    final options = {
      'date': localizations.date,
      'name': localizations.fileName,
    };

    return options.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: RadioListTile<String>(
          title: Text(
            entry.value,
            style: const TextStyle(fontSize: 16),
          ),
          value: entry.key,
          groupValue: _sortBy,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sortBy = value;
              });
              Navigator.pop(context);
            }
          },
          activeColor: Colors.green[600],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: kMainColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                localizations.paymentSlips,
                style: const TextStyle(fontWeight: FontWeight.bold,color: kWhite),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kMainColor, kMainColor.withOpacity(0.7)],
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
                icon: const Icon(Icons.sort),
                onPressed: _showSortBottomSheet,
                tooltip: 'Sort',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPaymentSlips,
                tooltip: localizations.refresh,
              ),
            ],
          ),
          SliverToBoxAdapter(child: _buildBody(localizations)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(localizations),
    );
  }

  Widget _buildBody(AppLocalizations localizations) {
    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kMainColor),
              const SizedBox(height: 16),
              Text(
                localizations.loadingPaymentSlips,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loadCustomerData,
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.tryAgain),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: Colors.white,
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
              colors: [kMainColor, kMainColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kMainColor.withOpacity(0.3),
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
                      _customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.regNo}: $_customerRegNo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_paymentSlips.length}',
                      style: TextStyle(
                        color: kMainColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      localizations.slips,
                      style: TextStyle(
                        color: kMainColor,
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

        const SizedBox(height: 16),

        // Payment Slips List
        if (_sortedSlips.isEmpty)
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
                    localizations.noPaymentSlips,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.paymentSlipsWillAppearHere,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
            itemCount: _sortedSlips.length,
            itemBuilder: (context, index) {
              return _buildPaymentSlipCard(_sortedSlips[index], localizations);
            },
          ),

        const SizedBox(height: 20),
      ],
    );
  }

Widget _buildPaymentSlipCard(PaymentSlipData slip, AppLocalizations localizations) {
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
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kMainColor.withOpacity(0.8),
                          kMainColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kMainColor.withOpacity(0.3),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slip.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            Flexible(
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(slip.uploadedDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              slip.uploadedBy,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _downloadFile(slip),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(localizations.download),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBottomNavBar(AppLocalizations localizations) {
    return Container(
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kMainColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded, size: 26),
              label: localizations.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.trending_up, size: 26),
              label: localizations.trends,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payment, size: 26),
              label: localizations.payment,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person, size: 26),
              label: localizations.profile,
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerDashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HarvestTrendsPage()),
        );
        break;
      case 2:
        // Current page
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
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
  final String uploadedBy;

  PaymentSlipData({
    required this.paymentId,
    required this.fileName,
    required this.downloadUrl,
    required this.uploadedDate,
    required this.fileSize,
    required this.status,
    required this.notes,
    required this.storagePath,
    required this.uploadedBy,
  });
}