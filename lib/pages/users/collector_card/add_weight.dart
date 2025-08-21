import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  // Fetch suggestions using regNo as doc ID
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final snapshot = await _firestore
          .collection("customers")
          .orderBy("regNo")
          .startAt([query])
          .endAt(["$query\uf8ff"])
          .limit(10)
          .get();

      final suggestions = snapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching suggestions: $e")),
      );
    }
  }

  // Add weight to Firestore
  Future<void> _addWeight() async {
    final regNumber = regController.text.trim();
    final weight = double.tryParse(weightController.text.trim()) ?? 0;

    if (regNumber.isEmpty || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid Reg Number and Weight")),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      final now = DateTime.now();
      final weekId = "${now.year}-W${((now.dayOfYear - 1) ~/ 7) + 1}";

      // Add harvest record
      await _firestore
          .collection("customers")
          .doc(regNumber)
          .collection("harvests")
          .add({
        "weight": weight,
        "date": Timestamp.fromDate(now),
        "weekId": weekId,
        "collectorId": currentUser!.uid,
        "customerRegNo": regNumber,
      });

      // Update weekly total using transaction
      final weeklyDoc = _firestore
          .collection("customers")
          .doc(regNumber)
          .collection("weekly")
          .doc(weekId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(weeklyDoc);
        if (!snapshot.exists) {
          transaction.set(weeklyDoc, {
            "total": weight,
            "weekId": weekId,
            "customerRegNo": regNumber,
            "lastUpdated": Timestamp.fromDate(now),
          });
        } else {
          final current = snapshot.get("total") ?? 0;
          transaction.update(weeklyDoc, {
            "total": current + weight,
            "lastUpdated": Timestamp.fromDate(now),
          });
        }
      });

      regController.clear();
      weightController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Weight added successfully!")),
      );
    } catch (e) {
      debugPrint("Error adding weight: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding weight: $e")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Clear input fields
  void _clearFields() {
    regController.clear();
    weightController.clear();
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Weight"),
        backgroundColor: kMainColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: regController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.perm_identity),
                        hintText: "Enter Customer Reg Number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: _fetchSuggestions,
                    ),
                  ),
                  if (_showSuggestions)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Card(
                        elevation: 4,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: _suggestions
                              .map(
                                (s) => ListTile(
                                  title: Text(s),
                                  onTap: () {
                                    regController.text = s;
                                    setState(() {
                                      _showSuggestions = false;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.scale),
                    hintText: "Enter Weight (kg)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: kMainColor)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 5,
                          ),
                          onPressed: _addWeight,
                          icon: const Icon(Icons.add),
                          label: const Text("Add"),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 5,
                          ),
                          onPressed: _clearFields,
                          icon: const Icon(Icons.clear),
                          label: const Text("Clear"),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  int get dayOfYear {
    final beginningOfYear = DateTime(year, 1, 1);
    return difference(beginningOfYear).inDays + 1;
  }
}
