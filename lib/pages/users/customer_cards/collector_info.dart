import 'package:TeaLink/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectorInfoPage extends StatelessWidget {
  final String collectorId; // Firestore document ID

  const CollectorInfoPage({super.key, required this.collectorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collector Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhite),),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: kMainColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(collectorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Collector not found"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? "Unknown";
          String email = data['email'] ?? "-";
          String phone = data['phone'] ?? "-";
          String regNo = data['registrationNumber'] ?? "-";
          String role = data['role'] ?? "-";
          

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                SizedBox(height: 30,),
                // Profile avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: kMainColor,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontSize: 40,
                      color: kWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kMainColor,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Info card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                         _infoTile(Icons.badge, "Registration No.", regNo),
                        
                        const Divider(),
                        _infoTile(Icons.phone, "Phone", phone),
                        const Divider(),
                       _infoTile(Icons.email, "Email", email),
                        
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: _btnStyle(),
                      icon: const Icon(Icons.phone, color: kWhite),
                      label: const Text("Call",
                          style: TextStyle(color: kWhite)),
                      onPressed: () => _launchPhone(phone),
                    ),
                    ElevatedButton.icon(
                      style: _btnStyle(),
                      icon: const Icon(Icons.email, color: kWhite),
                      label: const Text("Email",
                          style: TextStyle(color: kWhite)),
                      onPressed: () => _launchEmail(email),
                    ),
                    ElevatedButton.icon(
                      style: _btnStyle(),
                      icon: const Icon(Icons.chat, color: kWhite),
                      label: const Text("WhatsApp",
                          style: TextStyle(color: kWhite)),
                      onPressed: () => _launchWhatsApp(phone),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: kMainColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(value),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: kMainColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    );
  }

  // 📞 Launch phone dialer
  void _launchPhone(String phone) async {
    if (phone == "-" || phone.isEmpty) return;
    final Uri uri = Uri(scheme: "tel", path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // 📧 Launch email app
  void _launchEmail(String email) async {
    if (email == "-" || email.isEmpty) return;
    final Uri uri = Uri(scheme: "mailto", path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // 💬 Launch WhatsApp chat (auto-format for Sri Lankan numbers)
  void _launchWhatsApp(String phone) async {
    if (phone == "-" || phone.isEmpty) return;

    String formatted = phone.trim();

    // If number starts with "0", replace with +94
    if (formatted.startsWith("0")) {
      formatted = "+94${formatted.substring(1)}";
    }

    // If number already starts with +, keep as is
    if (!formatted.startsWith("+")) {
      formatted = "+94$formatted";
    }

    final Uri uri = Uri.parse("https://wa.me/${formatted.replaceAll(" ", "")}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
