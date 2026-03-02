import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../global/global_vars.dart';

// Assuming these variables and utilities are available globally
// NOTE: I'm assuming 'global_vars.googleApiKey' is the correct access method based on context.
String kGoogleApiKey = googleApiKey;
Color primaryColor = const Color(0xFF1A2B7B);


class SellerTrackingDetailView extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> initialOrderData;

  const SellerTrackingDetailView({
    super.key,
    required this.requestId,
    required this.initialOrderData,
  });

  @override
  State<SellerTrackingDetailView> createState() => _SellerTrackingDetailViewState();
}

class _SellerTrackingDetailViewState extends State<SellerTrackingDetailView> {
  Stream<DocumentSnapshot>? _orderStream;

  @override
  void initState() {
    super.initState();
    _orderStream = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.requestId)
        .snapshots();
  }

  /// Fetches the customer's name from the 'users' collection using the 'userId'
  /// and merges it into the orderData map under the key 'customerName'.
  Future<Map<String, dynamic>> _fetchUserAndEnrichData(Map<String, dynamic> orderData) async {
    final userId = orderData['userId'] as String?;

    if (userId != null && userId.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final userName = userData?['name'] as String?; // Assuming 'name' is the customer's name field

          if (userName != null) {
            final enrichedData = Map<String, dynamic>.from(orderData);
            // Store the fetched name in a known key for the map widget
            enrichedData['customerName'] = userName;
            return enrichedData;
          }
        }
      } catch (e) {
        debugPrint('Error fetching user details: $e');
      }
    }
    // Return original data if userId is missing or fetch fails
    return orderData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Order Tracking (Seller)', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found or completed.'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          // Wrap the map widget construction in a FutureBuilder to fetch customer name
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserAndEnrichData(orderData),
            builder: (context, futureSnapshot) {
              // Show loading if the customer name fetch is ongoing
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final enrichedOrderData = futureSnapshot.data ?? orderData;

              return _TrackingMapWidget(
                orderData: enrichedOrderData,
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------
// Reusable Core Tracking Map Widget
// -------------------------------------------------------------------

class _RouteResult {
  final List<LatLng> points;
  final String? distanceText;
  final String? durationText;

  _RouteResult({
    required this.points,
    this.distanceText,
    this.durationText,
  });
}

class _TrackingMapWidget extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const _TrackingMapWidget({
    required this.orderData,
  });

  @override
  State<_TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<_TrackingMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Tracking state variables
  LatLng? _driverPosition;
  LatLng? _lastDriverLocation;
  String? _currentStatus;
  String? _driverId;
  String? _vehicleType;

  // Custom Icons
  BitmapDescriptor? _motorbikeIcon;
  BitmapDescriptor? _bicycleIcon;
  BitmapDescriptor? _assignedDriverIcon;

  // Route Info
  String? _routeDistance;
  String? _routeDuration;

  // Map type toggle
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _initializeData(widget.orderData);
    _loadCustomIcons().then((_) {
      if (mounted) {
        _updateMapElements();
      }
    });
  }

  @override
  void didUpdateWidget(_TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orderData != oldWidget.orderData) {
      _initializeData(widget.orderData);
      _updateMapElements();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeData(Map<String, dynamic> data) {
    _currentStatus = data['status'] as String?;
    _driverId = data['driverId'] as String?;
    _vehicleType = data['rideType'] as String? ?? 'motorbike';

    final driverLat = data['driverLat'] as double?;
    final driverLng = data['driverLng'] as double?;

    if (driverLat != null && driverLng != null) {
      _lastDriverLocation = _driverPosition;
      _driverPosition = LatLng(driverLat, driverLng);
    } else {
      _driverPosition = null;
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      _assignedDriverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      // Ensure these asset paths are correct and files exist in pubspec.yaml
      _motorbikeIcon = await _createCustomIcon('images/bike-delivery-icon.png', size: 128);
      _bicycleIcon = await _createCustomIcon('images/bike-delivery-icon.png', size: 128);
    } catch (e) {
      debugPrint('Error loading custom icons: $e');
      // Fallback
      _motorbikeIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _bicycleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      _assignedDriverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  Future<BitmapDescriptor> _createCustomIcon(String assetPath, {int size = 150}) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
      );
      final frame = await codec.getNextFrame();
      final bytes = (await frame.image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _updateMapElements() async {
    _markers.clear();
    _polylines.clear();

    // Ensure safe casting for nested maps and coordinates
    final pickupData = widget.orderData['seller'] as Map<String, dynamic>?;
    final dropoffData = widget.orderData['dropoff'] as Map<String, dynamic>?;

    final pickupLat = pickupData?['lat'] as double?;
    final pickupLng = pickupData?['lng'] as double?;
    final dropoffLat = dropoffData?['lat'] as double?;
    final dropoffLng = dropoffData?['lng'] as double?;

    final pointsToFit = <LatLng>[];

    // 1. Add Pickup Marker (Seller's Location)
    if (pickupLat != null && pickupLng != null) {
      final pickupPoint = LatLng(pickupLat, pickupLng);
      _markers.add(_buildMarker('pickup', pickupPoint, '📦 Pickup (Your Shop)',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), 10));
      pointsToFit.add(pickupPoint);
    }

    // 2. Add Dropoff Marker (Customer's Location)
    if (dropoffLat != null && dropoffLng != null) {
      final dropoffPoint = LatLng(dropoffLat, dropoffLng);
      _markers.add(_buildMarker('destination', dropoffPoint, '🏁 Customer Dropoff',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), 10));
      pointsToFit.add(dropoffPoint);
    }

    // 3. Handle Routes and Driver Marker
    if (pickupLat != null && pickupLng != null && dropoffLat != null && dropoffLng != null) {
      final pickup = LatLng(pickupLat, pickupLng);
      final dropoff = LatLng(dropoffLat, dropoffLng);

      // *** LOGIC: ALWAYS DRAW MAIN ROUTE IN GREEN ***
      await _fetchMainRoute(pickup, dropoff); // This draws the green route

      if (_driverPosition != null && _driverId != null && _driverId!.isNotEmpty) {
        _updateDriverMarker();
        await _drawDriverRoute(pickup, dropoff); // This draws the blue/purple active driver route
        pointsToFit.add(_driverPosition!);
      }
    }


    if (mounted) {
      setState(() {});
      // Delay fitting camera until map controller is initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use all marker positions for the fit
        final markerPositions = _markers.map((m) => m.position).toList();
        _fitAllMarkers(markerPositions);
      });
    }
  }

  Marker _buildMarker(String id, LatLng position, String title, BitmapDescriptor icon, double zIndex) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon,
      infoWindow: InfoWindow(title: title),
      zIndex: zIndex,
    );
  }

  void _updateDriverMarker() {
    if (_driverPosition == null) return;

    double rotation = 0.0;
    if (_lastDriverLocation != null) {
      rotation = _calculateBearing(_lastDriverLocation!, _driverPosition!);
    }

    // Check if icons are loaded (Handle null icons gracefully)
    BitmapDescriptor iconToUse = _assignedDriverIcon!;
    if (_vehicleType?.toLowerCase() == 'motorbike' && _motorbikeIcon != null) {
      iconToUse = _motorbikeIcon!;
    } else if (_vehicleType?.toLowerCase() == 'bicycle' && _bicycleIcon != null) {
      iconToUse = _bicycleIcon!;
    }


    final marker = Marker(
      markerId: const MarkerId('assigned_driver'),
      position: _driverPosition!,
      icon: iconToUse,
      infoWindow: InfoWindow(title: '🏍️ Driver: ${widget.orderData['driverName'] ?? 'N/A'}'),
      rotation: rotation,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      zIndex: 9,
    );

    _markers.add(marker);
  }

  // Draws the route from the driver's location to the next target
  Future<void> _drawDriverRoute(LatLng pickup, LatLng dropoff) async {
    if (_driverPosition == null) return;

    LatLng? targetPoint;
    Color routeColor = Colors.blue;
    String routePolylineId = 'driver_to_pickup_route';

    if (_currentStatus == 'in-progress') {
      targetPoint = pickup;
      routeColor = Colors.blue.shade700;
      routePolylineId = 'driver_to_pickup_route';
    } else if (_currentStatus == 'onTheWay' || _currentStatus == 'heading_to_destination') {
      targetPoint = dropoff;
      routeColor = Colors.purple.shade700;
      routePolylineId = 'driver_to_dropoff_route';
    } else {
      return;
    }

    if (targetPoint == null) return;

    final result = await _fetchDirections(_driverPosition!, targetPoint);

    if (result.points.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId(routePolylineId),
          points: result.points,
          color: routeColor,
          width: 8, // Driver route is thicker for prominence
          jointType: JointType.round,
          zIndex: 5, // Higher Z-index to layer over the main green route
        ),
      );
      _routeDistance = result.distanceText;
      _routeDuration = result.durationText;
    }
  }

  // Draws the main, static route from pickup to dropoff
  Future<void> _fetchMainRoute(LatLng pickup, LatLng dropoff) async {
    final result = await _fetchDirections(pickup, dropoff);

    if (result.points.isNotEmpty) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('main_route'),
        color: Colors.green.shade700, // Explicitly set to a darker green
        width: 7, // Slightly thicker
        points: result.points,
        zIndex: 3, // Lower Z-index than the driver route
      ));

      // Only set this if the driver route isn't active
      if (_driverPosition == null || _currentStatus == 'prepared') {
        _routeDistance = result.distanceText;
        _routeDuration = result.durationText;
      }
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (math.pi / 180);
    final startLng = start.longitude * (math.pi / 180);
    final endLat = end.latitude * (math.pi / 180);
    final endLng = end.longitude * (math.pi / 180);

    final dLng = endLng - startLng;

    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    double bearing = math.atan2(y, x) * (180 / math.pi);
    return (bearing + 360) % 360;
  }

  Future<_RouteResult> _fetchDirections(LatLng origin, LatLng dest) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${dest.latitude},${dest.longitude}'
          '&mode=driving'
          '&key=$kGoogleApiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) return _RouteResult(points: const []);

      final route = routes.first as Map<String, dynamic>;
      final polylineStr = (route['overview_polyline']?['points'] as String?) ?? '';
      final points = _decodePolyline(polylineStr);

      String? distance, duration;
      final legs = (route['legs'] as List?) ?? const [];
      if (legs.isNotEmpty) {
        final leg = legs.first as Map<String, dynamic>;
        distance = leg['distance']?['text'] as String?;
        duration = leg['duration']?['text'] as String?;
      }

      return _RouteResult(
        points: points,
        distanceText: distance,
        durationText: duration,
      );
    } catch (e) {
      debugPrint('🚨 Error fetching directions: $e');
      return _RouteResult(points: const []);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {

    if (encoded.isEmpty) return [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    final List<LatLng> points = [];

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _fitAllMarkers(List<LatLng> points) {
    if (_mapController == null) return;

    // Fallback: If no markers, center on initial coordinates
    if (points.isEmpty) {
      final pickupData = widget.orderData['seller'] as Map<String, dynamic>?;
      final pickupLat = pickupData?['lat'] as double?;
      final pickupLng = pickupData?['lng'] as double?;
      if (pickupLat != null && pickupLng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pickupLat, pickupLng), 15.0),
        );
      }
      return;
    }


    double? minLat, maxLat, minLng, maxLng;
    for (final point in points) {
      minLat = (minLat == null || point.latitude < minLat) ? point.latitude : minLat;
      maxLat = (maxLat == null || point.latitude > maxLat) ? point.latitude : maxLat;
      minLng = (minLng == null || point.longitude < minLng) ? point.longitude : minLng;
      maxLng = (maxLng == null || point.longitude > maxLng) ? point.longitude : maxLng;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      // Crucial Check: Ensure the bounds are large enough to be valid.
      if ((maxLat - minLat).abs() > 0.0001 || (maxLng - minLng).abs() > 0.0001) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            100, // Padding
          ),
        );
      } else {
        // If all points are nearly identical (e.g., only one marker visible), just center on that single point
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15.0),
        );
      }
    }
  }

  String _getStatusTitle() {
    if (_currentStatus == 'prepared') {
      return 'Order is Prepared and Awaiting Driver';
    }

    if (_currentStatus == 'in-progress') {
      return 'Driver En Route to Pickup';
    }

    if (_currentStatus == 'onTheWay' || _currentStatus == 'heading_to_destination') {
      return 'Order En Route to Customer';
    }

    if (_currentStatus == 'delivered') {
      return 'Order Delivered';
    }

    return 'Status: ${_currentStatus ?? 'Awaiting Driver'}';
  }

  String _getETAMessage() {
    if (_currentStatus == 'prepared') {
      return 'A driver is being assigned shortly.';
    }

    if (_routeDuration != null && _routeDistance != null) {
      return 'Driver ETA: ${_routeDuration!} (${_routeDistance!})';
    }

    if (_currentStatus == 'delivered') {
      return 'The order has been successfully delivered.';
    }

    return _driverId == null ? 'Awaiting driver assignment.' : 'Calculating driver ETA...';
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }
  @override
  Widget build(BuildContext context) {
    final pickupData = widget.orderData['seller'] as Map<String, dynamic>?;
    final pickupLat = pickupData?['lat'] as double?;
    final pickupLng = pickupData?['lng'] as double?;

    return Stack(
      children: [
        // Main Google Map
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            // Fit map after controller is ready and after markers are added
            _fitAllMarkers(_markers.map((m) => m.position).toList());
          },
          initialCameraPosition: CameraPosition(
            target: pickupLat != null && pickupLng != null
                ? LatLng(pickupLat, pickupLng)
                : const LatLng(0, 0),
            zoom: 13,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: _currentMapType,
        ),

        // Map Controls
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'mapTypeSeller',
                onPressed: _toggleMapType,
                backgroundColor: primaryColor,
                child: const Icon(Icons.layers, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'recenterSeller',
                onPressed: () => _fitAllMarkers(
                    _markers.map((m) => m.position).toList()
                ),
                backgroundColor: Colors.white,
                child: Icon(Icons.screen_rotation_alt, color: primaryColor),
              ),
            ],
          ),
        ),

        // Status Card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Icon(
                        _driverId == null ? Icons.search : Icons.delivery_dining,
                        color: Colors.black54,
                        size: 30,
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _getETAMessage(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDriverAndCustomerInfo(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverAndCustomerInfo() {
    final driverName = widget.orderData['driverName'] ?? 'Awaiting Assignment';

    // *** UPDATED TO USE ENRICHED DATA ***
    final customerName = widget.orderData['customerName'] ?? 'Customer';

    final total = widget.orderData['total']?.toStringAsFixed(2) ?? 'N/A';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Driver:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text(driverName, style: TextStyle(color: _driverId == null ? Colors.red : Colors.green)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black)),
            Text(customerName, style: TextStyle(
                color: Colors.black
            ),),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text('ZMW $total', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ],
    );
  }
}