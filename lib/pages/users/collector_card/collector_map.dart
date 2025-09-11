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
import 'package:TeaLink/l10n/app_localizations.dart';

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
  List<NotificationData> _todaysNotifications = []; // Add today's filtered list
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

    _pulseAnimationController.repeat();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _setupNotificationStream();
      if (mounted) {
        _fabAnimationController.forward();
        _pulseAnimationController.repeat();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.failedToLoadNotifications + ': ${e.toString()}';
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
      // Simplified query - fetch all collector's notifications and filter client-side
      // This avoids the composite index requirement
      _notificationStream = FirebaseFirestore.instance
          .collection('notify_for_collection')
          .where('collectorId', isEqualTo: currentUser.uid)
          .snapshots()
          .listen(
        (snapshot) {
          print('Received ${snapshot.docs.length} documents from Firestore');
          if (mounted) {
            _updateNotifications(snapshot.docs);
          }
        },
        onError: (error) {
          print('Notification stream error: $error');
          if (mounted) {
            setState(() {
              _errorMessage = AppLocalizations.of(context)!.error + ' loading notifications: ${error.toString()}';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error setting up notification stream: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to setup notification stream: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to check if a notification is from today
  bool _isFromToday(NotificationData notification) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Parse the notification's createdAt or date
    DateTime? notificationDate;
    
    try {
      if (notification.createdAt != null) {
        notificationDate = notification.createdAt;
      } else if (notification.date.isNotEmpty) {
        // Try to parse the date string
        notificationDate = DateTime.parse(notification.date);
      }
      
      if (notificationDate != null) {
        final notificationDay = DateTime(
          notificationDate.year, 
          notificationDate.month, 
          notificationDate.day
        );
        return notificationDay.isAtSameMomentAs(today);
      }
    } catch (e) {
      print('Error parsing date for notification ${notification.id}: $e');
    }
    
    return false;
  }

  void _updateNotifications(List<QueryDocumentSnapshot> docs) {
    final notifications = <NotificationData>[];
    int documentsWithLocation = 0;
    int documentsProcessed = 0;
    
    print('Processing ${docs.length} documents...');
    
    for (var doc in docs) {
      try {
        documentsProcessed++;
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          print('Document ${doc.id} data: $data');
          
          final notification = NotificationData.fromFirestore(doc.id, data);
          notifications.add(notification);
          
          if (notification.hasLocation) {
            documentsWithLocation++;
            print('✓ Document ${doc.id} has valid location: lat=${notification.latitude}, lng=${notification.longitude}');
          } else {
            print('✗ Document ${doc.id} missing location data');
          }
        }
      } catch (e) {
        print('Error parsing notification ${doc.id}: $e');
      }
    }
    
    // Filter for today's notifications client-side
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final todaysNotifications = notifications.where((notification) {
      if (notification.createdAt != null) {
        return notification.createdAt!.isAfter(today) && 
               notification.createdAt!.isBefore(tomorrow);
      } else if (notification.date.isNotEmpty) {
        try {
          // Try to parse date string (assuming format like "2024-01-15" or similar)
          final notificationDate = DateTime.parse(notification.date);
          final notificationDay = DateTime(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day
          );
          return notificationDay.isAtSameMomentAs(today);
        } catch (e) {
          print('Error parsing date ${notification.date}: $e');
          return false;
        }
      }
      return false;
    }).toList();
    
    final todaysDocumentsWithLocation = todaysNotifications
        .where((n) => n.hasLocation)
        .length;
    
    print('Summary: $documentsProcessed total processed, ${todaysNotifications.length} from today, $todaysDocumentsWithLocation with location');
    
    // Sort notifications
    todaysNotifications.sort((a, b) {
      if (a.hasLocation && !b.hasLocation) return -1;
      if (!a.hasLocation && b.hasLocation) return 1;
      return b.timeAgo.compareTo(a.timeAgo);
    });
    
    setState(() {
      _notifications = notifications; // Keep all notifications for reference
      _todaysNotifications = todaysNotifications; // Today's filtered notifications
      _isLoading = false;
      
      if (todaysNotifications.isEmpty) {
        _errorMessage = AppLocalizations.of(context)!.noCollectionRequestsToday;
      } else if (todaysDocumentsWithLocation == 0) {
        _errorMessage = AppLocalizations.of(context)!.noLocationDataAvailable.replaceAll('{count}', '${todaysNotifications.length}');
      } else {
        _errorMessage = null;
        print('Successfully loaded $todaysDocumentsWithLocation notifications with location out of ${todaysNotifications.length} total for today');
        
        // Fit markers in view after a delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _fitMarkersInView();
          }
        });
      }
    });
  }

  // UPDATED: Only show today's pending notifications on map
  List<Marker> _buildMarkers() {
    final todaysPendingNotifications = _todaysNotifications
        .where((n) => n.hasLocation && n.status == 'Pending')
        .toList();
    
    print('Building ${todaysPendingNotifications.length} markers for today (pending only)');
    
    return todaysPendingNotifications.map((notification) {
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
              // Main marker background - always orange for pending
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.orange[700]!],
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
                child: const Icon(
                  Icons.pending,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Status indicator - always red for pending
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
              // Pulse animation for pending notifications
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

  // UPDATED: Only fit today's pending notifications in view
  void _fitMarkersInView() {
    // Check if widget is mounted and controller is not disposed
    if (!mounted) {
      print('Widget not mounted, skipping fit markers');
      return;
    }

    final todaysPendingLocations = _todaysNotifications
        .where((n) => n.hasLocation && n.status == 'Pending')
        .map((n) => LatLng(n.latitude!, n.longitude!))
        .toList();
    
    print('Fitting ${todaysPendingLocations.length} today\'s pending markers in view');
    
    if (todaysPendingLocations.isEmpty) {
      print('No today\'s pending locations to fit');
      // Center on Sri Lanka if no pending locations
      try {
        _mapController.move(_defaultLocation, _defaultZoom);
      } catch (e) {
        print('Error moving to default location: $e');
      }
      return;
    }

    try {
      if (todaysPendingLocations.length == 1) {
        print('Single today\'s pending location, centering at: ${todaysPendingLocations.first}');
        _mapController.move(todaysPendingLocations.first, 15.0);
      } else {
        print('Multiple today\'s pending locations, calculating bounds...');
        double minLat = todaysPendingLocations.first.latitude;
        double maxLat = todaysPendingLocations.first.latitude;
        double minLng = todaysPendingLocations.first.longitude;
        double maxLng = todaysPendingLocations.first.longitude;
        
        for (var location in todaysPendingLocations) {
          minLat = min(minLat, location.latitude);
          maxLat = max(maxLat, location.latitude);
          minLng = min(minLng, location.longitude);
          maxLng = max(maxLng, location.longitude);
        }

        if (minLat == maxLat || minLng == maxLng) {
          print('Invalid bounds, centering on first location');
          _mapController.move(todaysPendingLocations.first, 15.0);
          return;
        }
        
        final bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );
        
        print('Bounds: ${bounds.southWest} to ${bounds.northEast}');
        
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(80),
          ),
        );
        
        print('Map bounds set successfully');
      }
    } catch (e) {
      print('Error fitting today\'s pending markers in view: $e');
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorNavigatingToLocation + ': ${e.toString()}');
      }
    }
  }

  // UPDATED: Only allow selection of today's pending notifications
  void _selectNotification(NotificationData notification) {
    if (!mounted) return;
    
    // Only allow selection of pending notifications on map
    if (notification.status != 'Pending') {
      _showInfoSnackBar(AppLocalizations.of(context)!.collectionCompletedAlready);
      return;
    }
    
    setState(() => _selectedNotification = notification);
    _cardAnimationController.forward();
    
    try {
      if (notification.hasLocation) {
        _mapController.move(
          LatLng(notification.latitude!, notification.longitude!),
          16.0,
        );
      }
    } catch (e) {
      print('Error moving map to notification: $e');
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorNavigatingToLocation);
      }
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
    final todaysCollectedCount = _todaysNotifications.where((n) => n.status == 'Collected').length;

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
                        '${AppLocalizations.of(context)!.registrationNo}: ${notification.regNo}',
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
                    notification.status == 'Pending' 
                      ? AppLocalizations.of(context)!.pending 
                      : AppLocalizations.of(context)!.collected,
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
                  _buildDetailRow(Icons.access_time, AppLocalizations.of(context)!.timeRequested, notification.time),
                  _buildDetailRow(Icons.calendar_today, AppLocalizations.of(context)!.date, notification.date),
                  _buildDetailRow(Icons.schedule, AppLocalizations.of(context)!.requested, notification.timeAgo),
                  if (notification.weight != null)
                    _buildDetailRow(Icons.scale, AppLocalizations.of(context)!.weight, '${notification.weight} ${notification.weightUnit ?? 'kg'}'),
                  if (notification.address?.isNotEmpty == true)
                    _buildDetailRow(Icons.location_on, AppLocalizations.of(context)!.address, notification.address!),
                  if (notification.hasLocation)
                    _buildDetailRow(
                      Icons.gps_fixed, 
                      AppLocalizations.of(context)!.coordinatess, 
                      '${notification.latitude!.toStringAsFixed(6)}, ${notification.longitude!.toStringAsFixed(6)}'
                    ),
                  if (notification.locationSource != null)
                    _buildDetailRow(
                      Icons.info, 
                      AppLocalizations.of(context)!.locationSource, 
                      notification.locationSource == 'stored' ? AppLocalizations.of(context)!.userProfile : AppLocalizations.of(context)!.currentGPS
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
                            label: Text(AppLocalizations.of(context)!.addWeight),
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
                          label: Text(AppLocalizations.of(context)!.navigate),
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
                            label: Text(AppLocalizations.of(context)!.updateWeight),
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
                          label: Text(AppLocalizations.of(context)!.remove),
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
          // Add info about today's completed collections not shown on map
          if (todaysCollectedCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.completedCollectionsHidden.replaceAll('{count}', '$todaysCollectedCount'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
        layerName = AppLocalizations.of(context)!.streetMap;
        break;
      case 'satellite':
        layerName = AppLocalizations.of(context)!.satellite;
        break;
      case 'terrain':
        layerName = AppLocalizations.of(context)!.terrain;
        break;
    }
    
    _showInfoSnackBar(AppLocalizations.of(context)!.switchedToMapView.replaceAll('{layerName}', layerName));
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
        title: Text(
          AppLocalizations.of(context)!.todaysCustomerLocations,
          style: const TextStyle(
            fontSize: 19,
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
            tooltip: AppLocalizations.of(context)!.changeMapLayer,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fitMarkersInView,
            color: Colors.white,
            tooltip: AppLocalizations.of(context)!.centerTodaysMarkers,
          ),
        ],
      ),
      
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.errorLoadingMap,
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
                        child: Text(AppLocalizations.of(context)!.retry),
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
                    
                    // Enhanced Statistics Card
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildEnhancedStatsCard(),
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
                                              '${AppLocalizations.of(context)!.registrationNo}: ${_selectedNotification!.regNo}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (_selectedNotification!.weight != null)
                                              Text(
                                                '${AppLocalizations.of(context)!.weight}: ${_selectedNotification!.weight} ${_selectedNotification!.weightUnit ?? 'kg'}',
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
                                          child: Text(AppLocalizations.of(context)!.viewDetails),
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
                                          child: Text(AppLocalizations.of(context)!.addWeight),
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
      
      // UPDATED: Floating Action Button only shows when there are today's pending locations
      floatingActionButton: _todaysNotifications.where((n) => n.hasLocation && n.status == 'Pending').isNotEmpty
          ? ScaleTransition(
              scale: _fabScaleAnimation,
              child: FloatingActionButton(
                onPressed: _fitMarkersInView,
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                tooltip: AppLocalizations.of(context)!.centerTodaysPendingCollections,
                child: const Icon(Icons.my_location),
              ),
            )
      
        : null,
         bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
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
                icon: Icon(Icons.home_rounded, size: 24),
                label: AppLocalizations.of(context)!.home,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_sharp, size: 24),
                label: AppLocalizations.of(context)!.map,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history, size: 24),
                label: AppLocalizations.of(context)!.history,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 24),
                label: AppLocalizations.of(context)!.profile,
              ),
            ],
          ),
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
        _showSuccessSnackBar(AppLocalizations.of(context)!.collectionCompletedSuccessfully);
        
        if (_selectedNotification?.id == notification.id) {
          setState(() => _selectedNotification = null);
          _cardAnimationController.reset();
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorOpeningWeightPage.replaceAll('{error}', e.toString()));
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
        _showSuccessSnackBar(AppLocalizations.of(context)!.weightUpdatedSuccessfully);
        
        if (_selectedNotification?.id == notification.id) {
          setState(() => _selectedNotification = null);
          _cardAnimationController.reset();
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorUpdatingWeight.replaceAll('{error}', e.toString()));
      }
    }
  }

  Future<void> _removeWeight(NotificationData notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeWeight),
        content: Text(AppLocalizations.of(context)!.areYouSureRemoveWeight.replaceAll('{customerName}', notification.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.remove, style: TextStyle(color: Colors.white)),
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
          _showSuccessSnackBar(AppLocalizations.of(context)!.weightRemovedSuccessfully);
          
          if (_selectedNotification?.id == notification.id) {
            setState(() => _selectedNotification = null);
            _cardAnimationController.reset();
          }
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(AppLocalizations.of(context)!.failedToRemoveWeight.replaceAll('{error}', e.toString()));
        }
      }
    }
  }

  void _openInMaps(NotificationData notification) {
    _showInfoSnackBar(AppLocalizations.of(context)!.externalNavigationComingSoon);
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

  // UPDATED: Calculate today's total weight only
  String _calculateTodaysTotalWeight() {
    double total = 0.0;
    for (var notification in _todaysNotifications) {
      if (notification.weight != null) {
        total += notification.weight!;
      }
    }
    return total.toStringAsFixed(1);
  }

  // UPDATED: Enhanced statistics card showing only today's data
  Widget _buildEnhancedStatsCard() {
    final todaysPendingCount = _todaysNotifications.where((n) => n.status == 'Pending').length;
    final todaysCollectedCount = _todaysNotifications.where((n) => n.status == 'Collected').length;
    final todaysPendingOnMapCount = _todaysNotifications.where((n) => n.hasLocation && n.status == 'Pending').length;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Today indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kMainColor.withOpacity(0.1), kMainColor.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kMainColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today, color: kMainColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.todaysCollections,
                    style: TextStyle(
                      color: kMainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  AppLocalizations.of(context)!.onMap,
                  todaysPendingOnMapCount.toString(),
                  Icons.location_on,
                  kMainColor,
                ),
                _buildStatItem(
                  AppLocalizations.of(context)!.pending,
                  todaysPendingCount.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatItem(
                  AppLocalizations.of(context)!.completed,
                  todaysCollectedCount.toString(),
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
                    AppLocalizations.of(context)!.todaysTotalWeight.replaceAll('{weight}', _calculateTodaysTotalWeight()),
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
    );
  }

 void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/collector_home');
        break;
      case 1:
        Navigator.pushNamed(context, '/collector_map');
        break;
      case 2:
        Navigator.pushNamed(context, '/collector_history');
        break;
      case 3:
        Navigator.pushNamed(context, '/collector_profile');
        break;
    }
  }
}

