import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';

class AddressMapScreen extends StatefulWidget {
  const AddressMapScreen({super.key});

  @override
  State<AddressMapScreen> createState() => _AddressMapScreenState();
}

class _AddressMapScreenState extends State<AddressMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  String _currentSelectedAddress = ""; 
  bool _isLoadingLocation = false;
  LatLng? _selectedLocation;
  
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  final Completer<GoogleMapController> _mapController = Completer();

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        final results = await ApiService.getPlaceSuggestions(query);
        setState(() {
          _suggestions = results;
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> place) async {
    setState(() {
      _currentSelectedAddress = place['description'];
      _searchController.text = place['description'];
      _suggestions = [];
      _selectedLocation = LatLng(place['lat'], place['lng']);
    });
    
    _moveCameraTo(_selectedLocation!);
  }

  Future<void> _moveCameraTo(LatLng target) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: 15),
    ));
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable GPS/Location Services on your device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions were denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      } 

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        
        setState(() {
          _searchController.text = address;
          _currentSelectedAddress = address;
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        
        _moveCameraTo(_selectedLocation!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current location found!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        title: const Text('Select Address', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentSelectedAddress.isNotEmpty ? _currentSelectedAddress : null),
        ),
      ),
      body: Stack(
        children: [
          // Google Map Background (only shows if a location is selected)
          // Google Map Background
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? const LatLng(28.6139, 77.2090), // Default to New Delhi
              zoom: _selectedLocation != null ? 15 : 4.5,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            markers: _selectedLocation != null ? {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLocation!,
              ),
            } : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
            
          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search Your Address',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final place = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.grey),
                          title: Text(place['description'] ?? ''),
                          onTap: () => _selectSuggestion(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Use Current Location Button
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _isLoadingLocation ? null : _useCurrentLocation,
              backgroundColor: Colors.white,
              icon: _isLoadingLocation 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935)))
                  : const Icon(Icons.my_location, color: Color(0xFFE53935)),
              label: Text(
                _isLoadingLocation ? "Fetching..." : "Use Current Location", 
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
              ),
            ),
          ),
          
          // Save Button
          if (_selectedLocation != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final addressToSave = _searchController.text.isNotEmpty 
                        ? _searchController.text 
                        : _currentSelectedAddress;
                    Navigator.pop(context, {
                      'address': addressToSave,
                      'lat': _selectedLocation?.latitude ?? 0.0,
                      'lng': _selectedLocation?.longitude ?? 0.0,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
