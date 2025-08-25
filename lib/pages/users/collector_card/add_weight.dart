import 'package:TeaLink/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddWeightPage extends StatefulWidget {
  final String customerName;
  final String regNo;
  final DocumentReference docReference; // notify_for_collection/{docId}

  const AddWeightPage({
    super.key,
    required this.customerName,
    required this.regNo,
    required this.docReference, required this.customerId,
  });
  
  final String customerId;

  @override
  _AddWeightPageState createState() => _AddWeightPageState();
}

class _AddWeightPageState extends State<AddWeightPage> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController regController = TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    regController.text = widget.regNo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Weight"),
        backgroundColor: kMainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Customer Reg No (Read Only)
            TextField(
              controller: regController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Customer Reg No",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Weight input
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Weight (kg)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: isSaving ? null : _saveWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Save",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWeight() async {
  final weightText = weightController.text.trim();
  final regNo = regController.text.trim();

  final parsed = double.tryParse(weightText);
  if (parsed == null || parsed <= 0 || regNo.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid weight (kg)')),
    );
    return;
  }

  setState(() => isSaving = true);

  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final weekId = _isoWeekId(now);

    final batch = FirebaseFirestore.instance.batch();

    // 1) Update notify_for_collection (only adds allowed fields)
    batch.update(widget.docReference, {
      'status': 'Collected',
      'weight': parsed,
      'collectedBy': uid,
      'collectedAt': Timestamp.now(),
    });

    // 2) Create harvest record under customers/{UID}/harvests
    final harvestRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerId) // <-- UID
        .collection('harvests')
        .doc(); // create ID now so we can batch.set

    batch.set(harvestRef, {
      'collectorId': uid,
      'customerRegNo': regNo,
      'weight': parsed,
      'date': Timestamp.now(),
      'weekId': weekId,
    });

    await batch.commit();

    if (!mounted) return;
    Navigator.pop(context, true);
  } on FirebaseException catch (e) {
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: ${e.message ?? e.code}')),
    );
  } catch (e) {
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e')),
    );
  }
}

/// ISO week id like "2025-W35"
String _isoWeekId(DateTime date) {
  // ISO: week starts Monday, week belongs to the year that contains Thursday
  DateTime _thursdayOfWeek(DateTime d) => d.add(Duration(days: 4 - d.weekday));
  final th = _thursdayOfWeek(date);
  final firstTh = _thursdayOfWeek(DateTime(th.year, 1, 1));
  final week = 1 + th.difference(firstTh).inDays ~/ 7;
  return '${th.year}-W${week.toString().padLeft(2, '0')}';
}


}
