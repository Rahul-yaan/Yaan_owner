import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/models/owner_profile_model.dart';
import '../core/models/user_model.dart';
import '../services/profile_service.dart';
import '../core/models/hotel_model.dart';
import '../services/hotel_service.dart';

class EditProfileScreen extends StatefulWidget {
  final OwnerProfileModel? profile;
  final UserModel? user;

  const EditProfileScreen({super.key, this.profile, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final HotelService _hotelService = HotelService();
  HotelModel? _currentHotel;

  final Map<String, bool> _amenities = {
    'Free WiFi': false,
    'Air Conditioning': false,
    'Room Service': false,
    'Free Parking': false,
    'Wifi': true,
    'Rest Rooms': false,
    'Fuel Stations': false,
    'Dining Facilities': false,
    'Comfortable Rooms': false,
    'ATM': false,
    'Convenience Stores': false,
    'First Aid': false,
    'Fitness center': false,
    'Food Outlets': false,
    'Showers': false,
    'Laundry Services': false,
    'Seating Areas': false,
    'Swimming Pool': false,
    'Men': false,
    'Women': false,
  };

  final ImagePicker _picker = ImagePicker();

  late TextEditingController _hotelNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _priceController;
  
  String? _selectedState;
  String? _selectedCity;

  File? _hotelImageFile;
  File? _businessProofFile;
  File? _aadharCardFile;
  
  bool _isLoading = false;

  final List<String> _states = ['Gujarat', 'Maharashtra', 'Delhi'];
  final List<String> _cities = ['Ahmedabad', 'Surat', 'Mumbai', 'New Delhi'];

  @override
  void initState() {
    super.initState();
    _hotelNameController = TextEditingController(text: widget.profile?.hotelName ?? '');
    _ownerNameController = TextEditingController(text: widget.profile?.ownerName ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _addressController = TextEditingController(text: widget.profile?.address ?? '');
    _pincodeController = TextEditingController(text: widget.profile?.pincode ?? '');
    _priceController = TextEditingController(text: '42.37');
    
    if (widget.profile?.state.isNotEmpty == true && _states.contains(widget.profile?.state)) {
      _selectedState = widget.profile?.state;
    }
    if (widget.profile?.city.isNotEmpty == true && _cities.contains(widget.profile?.city)) {
      _selectedCity = widget.profile?.city;
    }
    _fetchHotelData();
  }

  Future<void> _fetchHotelData() async {
    try {
      final hotels = await _hotelService.getHotels();
      if (hotels.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentHotel = hotels.first;
            if (_currentHotel != null) {
                _priceController.text = _currentHotel!.pricePerNight.toString();
                if ((double.tryParse(_priceController.text) ?? 0.0) < 42.37) {
                    _priceController.text = '42.37';
                }
            }
            if (_currentHotel?.amenities != null) {
                final Map<int, String> idToName = {
                  1: "Free WiFi", 2: "Air Conditioning", 3: "Room Service", 4: "Swimming Pool", 5: "Free Parking",
                  6: "Wifi", 7: "Rest Rooms", 8: "Fuel Stations", 9: "Dining Facilities", 10: "Comfortable Rooms",
                  11: "ATM", 12: "Convenience Stores", 13: "First Aid", 14: "Fitness center", 15: "Food Outlets",
                  16: "Showers", 17: "Laundry Services", 18: "Seating Areas", 19: "Men", 20: "Women"
                };
                // Reset all to false first
                _amenities.forEach((key, _) => _amenities[key] = false);
                // Set true for available ones
                for (var id in _currentHotel!.amenities!) {
                    if (idToName.containsKey(id) && _amenities.containsKey(idToName[id])) {
                        _amenities[idToName[id]!] = true;
                    }
                }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching hotel: $e');
    }
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image != null) {
      setState(() {
        if (type == 'hotel') _hotelImageFile = File(image.path);
        else if (type == 'business') _businessProofFile = File(image.path);
        else if (type == 'aadhar') _aadharCardFile = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    double enteredPrice = double.tryParse(_priceController.text) ?? 0.0;
    if (enteredPrice < 42.37) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price cannot be less than 42.37')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'hotel_name': _hotelNameController.text,
        'owner_name': _ownerNameController.text,
        'address': _addressController.text,
        'state': _selectedState ?? '',
        'city': _selectedCity ?? '',
        'pincode': _pincodeController.text,
      };

      Map<String, File> files = {};
      // Mapping mock UI fields to backend fields
      if (_businessProofFile != null) files['business_proof'] = _businessProofFile!;
      if (_aadharCardFile != null) files['aadhaar_front'] = _aadharCardFile!;

      await _profileService.updateProfile(data: data, files: files.isNotEmpty ? files : null);

      if (_currentHotel != null) {
          final Map<String, int> amenityIds = {
            "Free WiFi": 1, "Air Conditioning": 2, "Room Service": 3, "Swimming Pool": 4, "Free Parking": 5,
            "Wifi": 6, "Rest Rooms": 7, "Fuel Stations": 8, "Dining Facilities": 9, "Comfortable Rooms": 10,
            "ATM": 11, "Convenience Stores": 12, "First Aid": 13, "Fitness center": 14, "Food Outlets": 15,
            "Showers": 16, "Laundry Services": 17, "Seating Areas": 18, "Men": 19, "Women": 20
          };
          List<int> selectedAmenities = [];
          _amenities.forEach((key, isSelected) {
            if (isSelected && amenityIds.containsKey(key)) {
              selectedAmenities.add(amenityIds[key]!);
            }
          });
          
          await _hotelService.updateHotel(_currentHotel!.id!, {
              'name': _hotelNameController.text,
              'price_per_night': enteredPrice,
              'amenities': selectedAmenities,
          });

          if (_hotelImageFile != null) {
              await _hotelService.uploadHotelImages(_currentHotel!.id!, {'Upload Your Hotel Image': _hotelImageFile!.path});
          }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to refresh account screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Enter Details To Edit Your Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    _buildImageUploadField('Upload Your Hotel Image', 'hotel', _hotelImageFile),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_hotelNameController, 'Enter Hotel Name'),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_ownerNameController, 'Enter Owner Name'),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_priceController, 'Enter Price per night (Min 42.37)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_phoneController, 'Phone Number', isReadOnly: true),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_emailController, 'Enter Email ID', isReadOnly: true),
                    const SizedBox(height: 16),
                    
                    _buildAddressField(),
                    const SizedBox(height: 16),
                    
                    _buildDropdown('State', _states, _selectedState, (val) => setState(() => _selectedState = val)),
                    const SizedBox(height: 16),
                    
                    _buildDropdown('City', _cities, _selectedCity, (val) => setState(() => _selectedCity = val)),
                    const SizedBox(height: 16),
                    
                    _buildDropdown('Select Road', ['Road 1', 'Road 2'], null, (val) {}),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_pincodeController, 'Pincode'),
                    const SizedBox(height: 16),
                    
                    _buildImageUploadField('Upload Your Business Proof', 'business', _businessProofFile),
                    const SizedBox(height: 16),
                    
                    _buildImageUploadField('Upload Your Aadhar Card', 'aadhar', _aadharCardFile),
                    const SizedBox(height: 16),

                    _buildAmenities(),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC0392B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('UPDATE PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isReadOnly = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        hintText: 'Address',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFC0392B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('MAP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildImageUploadField(String label, String type, File? file) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                file != null ? file.path.split('/').last : label,
                style: TextStyle(color: file != null ? Colors.black87 : Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0, top: 16.0),
          child: Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: _amenities.keys.length,
            itemBuilder: (context, index) {
              String key = _amenities.keys.elementAt(index);
              return Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _amenities[key],
                      onChanged: (bool? value) {
                        setState(() {
                          _amenities[key] = value ?? false;
                        });
                      },
                      activeColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      key, 
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    )
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
