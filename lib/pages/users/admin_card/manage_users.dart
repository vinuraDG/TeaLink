// manage_users_page.dart - Fixed localized version
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isAdmin = false;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _customers = [];
  List<QueryDocumentSnapshot> _collectors = [];
  String? _errorMessage;
  
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    // Delay the check to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAndLoadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoadUsers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not authenticated';
            _isLoading = false;
          });
        }
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User document not found';
            _isLoading = false;
          });
        }
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role']?.toString().toLowerCase() ?? '';
      
      if (role != 'admin') {
        if (mounted) {
          setState(() {
            _errorMessage = 'Access denied. Admin privileges required.';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isAdmin = true;
        });
      }

      await _loadUsers();

    } catch (e) {
      print('Error in _checkAdminAndLoadUsers: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking permissions: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    if (!_isAdmin) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Admin access required';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      print('Loading users...');
      
      final QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .get();
      
      print('Users loaded successfully: ${usersSnapshot.docs.length} documents');
      
      List<QueryDocumentSnapshot> customers = [];
      List<QueryDocumentSnapshot> collectors = [];
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final role = userData['role']?.toString().toLowerCase() ?? '';
        
        if (role == 'customer') {
          customers.add(doc);
        } else if (role == 'collector') {
          collectors.add(doc);
        }
      }
      
      customers.sort((a, b) {
        final nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
        final nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      
      collectors.sort((a, b) {
        final nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
        final nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      
      if (mounted) {
        setState(() {
          _customers = customers;
          _collectors = collectors;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading users: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.userManagement, 
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold)),
        backgroundColor: kMainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: _isAdmin && !_isLoading && _errorMessage == null 
          ? TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: Icon(Icons.people),
                  text: l10n.customersCount(_customers.length),
                ),
                Tab(
                  icon: Icon(Icons.agriculture),
                  text: l10n.collectorsCount(_collectors.length),
                ),
              ],
            )
          : null,
        actions: [
          if (_isAdmin && !_isLoading)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadUsers,
              tooltip: l10n.refreshUsers,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
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
              icon: Icon(Icons.home_rounded, size: 26),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_sharp, size: 26),
              label: l10n.payment,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 26),
              label: l10n.users,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 26),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
            ),
            SizedBox(height: 16),
            Text(
              l10n.loadingUsers,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              ),
              SizedBox(height: 24),
              Text(
                l10n.accessError,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.red[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkAdminAndLoadUsers,
                icon: Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildUserList(_customers, 'customer', l10n.noCustomersFound, l10n.customersWillAppear),
        _buildUserList(_collectors, 'collector', l10n.noCollectorsFound, l10n.collectorsWillAppear),
      ],
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> users, String userType, String emptyMessage, String emptyDescription) {
    final l10n = AppLocalizations.of(context)!;
    
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                userType == 'customer' ? Icons.people_outline : Icons.agriculture_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              emptyDescription,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: Colors.indigo[600],
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final userData = user.data() as Map<String, dynamic>;
          
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _viewUserDetails(user.id, userData),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _getRoleColor(userData['role']),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _getRoleColor(userData['role']).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getRoleIcon(userData['role']),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? l10n.unknownUser,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userData['email'] ?? l10n.noEmail,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (userData['regNo'] != null) ...[
                            SizedBox(height: 2),
                            Text(
                              '${l10n.reg}: ${userData['regNo']}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(userData['role']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (userData['role'] ?? 'N/A').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getRoleColor(userData['role']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    _buildUserMenu(user.id, userData, l10n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserMenu(String userId, Map<String, dynamic> userData, AppLocalizations l10n) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.blue[600], size: 20),
              SizedBox(width: 12),
              Text(l10n.viewDetailsAction),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.orange[600], size: 20),
              SizedBox(width: 12),
              Text(l10n.editUser),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red[600], size: 20),
              SizedBox(width: 12),
              Text(l10n.deleteUser),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'view') {
          _viewUserDetails(userId, userData);
        } else if (value == 'edit') {
          _editUser(userId, userData);
        } else if (value == 'delete') {
          _deleteUser(userId, userData['name'] ?? l10n.user);
        }
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid date';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin': return Colors.purple[600]!;
      case 'collector': return Colors.orange[600]!;
      case 'customer': return Colors.green[600]!;
      default: return Colors.grey[600]!;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin': return Icons.admin_panel_settings;
      case 'collector': return Icons.agriculture;
      case 'customer': return Icons.person;
      default: return Icons.help_outline;
    }
  }

  void _viewUserDetails(String userId, Map<String, dynamic> userData) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getRoleColor(userData['role']),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getRoleIcon(userData['role']),
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? l10n.unknownUser,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            (userData['role'] ?? 'N/A').toUpperCase(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              
              SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailCard(l10n.personalInformationTitle, [
                      _buildDetailRow(l10n.fullNameLabel, userData['name'] ?? 'N/A'),
                      _buildDetailRow(l10n.emailAddressLabel, userData['email'] ?? 'N/A'),
                      _buildDetailRow(l10n.registrationNoLabel, userData['regNo'] ?? 'N/A'),
                      _buildDetailRow(l10n.userRole, (userData['role'] ?? 'N/A').toUpperCase()),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailCard(l10n.accountInformation, [
                      _buildDetailRow(l10n.joinedDate, _formatTimestamp(userData['createdAt'])),
                      if (userData['updatedAt'] != null)
                        _buildDetailRow(l10n.lastUpdated, _formatTimestamp(userData['updatedAt'])),
                    ]),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _editUser(userId, userData);
                        },
                        icon: Icon(Icons.edit),
                        label: Text(l10n.editUser),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[600],
                          side: BorderSide(color: Colors.orange[600]!),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(Icons.check),
                        label: Text(l10n.done),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getRoleColor(userData['role']),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> userData) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final emailController = TextEditingController(text: userData['email'] ?? '');
    final regNoController = TextEditingController(text: userData['regNo']?.toString() ?? '');
    String selectedRole = userData['role'] ?? 'customer';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.editUserTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.fullNameField,
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: l10n.emailAddressField,
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: regNoController,
                        decoration: InputDecoration(
                          labelText: l10n.registrationNumberField,
                          prefixIcon: Icon(Icons.card_membership),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          labelText: l10n.userRoleField,
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: ['customer', 'collector']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) => selectedRole = value ?? 'customer',
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(l10n.cancel),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty || 
                                emailController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.nameAndEmailRequired),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                              return;
                            }

                            try {
                              Map<String, dynamic> updateData = {
                                'name': nameController.text.trim(),
                                'email': emailController.text.trim(),
                                'role': selectedRole,
                                'updatedAt': FieldValue.serverTimestamp(),
                              };
                              
                              if (regNoController.text.trim().isNotEmpty) {
                                updateData['regNo'] = regNoController.text.trim();
                              }

                              await _firestore.collection('users').doc(userId).update(updateData);
                              Navigator.pop(dialogContext);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.userUpdatedSuccessfully),
                                    backgroundColor: Colors.green[600],
                                  ),
                                );
                                await _loadUsers();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${l10n.errorUpdatingUser}: $e'),
                                    backgroundColor: Colors.red[600],
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(l10n.updateUser),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteUser(String userId, String userName) {
    final l10n = AppLocalizations.of(context)!;
    
    if (userId == _auth.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotDeleteOwnAccount),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            SizedBox(width: 12),
            Text(l10n.deleteUserTitle),
          ],
        ),
        content: Text(l10n.deleteUserConfirmation(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(userId).delete();
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.userDeletedSuccessfully),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                  await _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.errorDeletingUser}: $e'),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteUser),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/admin_home');
        break;
      case 1:
        Navigator.pushNamed(context, '/admin_payment_slip');
        break;
      case 2:
        Navigator.pushNamed(context, '/admin_users');
        break;
      case 3:
        Navigator.pushNamed(context, '/admin_settings');
        break;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}