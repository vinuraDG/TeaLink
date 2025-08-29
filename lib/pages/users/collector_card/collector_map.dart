import 'dart:async';
import 'dart:math';
import 'package:TeaLink/pages/users/collector_card/add_weight.dart';
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
  int _selectedIndex = 1;
  
  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;
  
  // Map settings
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
      // Stream notifications for this collector - including all statuses to show weight info
      _notificationStream = FirebaseFirestore.instance
          .collection('notify_for_collection')
          .where('collectorId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
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
        width: 80.0,
        height: 80.0,
        point: LatLng(notification.latitude!, notification.longitude!),
        child: GestureDetector(
          onTap: () => _selectNotification(notification),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
              // Main marker background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getMarkerColors(notification),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMarkerIcon(notification),
                      color: Colors.white,
                      size: 20,
                    ),
                    if (notification.weight != null)
                      Text(
                        '${notification.weight}kg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              // Status indicator
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(notification),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getStatusIcon(notification),
                    color: Colors.white,
                    size: 10,
                  ),
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

  List<Color> _getMarkerColors(NotificationData notification) {
    switch (notification.status) {
      case 'Pending':
        return [Colors.orange, Colors.orange[700]!];
      case 'Collected':
        return [Colors.green, Colors.green[700]!];
      default:
        return [Colors.grey, Colors.grey[700]!];
    }
  }

  IconData _getMarkerIcon(NotificationData notification) {
    if (notification.weight != null) {
      return Icons.scale;
    }
    return notification.status == 'Pending' ? Icons.pending : Icons.check_circle;
  }

  Color _getStatusColor(NotificationData notification) {
    switch (notification.status) {
      case 'Pending':
        return Colors.red;
      case 'Collected':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(NotificationData notification) {
    switch (notification.status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Collected':
        return Icons.check;
      default:
        return Icons.help;
    }
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
            padding: const EdgeInsets.all(80),
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
                  if (notification.weight != null)
                    _buildDetailRow(Icons.scale, 'Weight', '${notification.weight} ${notification.weightUnit ?? 'kg'}'),
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
                  if (notification.status == 'Pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _markAsCollected(notification),
                            icon: const Icon(Icons.scale),
                            label: const Text('Add Weight'),
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
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateWeight(notification),
                            icon: const Icon(Icons.edit),
                            label: const Text('Update Weight'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
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
                          onPressed: () => _removeWeight(notification),
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
    try {
      // Create document reference for the notification
      final docRef = FirebaseFirestore.instance
          .collection('notify_for_collection')
          .doc(notification.id);

      // Navigate to AddWeightPage
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddWeightPage(
            customerName: notification.name,
            regNo: notification.regNo,
            docReference: docRef,
            customerId: notification.customerId,
          ),
        ),
      );

      // If weight was successfully saved (result == true), show success message
      if (result == true && mounted) {
        _showSuccessSnackBar('Collection completed successfully!');
        
        // Close the selected notification card if it's open
        if (_selectedNotification?.id == notification.id) {
          setState(() => _selectedNotification = null);
          _cardAnimationController.reset();
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error opening weight page: ${e.toString()}');
      }
    }
  }

  Future<void> _updateWeight(NotificationData notification) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('notify_for_collection')
          .doc(notification.id);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddWeightPage(
            customerName: notification.name,
            regNo: notification.regNo,
            docReference: docRef,
            customerId: notification.customerId,
          ),
        ),
      );

      if (result == true && mounted) {
        _showSuccessSnackBar('Weight updated successfully!');
        
        if (_selectedNotification?.id == notification.id) {
          setState(() => _selectedNotification = null);
          _cardAnimationController.reset();
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating weight: ${e.toString()}');
      }
    }
  }

  Future<void> _removeWeight(NotificationData notification) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Weight'),
        content: Text('Are you sure you want to remove the weight for ${notification.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
          _showSuccessSnackBar('Weight removed successfully');
          
          if (_selectedNotification?.id == notification.id) {
            setState(() => _selectedNotification = null);
            _cardAnimationController.reset();
          }
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to remove weight: ${e.toString()}');
        }
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
        final scale = 1.0 + (0.3 * sin(_pulseAnimationController.value * 2 * pi));
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.2 * (2.0 - scale)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  String _calculateTotalWeight() {
    double total = 0.0;
    for (var notification in _notifications) {
      if (notification.weight != null) {
        total += notification.weight!;
      }
    }
    return total.toStringAsFixed(1);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
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
                    
                    // Enhanced Statistics Card with Weight Info
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
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Total',
                                    _notifications.length.toString(),
                                    Icons.location_on,
                                    kMainColor,
                                  ),
                                  _buildStatItem(
                                    'Pending',
                                    _notifications.where((n) => n.status == 'Pending').length.toString(),
                                    Icons.pending,
                                    Colors.orange,
                                  ),
                                  _buildStatItem(
                                    'Collected',
                                    _notifications.where((n) => n.status == 'Collected').length.toString(),
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.scale, color: Colors.blue[700], size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Weight: ${_calculateTotalWeight()} kg',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                        fontSize: 14,
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
                    
                    // Selected Notification Card
                    if (_selectedNotification != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: SlideTransition(
                          position: _cardSlideAnimation,
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _getMarkerColors(_selectedNotification!),
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getMarkerIcon(_selectedNotification!),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedNotification!.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Reg: ${_selectedNotification!.regNo}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (_selectedNotification!.weight != null)
                                              Text(
                                                'Weight: ${_selectedNotification!.weight} ${_selectedNotification!.weightUnit ?? 'kg'}',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _showNotificationDetails(_selectedNotification!),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kMainColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('View Details'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_selectedNotification!.status == 'Pending')
                                        ElevatedButton(
                                          onPressed: () => _markAsCollected(_selectedNotification!),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('Add Weight'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      
      // Floating Action Button for centering map
      floatingActionButton: _notifications.isNotEmpty
          ? ScaleTransition(
              scale: _fabScaleAnimation,
              child: FloatingActionButton(
                onPressed: _fitMarkersInView,
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.my_location),
              ),
            )
          : null,
    );
  }
}

// NotificationData model class
class NotificationData {
  final String id;
  final String name;
  final String regNo;
  final String customerId;
  final String status;
  final String time;
  final String date;
  final String timeAgo;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? locationSource;
  final double? weight;
  final String? weightUnit;

  NotificationData({
    required this.id,
    required this.name,
    required this.regNo,
    required this.customerId,
    required this.status,
    required this.time,
    required this.date,
    required this.timeAgo,
    this.latitude,
    this.longitude,
    this.address,
    this.locationSource,
    this.weight,
    this.weightUnit,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory NotificationData.fromFirestore(String id, Map<String, dynamic> data) {
    return NotificationData(
      id: id,
      name: data['customerName'] ?? 'Unknown',
      regNo: data['regNo'] ?? 'N/A',
      customerId: data['customerId'] ?? '',
      status: data['status'] ?? 'Pending',
      time: data['time'] ?? '',
      date: data['date'] ?? '',
      timeAgo: _formatTimeAgo(data['createdAt']),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      address: data['address'],
      locationSource: data['locationSource'],
      weight: data['weight']?.toDouble(),
      weightUnit: data['weightUnit'],
    );
  }

  static String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    try {
      DateTime createdAt;
      if (timestamp is Timestamp) {
        createdAt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        createdAt = timestamp;
      } else {
        return 'Unknown time';
      }
      
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 30).floor()} months ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}