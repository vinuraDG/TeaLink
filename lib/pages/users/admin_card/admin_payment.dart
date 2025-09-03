import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  Future<void> _startPayment(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please log in first")),
      );
      return;
    }

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    var paymentObject = {
      "sandbox": true, // ✅ set to false in production
      "merchant_id": "YOUR_MERCHANT_ID",
      "merchant_secret": "YOUR_MERCHANT_SECRET",
      "notify_url": "https://your-backend.com/notify", // optional
      "order_id": orderId,
      "items": "Tea Leaves Purchase",
      "amount": amount.toStringAsFixed(2),
      "currency": "LKR",
      "first_name": "Test",
      "last_name": "User",
      "email": user.email ?? "test@example.com",
      "phone": "0771234567",
      "address": "Colombo",
      "city": "Colombo",
      "country": "Sri Lanka",
    };

    setState(() => _isLoading = true);

    var PayHere;
    PayHere.startPayment(paymentObject, (paymentId) async {
      await FirebaseFirestore.instance.collection("payments").doc(orderId).set({
        "uid": user.uid,
        "orderId": orderId,
        "amount": amount,
        "currency": "LKR",
        "status": "success",
        "paymentId": paymentId,
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Payment Success! Ref: $paymentId")),
      );
    }, (error) async {
      await FirebaseFirestore.instance.collection("payments").doc(orderId).set({
        "uid": user.uid,
        "orderId": orderId,
        "amount": amount,
        "currency": "LKR",
        "status": "failed",
        "error": error.toString(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment Failed: $error")),
      );
    }, () {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Payment Cancelled")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PayHere Checkout"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_bag,
                              size: 60, color: Colors.green),
                          const SizedBox(height: 12),
                          const Text(
                            "Tea Leaves Purchase",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Secure your fresh tea leaves with PayHere.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _priceOption("LKR 500", 500),
                              _priceOption("LKR 1000", 1000),
                              _priceOption("LKR 2000", 2000),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _startPayment(1000.00),
                    icon: const Icon(Icons.payment),
                    label: const Text("Pay LKR 1000"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _startPayment(2000.00),
                    icon: const Icon(Icons.upgrade),
                    label: const Text("Pay LKR 2000"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _priceOption(String label, double amount) {
    return GestureDetector(
      onTap: () => _startPayment(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade300, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.green.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
