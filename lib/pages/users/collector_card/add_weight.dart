import 'package:TeaLink/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWeightPage extends StatefulWidget {
  final String customerName;
  final String regNo;
  final DocumentReference docReference;
  final String customerId;

  const AddWeightPage({
    super.key,
    required this.customerName,
    required this.regNo,
    required this.docReference,
    required this.customerId,
  });

  @override
  _AddWeightPageState createState() => _AddWeightPageState();
}

class _AddWeightPageState extends State<AddWeightPage> {
  final TextEditingController _weightController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Weight",
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: ${widget.customerName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reg No: ${widget.regNo}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Weight Input Section
            const Text(
              'Enter Harvest Weight',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'Enter weight in kilograms',
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kMainColor, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Weight',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const Spacer(),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter the accurate weight of harvested tea leaves in kilograms.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWeight() async {
    if (_weightController.text.isEmpty) {
      _showErrorSnackBar('Please enter a weight value');
      return;
    }

    final weightText = _weightController.text.trim();
    final weight = double.tryParse(weightText);

    if (weight == null || weight <= 0) {
      _showErrorSnackBar('Please enter a valid weight greater than 0');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      
      // Update the notification document with weight and status
      // IMPORTANT: Add customerId to make it available for trends page
      batch.update(widget.docReference, {
        'weight': weight,
        'status': 'Collected',
        'collectedAt': Timestamp.fromDate(now),
        'customerId': widget.customerId, // This is the key addition
        'collectedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      });

      // Calculate week ID for current date
      final weekId = "${now.year}-W${((now.day - 1) ~/ 7) + 1}";

      // Update weekly harvest for the customer
      final weeklyDocRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.regNo)
          .collection('weekly')
          .doc(weekId);

      // Get current weekly total
      final weeklyDoc = await weeklyDocRef.get();
      final currentTotal = weeklyDoc.exists ? (weeklyDoc.data()?['total'] ?? 0.0) : 0.0;
      final newTotal = currentTotal + weight;

      // Update or create weekly document
      batch.set(weeklyDocRef, {
        'total': newTotal,
        'updatedAt': Timestamp.fromDate(now),
        'customerId': widget.customerId,
        'customerRegNo': widget.regNo,
        'weekId': weekId,
      }, SetOptions(merge: true));

      // Add individual harvest record
      final harvestDocRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.regNo)
          .collection('harvests')
          .doc();

      batch.set(harvestDocRef, {
        'weight': weight,
        'date': now.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'timestamp': Timestamp.fromDate(now),
        'customerId': widget.customerId,
        'customerRegNo': widget.regNo,
        'collectedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'status': 'Collected',
        'weekId': weekId,
      });

      // Commit the batch
      await batch.commit();

      setState(() => _isLoading = false);

      if (mounted) {
        _showSuccessSnackBar('Weight saved successfully!');
        // Return true to indicate successful save
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error saving weight: $e');
      _showErrorSnackBar('Failed to save weight. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}