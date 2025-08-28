import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:TeaLink/constants/colors.dart';

class CollectorMapPage extends StatefulWidget {
  const CollectorMapPage({super.key});

  @override
  State<CollectorMapPage> createState() => _CollectorMapPageState();
}

class _CollectorMapPageState extends State<CollectorMapPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<QuerySnapshot>? _notificationStream;
  List<NotificationData> _notifications = [];
  NotificationData? _selectedNotification;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;
  
  // Map settings
  bool _isDarkMode = false;
  String _currentTileLayer = 'openstreetmap';
  
  // Default location (Sri Lanka center)
  static const LatLng _defaultLocation = LatLng(7.8731, 80.7718);
  static const double _defaultZoom = 8.0;

  // Map tile layers
  final Map<String, TileLayer> _tileLayers = {
    'openstreetmap': TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.tealink.app',
      maxZoom: 19,
    ),
    'satellite': TileLayer(
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.tealink.app',
      maxZoom: 19,
    ),
    'terrain': TileLayer(
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.tealink.app',
      subdomains: const ['a', 'b', 'c'],
      maxZoom: 17,
    ),
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeMap();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeMap() async {
    try {
      await _setupNotificationStream();
      if (mounted) {
        _fabAnimationController.forward();
        _pulseAnimationController.repeat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load map data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setupNotificationStream() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Stream notifications for this collector
      _notificationStream = FirebaseFirestore.instance
          .collection('notify_for_collection')
          .where('collectorId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'Pending')
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            _updateNotifications(snapshot.docs);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Error loading notifications: ${error.toString()}';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to setup notification stream: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _updateNotifications(List<QueryDocumentSnapshot> docs) {
    if (!mounted) return;
    
    final notifications = <NotificationData>[];
    
    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final notification = NotificationData.fromFirestore(doc.id, data);
          if (notification.hasLocation) {
            notifications.add(notification);
          }
        }
      } catch (e) {
        print('Error parsing notification: $e');
      }
    }
    
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
    
    if (_notifications.isNotEmpty) {
      // Delay to ensure map is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _fitMarkersInView();
        }
      });
    }
  }

  List<Marker> _buildMarkers() {
    return _notifications.where((n) => n.hasLocation).map((notification) {
      return Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(notification.latitude!, notification.longitude!),
        child: GestureDetector(
          onTap: () => _selectNotification(notification),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.2),
                ),
                transform: Matrix4.translationValues(2, 2, 0),
              ),
              // Main marker
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.status == 'Pending' ? Colors.orange : Colors.green,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  notification.status == 'Pending' ? Icons.pending : Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              // Pulse animation for pending notifications
              if (notification.status == 'Pending')
                _buildPulseAnimation(),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _fitMarkersInView() {
    if (_notifications.isEmpty || !mounted) return;
    
    final locations = _notifications
        .where((n) => n.hasLocation)
        .map((n) => LatLng(n.latitude!, n.longitude!))
        .toList();
    
    if (locations.isEmpty) return;

    try {
      if (locations.length == 1) {
        // If only one location, just center on it
        _mapController.move(locations.first, 15.0);
      } else {
        // Calculate bounds for multiple locations
        double minLat = locations.first.latitude;
        double maxLat = locations.first.latitude;
        double minLng = locations.first.longitude;
        double maxLng = locations.first.longitude;
        
        for (var location in locations) {
          minLat = min(minLat, location.latitude);
          maxLat = max(maxLat, location.latitude);
          minLng = min(minLng, location.longitude);
          maxLng = max(maxLng, location.longitude);
        }
        
        final bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );
        
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (e) {
      print('Error fitting markers in view: $e');
    }
  }

  void _selectNotification(NotificationData notification) {
    if (!mounted) return;
    
    setState(() => _selectedNotification = notification);
    _cardAnimationController.forward();
    
    try {
      _mapController.move(
        LatLng(notification.latitude!, notification.longitude!),
        16.0,
      );
    } catch (e) {
      print('Error moving map to notification: $e');
    }
  }

  void _showNotificationDetails(NotificationData notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationDetailSheet(notification),
    );
  }

  Widget _buildNotificationDetailSheet(NotificationData notification) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kMainColor, kMainColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Reg: ${notification.regNo}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: notification.status == 'Pending' 
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: notification.status == 'Pending' 
                        ? Colors.orange 
                        : Colors.green,
                    ),
                  ),
                  child: Text(
                    notification.status,
                    style: TextStyle(
                      color: notification.status == 'Pending' 
                        ? Colors.orange[700] 
                        : Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.access_time, 'Time', notification.time),
                  _buildDetailRow(Icons.calendar_today, 'Date', notification.date),
                  _buildDetailRow(Icons.schedule, 'Requested', notification.timeAgo),
                  if (notification.address?.isNotEmpty == true)
                    _buildDetailRow(Icons.location_on, 'Address', notification.address!),
                  _buildDetailRow(
                    Icons.gps_fixed, 
                    'Coordinates', 
                    '${notification.latitude!.toStringAsFixed(6)}, ${notification.longitude!.toStringAsFixed(6)}'
                  ),
                  if (notification.locationSource != null)
                    _buildDetailRow(
                      Icons.info, 
                      'Location Source', 
                      notification.locationSource == 'stored' ? 'User Profile' : 'Current GPS'
                    ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsCollected(notification),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Collected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openInMaps(notification),
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kMainColor, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsCollected(NotificationData notification) async {
    // First check if weight is already added
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .doc(notification.id)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final existingWeight = data['weight'];
        
        if (existingWeight != null) {
          // Weight exists, show option to remove or update
          _showWeightExistsDialog(notification, existingWeight);
          return;
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error checking existing data: ${e.toString()}');
      return;
    }
    
    // No weight exists, show weight input dialog
    _showWeightInputDialog(notification);
  }

  void _showWeightExistsDialog(NotificationData notification, dynamic existingWeight) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Weight Already Added'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current weight: ${existingWeight.toString()} kg'),
              const SizedBox(height: 16),
              const Text('What would you like to do?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showWeightInputDialog(notification, existingWeight: existingWeight);
              },
              child: const Text('Update Weight'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeWeightAndRevert(notification);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove Weight'),
            ),
          ],
        );
      },
    );
  }

  void _showWeightInputDialog(NotificationData notification, {dynamic existingWeight}) {
    final TextEditingController weightController = TextEditingController();
    if (existingWeight != null) {
      weightController.text = existingWeight.toString();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(existingWeight != null ? 'Update Weight' : 'Add Weight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${notification.name}'),
              Text('Reg No: ${notification.regNo}'),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter weight in kg',
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kMainColor, width: 2),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Weight is required to mark as collected',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final weightText = weightController.text.trim();
                if (weightText.isEmpty) {
                  _showErrorSnackBar('Please enter a weight value');
                  return;
                }
                
                final weight = double.tryParse(weightText);
                if (weight == null || weight <= 0) {
                  _showErrorSnackBar('Please enter a valid weight value');
                  return;
                }
                
                Navigator.pop(context);
                _saveCollectionWithWeight(notification, weight);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
              ),
              child: Text(existingWeight != null ? 'Update' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCollectionWithWeight(NotificationData notification, double weight) async {
    try {
      await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .doc(notification.id)
          .update({
        'status': 'Collected',
        'collectedAt': Timestamp.now(),
        'collectedBy': FirebaseAuth.instance.currentUser?.uid,
        'weight': weight,
        'weightUnit': 'kg',
      });
      
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showSuccessSnackBar('Collection marked with weight: ${weight}kg');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save collection: ${e.toString()}');
      }
    }
  }

  Future<void> _removeWeightAndRevert(NotificationData notification) async {
    try {
      await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .doc(notification.id)
          .update({
        'status': 'Pending',
        'collectedAt': FieldValue.delete(),
        'collectedBy': FieldValue.delete(),
        'weight': FieldValue.delete(),
        'weightUnit': FieldValue.delete(),
      });
      
      if (mounted) {
        _showSuccessSnackBar('Weight removed and status reverted to pending');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to remove weight: ${e.toString()}');
      }
    }
  }

  void _openInMaps(NotificationData notification) {
    // Implementation for opening in external maps app
    // This would typically use url_launcher to open external maps
    _showInfoSnackBar('External navigation feature coming soon!');
  }

  Widget _buildPulseAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        final scale = 1.0 + (0.5 * sin(_pulseAnimationController.value * 2 * pi));
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.3 * (2.0 - scale)),
            ),
          ),
        );
      },
    );
  }

  void _changeTileLayer() {
    final layers = _tileLayers.keys.toList();
    final currentIndex = layers.indexOf(_currentTileLayer);
    final nextIndex = (currentIndex + 1) % layers.length;
    
    setState(() {
      _currentTileLayer = layers[nextIndex];
    });
    
    String layerName = _currentTileLayer;
    switch (_currentTileLayer) {
      case 'openstreetmap':
        layerName = 'Street Map';
        break;
      case 'satellite':
        layerName = 'Satellite';
        break;
      case 'terrain':
        layerName = 'Terrain';
        break;
    }
    
    _showInfoSnackBar('Switched to $layerName view');
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
      ),
    );
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
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _notificationStream?.cancel();
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Locations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _changeTileLayer,
            color: Colors.white,
            tooltip: 'Change map layer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fitMarkersInView,
            color: Colors.white,
            tooltip: 'Center all markers',
          ),
        ],
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeMap,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultLocation,
                        initialZoom: _defaultZoom,
                        minZoom: 3,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        _tileLayers[_currentTileLayer]!,
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    
                    // Statistics Card
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Requests',
                                _notifications.length.toString(),
                                Icons.notifications,
                                kMainColor,
                              ),
                              _buildStatItem(
                                'Pending',
                                _notifications.where((n) => n.status == 'Pending').length.toString(),
                                Icons.pending,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Selected notification card
                    if (_selectedNotification != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: SlideTransition(
                          position: _cardSlideAnimation,
                          child: _buildSelectedNotificationCard(),
                        ),
                      ),
                  ],
                ),
      
      // Floating action buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ScaleTransition(
            scale: _fabScaleAnimation,
            child: FloatingActionButton(
              heroTag: 'center_map',
              onPressed: _fitMarkersInView,
              backgroundColor: Colors.white,
              foregroundColor: kMainColor,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
          const SizedBox(height: 12),
          ScaleTransition(
            scale: _fabScaleAnimation,
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: _goToCurrentLocation,
              backgroundColor: kMainColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedNotificationCard() {
    final notification = _selectedNotification!;
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Reg: ${notification.regNo}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _selectedNotification = null);
                    _cardAnimationController.reset();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${notification.time} • ${notification.timeAgo}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showNotificationDetails(notification),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _markAsCollected(notification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Collected'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
      _showInfoSnackBar('Moved to your current location');
    } catch (e) {
      _showErrorSnackBar('Unable to get current location: ${e.toString()}');
    }
  }
}

// Data model for notifications
class NotificationData {
  final String id;
  final String customerId;
  final String name;
  final String regNo;
  final String collectorId;
  final String date;
  final String time;
  final String status;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? locationSource;

  NotificationData({
    required this.id,
    required this.customerId,
    required this.name,
    required this.regNo,
    required this.collectorId,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.address,
    this.locationSource,
  });

  factory NotificationData.fromFirestore(String id, Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>?;
    
    return NotificationData(
      id: id,
      customerId: data['customerId'] ?? '',
      name: data['name'] ?? 'Unknown',
      regNo: data['regNo'] ?? '',
      collectorId: data['collectorId'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: location?['latitude']?.toDouble(),
      longitude: location?['longitude']?.toDouble(),
      address: location?['address'],
      locationSource: location?['source'],
    );
  }

  bool get hasLocation => latitude != null && longitude != null;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}