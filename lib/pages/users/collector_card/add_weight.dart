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

  // Helper function to get week ID (YYYY-W##) - ISO week date (matching CollectorNotificationPage)
  String getWeekId(DateTime date) {
    // ISO 8601 week date calculation
    // Week 1 is the first week with at least 4 days in the new year
    // Monday is the first day of the week
    
    int year = date.year;
    int dayOfYear = date.difference(DateTime(year, 1, 1)).inDays + 1;
    
    // Find the first Monday of the year
    DateTime jan1 = DateTime(year, 1, 1);
    int jan1Weekday = jan1.weekday; // Monday = 1, Sunday = 7
    
    // Days to the first Monday
    int daysToFirstMonday = jan1Weekday == 1 ? 0 : 8 - jan1Weekday;
    
    // Adjust for ISO week calculation
    int adjustedDayOfYear = dayOfYear + jan1Weekday - 1;
    int weekNumber = ((adjustedDayOfYear - 1) / 7).floor() + 1;
    
    // Handle edge cases for first and last weeks
    if (weekNumber < 1) {
      // This date belongs to the last week of the previous year
      year = year - 1;
      weekNumber = getISOWeeksInYear(year);
    } else if (weekNumber > getISOWeeksInYear(year)) {
      // This date belongs to the first week of the next year
      year = year + 1;
      weekNumber = 1;
    }
    
    return "${year}-W${weekNumber.toString().padLeft(2, '0')}";
  }
  
  int getISOWeeksInYear(int year) {
    DateTime lastDayOfYear = DateTime(year, 12, 31);
    DateTime firstDayOfYear = DateTime(year, 1, 1);
    
    // Week 1 contains January 4th
    DateTime jan4 = DateTime(year, 1, 4);
    int jan4Weekday = jan4.weekday;
    DateTime firstMondayOfFirstWeek = jan4.subtract(Duration(days: jan4Weekday - 1));
    
    // Last Monday of the year that starts a week
    DateTime lastMondayOfYear = lastDayOfYear.subtract(Duration(days: lastDayOfYear.weekday - 1));
    
    return ((lastMondayOfYear.difference(firstMondayOfFirstWeek).inDays) / 7).floor() + 1;
  }

  // Get day name from DateTime (Monday = 1, Sunday = 7)
  String getDayName(DateTime date) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[date.weekday - 1];
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
      
      // Calculate week ID and day name using the same method as CollectorNotificationPage
      final weekId = getWeekId(now);
      final dayName = getDayName(now);
      
      // Update the notification document with weight and status
      // IMPORTANT: Add customerId to make it available for trends page
      batch.update(widget.docReference, {
        'weight': weight,
        'status': 'Collected',
        'collectedAt': Timestamp.fromDate(now),
        'customerId': widget.customerId, // This is the key addition
        'collectedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      });

      // Update weekly harvest for the customer using the correct structure
      final weeklyDocRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.regNo)
          .collection('weekly')
          .doc(weekId);

      // Use transaction to ensure data consistency (same as CollectorNotificationPage)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot weeklyDoc = await transaction.get(weeklyDocRef);
        
        if (weeklyDoc.exists) {
          // Update existing weekly document
          Map<String, dynamic> currentData = weeklyDoc.data() as Map<String, dynamic>;
          double currentDayWeight = (currentData[dayName] as num?)?.toDouble() ?? 0.0;
          double currentWeeklyTotal = (currentData['weeklyTotal'] as num?)?.toDouble() ?? 0.0;
          
          // Add new weight to existing day weight and weekly total
          double newDayWeight = currentDayWeight + weight;
          double newWeeklyTotal = currentWeeklyTotal + weight;
          
          transaction.update(weeklyDocRef, {
            dayName: newDayWeight,
            'weeklyTotal': newWeeklyTotal,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('Updated existing week: $dayName=$newDayWeight, weeklyTotal=$newWeeklyTotal');
        } else {
          // Create new weekly document
          Map<String, dynamic> weeklyData = {
            'weekId': weekId,
            'monday': 0.0,
            'tuesday': 0.0,
            'wednesday': 0.0,
            'thursday': 0.0,
            'friday': 0.0,
            'saturday': 0.0,
            'sunday': 0.0,
            'weeklyTotal': weight,
            'customerId': widget.customerId,
            'customerRegNo': widget.regNo,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          
          // Set the current day's weight
          weeklyData[dayName] = weight;
          
          transaction.set(weeklyDocRef, weeklyData);
          
          print('Created new week document: $weekId with $dayName=$weight');
        }
      });

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
        'dayName': dayName, // Add day name for consistency
      });

      // Commit the batch
      await batch.commit();

      setState(() => _isLoading = false);

      if (mounted) {
        _showSuccessSnackBar('Weight saved successfully!');
        // Return success with weight data
        Navigator.pop(context, {
          'success': true,
          'weight': weight,
        });
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