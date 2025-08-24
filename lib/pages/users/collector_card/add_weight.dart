import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TeaLink/constants/colors.dart';

class AddWeightPage extends StatefulWidget {
  final String notifyId; // document id of notify_for_collection

  const AddWeightPage({
    super.key,
    required this.notifyId, required String customerName, required String regNo, required DocumentReference<Object?> notifyDocRef,
  });

  @override
  State<AddWeightPage> createState() => _AddWeightPageState();
}

class _AddWeightPageState extends State<AddWeightPage> {
  final TextEditingController weightController = TextEditingController();
  bool _isLoading = false;

  DocumentReference get notifyDocRef =>
      FirebaseFirestore.instance.collection("notify_for_collection").doc(widget.notifyId);

  Future<void> _submitWeight(Map<String, dynamic> notifyData) async {
    final weight = double.tryParse(weightController.text.trim());

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid weight")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update main notify doc
      await notifyDocRef.update({
        "status": "Collected",
        "lastWeight": weight,
        "collectedAt": FieldValue.serverTimestamp(),
      });

      // 2. Add weight history in subcollection
      await notifyDocRef.collection("weights").add({
        "weight": weight,
        "collectedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ ${notifyData['customerName']} (Reg: ${notifyData['regNo']}) collected with $weight kg"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save weight: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Weight"),
        backgroundColor: kMainColor,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: notifyDocRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kMainColor),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No customer data found."));
          }

          final notifyData = snapshot.data!.data() as Map<String, dynamic>;
          final customerName = notifyData["customerName"] ?? "Unknown";
          final regNo = notifyData["regNo"] ?? "N/A";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Customer Info
                Card(
                  color: Colors.grey[100],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kMainColor,
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      customerName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Reg No: $regNo",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Weight Input
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Weight (kg)",
                    prefixIcon: const Icon(Icons.scale),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kMainColor))
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _submitWeight(notifyData),
                        icon:
                            const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          "Submit",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