// UPDATED NotificationData class with createdAt field
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
  final DateTime? createdAt; // Add this field

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
    this.createdAt, // Add this parameter
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory NotificationData.fromFirestore(String id, Map<String, dynamic> data) {
    // Enhanced location extraction with multiple fallback strategies
    double? lat, lng;
    String? address, locationSource;

    // Strategy 1: Direct latitude/longitude fields
    lat = _parseLocationValue(data['latitude']);
    lng = _parseLocationValue(data['longitude']);
    
    // Strategy 2: Check nested location object
    if ((lat == null || lng == null) && data['location'] != null) {
      final locationData = data['location'];
      if (locationData is Map<String, dynamic>) {
        lat ??= _parseLocationValue(locationData['latitude']);
        lng ??= _parseLocationValue(locationData['longitude']);
        address = locationData['address']?.toString();
        locationSource = locationData['source']?.toString();
      }
    }
    
    // Strategy 3: Check for coordinate arrays
    if ((lat == null || lng == null) && data['coordinates'] != null) {
      final coords = data['coordinates'];
      if (coords is List && coords.length >= 2) {
        lat ??= _parseLocationValue(coords[0]);
        lng ??= _parseLocationValue(coords[1]);
      }
    }
    
    // Strategy 4: Check GeoPoint (Firestore's native location type)
    if ((lat == null || lng == null) && data['geopoint'] != null) {
      final geoPoint = data['geopoint'];
      if (geoPoint is GeoPoint) {
        lat = geoPoint.latitude;
        lng = geoPoint.longitude;
      }
    }

    // Extract other location-related data
    address ??= data['address']?.toString();
    locationSource ??= data['locationSource']?.toString();

    // Extract createdAt timestamp
    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      try {
        createdAt = DateTime.parse(data['createdAt']);
      } catch (e) {
        print('Error parsing createdAt string: $e');
      }
    }

    return NotificationData(
      id: id,
      name: data['customerName']?.toString() ?? data['name']?.toString() ?? 'Unknown',
      regNo: data['regNo']?.toString() ?? 'N/A',
      customerId: data['customerId']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Pending',
      time: data['time']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      timeAgo: _formatTimeAgo(data['createdAt']),
      latitude: lat,
      longitude: lng,
      address: address,
      locationSource: locationSource,
      weight: _parseToDouble(data['weight']),
      weightUnit: data['weightUnit']?.toString() ?? 'kg',
      createdAt: createdAt, // Add this field
    );
  }

  static double? _parseLocationValue(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    
    if (value is String && value.trim().isNotEmpty) {
      try {
        final cleaned = value.trim();
        return double.parse(cleaned);
      } catch (e) {
        print('Error parsing location string "$value": $e');
        return null;
      }
    }
    
    print('Unhandled location value type: ${value.runtimeType} = $value');
    return null;
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    
    if (value is String && value.trim().isNotEmpty) {
      try {
        String cleanedValue = value.trim().replaceAll(RegExp(r'[^\d.-]'), '');
        if (cleanedValue.isEmpty) return null;
        
        return double.parse(cleanedValue);
      } catch (e) {
        print('Error parsing string to double: "$value" : $e');
        return null;
      }
    }
    
    return null;
  }

  static String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    try {
      DateTime createdAt;
      if (timestamp is Timestamp) {
        createdAt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        createdAt = timestamp;
      } else if (timestamp is String) {
        createdAt = DateTime.parse(timestamp);
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
      print('Error formatting time: $e');
      return 'Unknown time';
    }
  }
}