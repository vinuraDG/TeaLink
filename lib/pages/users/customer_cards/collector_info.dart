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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Collector Profile",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: kWhite,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(collectorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kMainColor),
                  const SizedBox(height: 16),
                  Text(
                    "Loading profile...",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Collector not found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? "Unknown";
          String email = data['email'] ?? "-";
          String phone = data['phone'] ?? "-";
          String regNo = data['registrationNumber'] ?? "-";
          String role = data['role'] ?? "-";

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header section with profile info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kMainColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      children: [
                        // Profile avatar with shadow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: kWhite,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.teal.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "?",
                                style: TextStyle(
                                  fontSize: 42,
                                  color: kMainColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kMainColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Contact Information Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: kMainColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Contact Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _infoTile(
                            Icons.badge_outlined,
                            "Registration Number",
                            regNo,
                          ),
                          const SizedBox(height: 12),
                          
                          _infoTile(
                            Icons.phone_outlined,
                            "Phone Number",
                            phone,
                          ),
                          const SizedBox(height: 12),
                          
                          _infoTile(
                            Icons.email_outlined,
                            "Email Address",
                            email,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Action buttons in a more accessible layout
                      _buildActionButton(
                        icon: Icons.phone,
                        label: "Call Now",
                        subtitle: phone != "-" ? phone : "No phone number",
                        color: Colors.green,
                        onPressed: phone != "-" ? () => _launchPhone(phone) : null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        icon: Icons.email,
                        label: "Send Email",
                        subtitle: email != "-" ? email : "No email address",
                        color: Colors.blue,
                        onPressed: email != "-" ? () => _launchEmail(email) : null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        icon: Icons.chat,
                        label: "WhatsApp Chat",
                        subtitle: phone != "-" ? "Send a message" : "No phone number",
                        color: Colors.teal,
                        onPressed: phone != "-" ? () => _launchWhatsApp(phone) : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: kMainColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    bool isEnabled = onPressed != null;
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : Colors.grey.shade300,
          foregroundColor: isEnabled ? Colors.white : Colors.grey.shade500,
          elevation: isEnabled ? 4 : 0,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isEnabled ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled 
                          ? Colors.white.withOpacity(0.9) 
                          : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.7),
              ),
          ],
        ),
      ),
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