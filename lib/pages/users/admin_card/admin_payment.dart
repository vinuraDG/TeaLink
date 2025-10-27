import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:TeaLink/pages/users/admin_card/admin_setting.dart';
import 'package:TeaLink/pages/users/admin_card/manage_users.dart';
import 'package:TeaLink/pages/users/admin_dashboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


class AdminPaymentSlipPage extends StatefulWidget {
  const AdminPaymentSlipPage({super.key});

  @override
  State<AdminPaymentSlipPage> createState() => _AdminPaymentSlipPageState();
}

class _AdminPaymentSlipPageState extends State<AdminPaymentSlipPage> {
  bool _isLoading = false;
  bool _isUploading = false;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedCustomerEmail;
  String? _selectedCustomerRegNo;
  PlatformFile? _selectedPlatformFile;
  String? _fileName;
  int _selectedIndex = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedPlatformFile = result.files.first;
          _fileName = result.files.first.name;
        });
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("${localizations.fileSelected}: $_fileName")),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        _showErrorSnackBar(localizations.noFileSelected);
      }
    } catch (e) {
      print("File picker error: $e");
      _showErrorSnackBar("${localizations.error}: ${e.toString()}");
    }
  }

  Future<void> _uploadPaymentSlip() async {
    final localizations = AppLocalizations.of(context)!;
    
    if (_selectedCustomerId == null || _selectedCustomerRegNo == null) {
      _showErrorSnackBar(localizations.pleaseSelectCustomer);
      return;
    }

    if (_selectedPlatformFile == null) {
      _showErrorSnackBar(localizations.pleaseSelectPaymentSlipFile);
      return;
    }

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) {
      _showErrorSnackBar(localizations.adminNotLoggedIn);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _fileName!.split('.').last;
      
      final storage = FirebaseStorage.instance;
      
      final storageRef = storage
          .ref()
          .child('payment_slips')
          .child(_selectedCustomerRegNo!)
          .child('${timestamp}_$_fileName');

      print("Uploading to path: payment_slips/$_selectedCustomerRegNo/${timestamp}_$_fileName");

      UploadTask uploadTask;

      if (kIsWeb) {
        if (_selectedPlatformFile!.bytes == null) {
          throw Exception("File data not available for web upload");
        }
        uploadTask = storageRef.putData(
          _selectedPlatformFile!.bytes!,
          SettableMetadata(
            contentType: _getContentType(fileExtension),
            customMetadata: {
              'uploadedBy': admin.email ?? 'unknown',
              'customerId': _selectedCustomerId!,
              'customerRegNo': _selectedCustomerRegNo!,
              'uploadTimestamp': timestamp.toString(),
            },
          ),
        );
      } else {
        if (_selectedPlatformFile!.path == null) {
          throw Exception("File path not available for mobile upload");
        }
        uploadTask = storageRef.putFile(
          File(_selectedPlatformFile!.path!),
          SettableMetadata(
            contentType: _getContentType(fileExtension),
            customMetadata: {
              'uploadedBy': admin.email ?? 'unknown',
              'customerId': _selectedCustomerId!,
              'customerRegNo': _selectedCustomerRegNo!,
              'uploadTimestamp': timestamp.toString(),
            },
          ),
        );
      }

      final uploadSnapshot = await uploadTask;
      print("Upload completed, getting download URL...");
      
      final downloadUrl = await uploadSnapshot.ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      final paymentId = 'PAY_$timestamp';
      await FirebaseFirestore.instance.collection("payments").doc(paymentId).set({
        "paymentId": paymentId,
        "customerId": _selectedCustomerId,
        "customerName": _selectedCustomerName,
        "customerEmail": _selectedCustomerEmail,
        "customerRegNo": _selectedCustomerRegNo,
        "slipUrl": downloadUrl,
        "fileName": _fileName,
        "storagePath": 'payment_slips/$_selectedCustomerRegNo/${timestamp}_$_fileName',
        "notes": _notesController.text.trim(),
        "uploadedBy": admin.uid,
        "uploadedByEmail": admin.email,
        "status": "verified",
        "uploadDate": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("Payment record created in Firestore");

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _selectedPlatformFile = null;
        _fileName = null;
        _selectedCustomerId = null;
        _selectedCustomerName = null;
        _selectedCustomerEmail = null;
        _selectedCustomerRegNo = null;
        _notesController.clear();
      });

      _showSuccessDialog();
    } catch (e) {
      print("Upload error: $e");
      setState(() => _isUploading = false);
      _showErrorSnackBar("${localizations.uploadFailed}: ${e.toString()}");
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.successTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "${localizations.paymentSlipUploadedTo}\n$_selectedCustomerRegNo ${localizations.folder}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    localizations.done,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerSelector() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final regNosSnapshot = await FirebaseFirestore.instance
          .collection('unique_reg_nos')
          .get();

      List<Map<String, dynamic>> customersList = [];

      for (var regDoc in regNosSnapshot.docs) {
        final regNo = regDoc.id;
        final uid = regDoc.data()['uid'] as String?;

        if (uid != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final role = userData['role'] as String?;
              
              if (role == null || role.toLowerCase() == 'customer') {
                customersList.add({
                  'uid': uid,
                  'regNo': regNo,
                  'name': userData['name'] ?? 'Unknown',
                  'email': userData['email'] ?? 'No email',
                  'phone': userData['phone'] ?? '',
                });
              }
            }
          } catch (e) {
            print('Error fetching user $uid: $e');
          }
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            String searchQuery = '';
            List<Map<String, dynamic>> filteredCustomers = customersList;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.people, color: Colors.green.shade700, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.selectCustomerTitle,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${customersList.length} ${localizations.customers.toLowerCase()}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value.toLowerCase();
                          filteredCustomers = customersList.where((customer) {
                            final name = (customer['name'] ?? '').toString().toLowerCase();
                            final email = (customer['email'] ?? '').toString().toLowerCase();
                            final regNo = (customer['regNo'] ?? '').toString().toLowerCase();
                            return name.contains(searchQuery) || 
                                   email.contains(searchQuery) ||
                                   regNo.contains(searchQuery);
                          }).toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: localizations.searchByNameEmailOrReg,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty 
                                      ? localizations.noCustomersFound
                                      : localizations.noMatchingCustomers,
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCustomers.length,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final uid = customer['uid'] ?? '';
                              final regNo = customer['regNo'] ?? 'Unknown';
                              final name = customer['name'] ?? 'Unknown';
                              final email = customer['email'] ?? 'No email';
                              final phone = customer['phone'] ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCustomerId = uid;
                                      _selectedCustomerName = name;
                                      _selectedCustomerEmail = email;
                                      _selectedCustomerRegNo = regNo;
                                    });
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            name[0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      regNo,
                                                      style: TextStyle(
                                                        color: Colors.green.shade700,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (phone.isNotEmpty)
                                                Text(
                                                  phone,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("${localizations.error}: $e");
    }
  }

  void _clearForm() {
    setState(() {
      _selectedPlatformFile = null;
      _fileName = null;
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _selectedCustomerEmail = null;
      _selectedCustomerRegNo = null;
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(localizations.uploadPaymentSlipTitle, 
            style: const TextStyle(fontSize: 17,
            fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: kMainColor,
        foregroundColor: kWhite,
        elevation: 0,
        actions: [
          if (_selectedCustomerId != null || _selectedPlatformFile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearForm,
              tooltip: localizations.clearForm,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _infoHeader(localizations),
                  const SizedBox(height: 24),
                  _buildSectionHeader("1", localizations.selectCustomerStep, Icons.person),
                  const SizedBox(height: 12),
                  _buildCustomerCard(localizations),
                  const SizedBox(height: 24),
                  _buildSectionHeader("2", localizations.uploadPaymentSlipStep, Icons.upload_file),
                  const SizedBox(height: 12),
                  _buildFileUploadCard(localizations),
                  const SizedBox(height: 24),
                  _buildSectionHeader("3", localizations.additionalNotes, Icons.note_alt, isOptional: true),
                  const SizedBox(height: 12),
                  _buildNotesCard(localizations),
                  const SizedBox(height: 32),
                  _submitButton(localizations),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(localizations),
    );
  }

  Widget _infoHeader(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.shade200, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.receipt_long, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.paymentSlipUpload,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(localizations.uploadPaymentSlipsForCustomers,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String step, String title, IconData icon, {bool isOptional = false}) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.green.shade600, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (isOptional)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Text(localizations.optional,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: _showCustomerSelector,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _selectedCustomerId != null ? Colors.blue.shade100 : Colors.grey.shade200,
                child: Icon(
                  _selectedCustomerId != null ? Icons.person : Icons.person_outline,
                  color: _selectedCustomerId != null ? Colors.green.shade700 : Colors.grey.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCustomerName ?? localizations.tapToSelectCustomer,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedCustomerId != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedCustomerId != null ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    if (_selectedCustomerRegNo != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _selectedCustomerRegNo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (_selectedCustomerEmail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedCustomerEmail!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _selectedPlatformFile != null ? Colors.green.shade100 : Colors.grey.shade200,
                child: Icon(
                  _selectedPlatformFile != null ? Icons.file_present : Icons.attach_file,
                  color: _selectedPlatformFile != null ? Colors.green.shade700 : Colors.grey.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? localizations.tapToSelectFile,
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedPlatformFile != null ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: _selectedPlatformFile != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.pdfJpgPngSupported,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.upload_file, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: localizations.enterAdditionalNotes,
          ),
        ),
      ),
    );
  }

  Widget _submitButton(AppLocalizations localizations) {
    return ElevatedButton(
      onPressed: _isUploading ? null : _uploadPaymentSlip,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: _isUploading ? 0 : 2,
      ),
      child: _isUploading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  "${localizations.uploadingTo} $_selectedCustomerRegNo...",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            )
          : Text(
              localizations.uploadPaymentSlipButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              icon: const Icon(Icons.map_sharp, size: 26),
              label: localizations.payment,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history, size: 26),
              label: localizations.users,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person, size: 26),
              label: localizations.settings,
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
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AdminDashboard()));
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AdminPaymentSlipPage()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ManageUsersPage()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => AdminSettingsPage()));
        break;
    }
  }
}