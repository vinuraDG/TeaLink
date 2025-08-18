import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TeaLink/constants/colors.dart';

class AddWeightPage extends StatefulWidget {
  const AddWeightPage({super.key});

  @override
  State<AddWeightPage> createState() => _AddWeightPageState();
}

class _AddWeightPageState extends State<AddWeightPage> {
  final TextEditingController regController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addWeight() async {
    final regNumber = regController.text.trim();
    final weight = double.tryParse(weightController.text.trim()) ?? 0;

    if (regNumber.isEmpty || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid Reg Number and Weight")),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final weekId = "${now.year}-W${((now.dayOfYear - 1) ~/ 7) + 1}";

      // Save harvest record
      await _firestore
          .collection("customers")
          .doc(regNumber)
          .collection("harvests")
          .add({
        "weight": weight,
        "date": now,
        "weekId": weekId,
      });

      // Update weekly total
      final weeklyDoc =
          _firestore.collection("customers").doc(regNumber).collection("weekly").doc(weekId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(weeklyDoc);
        if (!snapshot.exists) {
          transaction.set(weeklyDoc, {"total": weight});
        } else {
          final current = snapshot["total"] ?? 0;
          transaction.update(weeklyDoc, {"total": current + weight});
        }
      });

      regController.clear();
      weightController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Weight added successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _clearFields() {
    regController.clear();
    weightController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Weight"),
        backgroundColor: kMainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: regController,
              decoration: const InputDecoration(labelText: "Customer Reg Number"),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
                  onPressed: _addWeight,
                  child: const Text("Add"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _clearFields,
                  child: const Text("Clear"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on DateTime {
  get dayOfYear => null;
}
