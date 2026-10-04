import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/hotel_service.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../core/models/hotel_model.dart';
import '../core/utils/india_locations.dart';
import 'address_map_screen.dart';
import 'dashboard_screen.dart';

class HotelSetupScreen extends StatefulWidget {
  const HotelSetupScreen({super.key});

  @override
  State<HotelSetupScreen> createState() => _HotelSetupScreenState();
}

class _HotelSetupScreenState extends State<HotelSetupScreen> {
  String _address = '';
  double _latitude = 28.6139; // Default to New Delhi
  double _longitude = 77.2090;
  bool _freeBreakfast = true;
  
  String? _selectedState;
  String? _selectedCity;
  String? _selectedRoad;
  
  bool _isSubmitting = false;
  final HotelService _hotelService = HotelService();
  final ProfileService _profileService = ProfileService();
  
  String _ownerPhone = 'Loading...';
  String? _kycStatus;
  String? _rejectionReason;
  String? _kycMessage;
  
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _uploadedImages = {};

  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _fssaiController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(text: '42.37');
  final TextEditingController _totalSlotsController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _hotelNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _fssaiController.dispose();
    _gstController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _priceController.dispose();
    _totalSlotsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final res = await ApiService.getProfile();
    if (res != null) {
      if (mounted) {
        setState(() {
          _ownerPhone = res['user']?['phone'] ?? 'N/A';
          _kycStatus = res['kyc_status'];
          _rejectionReason = res['rejection_reason'];
          _kycMessage = res['kyc_message'] ?? res['message'];
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _ownerPhone = 'N/A';
        });
      }
    }
  }

  Future<void> _pickImage(String label) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        setState(() {
          _uploadedImages[label] = image.path;
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }
  
  final Map<String, bool> _amenities = {
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
  };

  final List<String> _statesList = IndiaLocationData.states;
  final Map<String, List<String>> _stateCities = IndiaLocationData.stateCities;
  final Map<String, List<String>> _cityRoads = IndiaLocationData.cityRoads;

  Widget _buildTextField(String hintText, {bool enabled = true, String? suffixText, VoidCallback? onSuffixTap, TextEditingController? controller, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            if (suffixText != null)
              GestureDetector(
                onTap: onSuffixTap,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    suffixText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildAutocomplete(
    String hintText, 
    List<String> options, {
    Function(String)? onSelectedValue, 
    Function(String)? onChangedValue,
    String? initialText,
    Key? key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Autocomplete<String>(
          initialValue: initialText != null && initialText.isNotEmpty ? TextEditingValue(text: initialText) : null,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) {
              return options.take(50);
            }
            final startsWith = options.where((String opt) => opt.toLowerCase().startsWith(query)).toList();
            final contains = options.where((String opt) => !opt.toLowerCase().startsWith(query) && opt.toLowerCase().contains(query)).toList();
            return [...startsWith, ...contains];
          },
          onSelected: (String selection) {
            if (onSelectedValue != null) {
              onSelectedValue(selection);
            }
          },
          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
              FocusNode focusNode, VoidCallback onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (val) {
                if (onChangedValue != null) {
                  onChangedValue(val);
                }
              },
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.search, color: Colors.black54),
              ),
            );
          },
          optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6.0,
                color: Colors.white,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 240.0,
                    maxWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option, 
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageUpload(String label) {
    bool hasImage = _uploadedImages.containsKey(label);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _pickImage(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: hasImage ? Colors.green.shade300 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: hasImage ? Colors.green.shade50 : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: hasImage ? Colors.green : Colors.grey.shade400, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  hasImage ? Icons.check : Icons.add, 
                  size: 20, 
                  color: hasImage ? Colors.green : Colors.black54
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleImageUpload(String label1, String label2) {
    bool hasImage1 = _uploadedImages.containsKey(label1);
    bool hasImage2 = _uploadedImages.containsKey(label2);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Your Aadhar Card', style: TextStyle(color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () => _pickImage(label1),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: hasImage1 ? Colors.green : Colors.grey.shade400, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(4),
                          color: hasImage1 ? Colors.green.shade50 : Colors.transparent,
                        ),
                        child: Icon(
                          hasImage1 ? Icons.check : Icons.add, 
                          size: 24, 
                          color: hasImage1 ? Colors.green : Colors.black54
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label1, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _pickImage(label2),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: hasImage2 ? Colors.green : Colors.grey.shade400, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(4),
                          color: hasImage2 ? Colors.green.shade50 : Colors.transparent,
                        ),
                        child: Icon(
                          hasImage2 ? Icons.check : Icons.add, 
                          size: 24, 
                          color: hasImage2 ? Colors.green : Colors.black54
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label2, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            Switch(
              value: _freeBreakfast,
              activeTrackColor: Colors.blue.shade100,
              activeThumbColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _freeBreakfast = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0, top: 8.0),
          child: Text('Bank Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        _buildTextField('Enter Bank Name', controller: _bankNameController),
        _buildTextField('Enter Account Number', controller: _accountNumberController),
        _buildTextField('Enter IFSC Code', controller: _ifscController),
      ],
    );
  }

  Widget _buildParkingPriceGrid() {
    List<String> wheels = [
      '4 Wheel', '6 Wheel', '8 Wheel', '10 Wheel', 
      '12 Wheel', '14 Wheel', '16 Wheel', '18 Wheel', 
      '22 Wheel', '22+ Wheel'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Text('Enter Parking Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: wheels.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                Text(wheels[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Original Price',
                      hintStyle: const TextStyle(fontSize: 10, color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Discount Price',
                      hintStyle: const TextStyle(fontSize: 10, color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        title: const Text('Registration', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Profile Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter Details To Complete Your Profile',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              
              _buildImageUpload('Upload Your Hotel Image'),
              _buildTextField('Enter Hotel Name', controller: _hotelNameController),
              _buildTextField('Enter Owner Name', controller: _ownerNameController),
              _buildTextField(_ownerPhone, enabled: false), // Disabled phone number
              _buildTextField('Enter Email ID', controller: _emailController),
              
              _buildTextField(
                _address.isEmpty ? 'Address' : _address, 
                suffixText: 'MAP',
                onSuffixTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddressMapScreen()),
                  );
                  if (result != null && result is Map) {
                    setState(() {
                      _address = result['address'] ?? '';
                      _latitude = result['lat'] ?? 28.6139;
                      _longitude = result['lng'] ?? 77.2090;
                    });
                  }
                }
              ),
              
              _buildAutocomplete(
                'State', 
                _statesList,
                initialText: _selectedState,
                key: ValueKey('state_$_selectedState'),
                onSelectedValue: (val) {
                  setState(() {
                    _selectedState = val;
                    if (_selectedCity != null && 
                        !IndiaLocationData.getCities(state: val).map((c) => c.toLowerCase()).contains(_selectedCity!.toLowerCase())) {
                      _selectedCity = null;
                    }
                  });
                },
                onChangedValue: (val) {
                  _selectedState = val.trim();
                },
              ),
              _buildAutocomplete(
                'City', 
                (_selectedState != null && _selectedState!.isNotEmpty)
                    ? (_stateCities[_selectedState] ?? IndiaLocationData.getCities(state: _selectedState))
                    : IndiaLocationData.allCities,
                initialText: _selectedCity,
                key: ValueKey('city_${_selectedState}_$_selectedCity'),
                onSelectedValue: (val) {
                  setState(() {
                    _selectedCity = val;
                    if (_selectedState == null || _selectedState!.isEmpty) {
                      final inferredState = IndiaLocationData.getStateForCity(val);
                      if (inferredState != null) {
                        _selectedState = inferredState;
                      }
                    }
                  });
                },
                onChangedValue: (val) {
                  _selectedCity = val.trim();
                },
              ),
              _buildAutocomplete(
                'Select Road', 
                (_selectedCity != null && _cityRoads.containsKey(_selectedCity))
                    ? [..._cityRoads[_selectedCity]!, ...IndiaLocationData.majorHighwaysAndRoads]
                    : IndiaLocationData.getRoads(city: _selectedCity),
                initialText: _selectedRoad,
                key: ValueKey('road_${_selectedCity}_$_selectedRoad'),
                onSelectedValue: (val) {
                  setState(() {
                    _selectedRoad = val;
                  });
                },
                onChangedValue: (val) {
                  _selectedRoad = val.trim();
                },
              ),
              _buildTextField('Pincode', controller: _pincodeController),
              
              _buildImageUpload('Upload Your Business Proof'),
              _buildDoubleImageUpload('Front Side', 'Back Side'),
              
              _buildImageUpload('Upload Your Pan Card'),
              _buildImageUpload('Upload Your Fssai License'),
              
              _buildTextField('Enter Fssai Number', controller: _fssaiController),
              _buildTextField('Enter Gst No', controller: _gstController),
              
              _buildImageUpload('Upload Your Gst Image'),
              
              // NEW FIELDS BASED ON EXTENDED IMAGES
              _buildTextField('Enter Total Parking Slots', controller: _totalSlotsController, keyboardType: TextInputType.number),
              _buildTextField('Enter Price per night (Min 42.37)', controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              _buildSwitch('Free Breakfast'),
              if (_freeBreakfast) _buildTextField('Enter Breakfast Name'),
              
              const SizedBox(height: 16),
              _buildBankDetails(),
              
              const SizedBox(height: 16),
              _buildParkingPriceGrid(),
              
              const SizedBox(height: 16),
              _buildAmenities(),
              
              const SizedBox(height: 40),
              
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    void showError(String msg) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
                    }
                    
                    if (_hotelNameController.text.isEmpty) { showError('Hotel Name is required'); return; }
                    if (_ownerNameController.text.isEmpty) { showError('Owner Name is required'); return; }
                    if (_address.isEmpty) { showError('Address is required'); return; }
                    if (_fssaiController.text.isEmpty) { showError('FSSAI Number is required'); return; }
                    if (_gstController.text.isEmpty) { showError('GST Number is required'); return; }
                    if (_bankNameController.text.isEmpty) { showError('Bank Name is required'); return; }
                    if (_accountNumberController.text.isEmpty) { showError('Account Number is required'); return; }
                    if (_ifscController.text.isEmpty) { showError('IFSC Code is required'); return; }
                    
                    double enteredPrice = double.tryParse(_priceController.text) ?? 0.0;
                    if (enteredPrice < 42.37) { showError('Price cannot be less than 42.37'); return; }

                    int totalSlots = int.tryParse(_totalSlotsController.text) ?? 10;
                    if (totalSlots < 1) { showError('Total slots must be at least 1'); return; }

                    final requiredImages = [
                      'Upload Your Hotel Image', 'Upload Your Business Proof', 'Front Side', 
                      'Back Side', 'Upload Your Pan Card', 'Upload Your Fssai License', 'Upload Your Gst Image'
                    ];
                    for (String img in requiredImages) {
                      if (!_uploadedImages.containsKey(img)) {
                        showError('Please upload: $img');
                        return;
                      }
                    }

                    setState(() {
                      _isSubmitting = true;
                    });
                    try {
                      // 1. Save Owner Profile Documents
                      final finalAddress = _address.isNotEmpty
                          ? _address
                          : [
                              if (_selectedRoad != null && _selectedRoad!.isNotEmpty) _selectedRoad,
                              if (_selectedCity != null && _selectedCity!.isNotEmpty) _selectedCity,
                              if (_selectedState != null && _selectedState!.isNotEmpty) _selectedState,
                            ].join(', ');

                      final profileData = {
                        'hotel_name': _hotelNameController.text,
                        'owner_name': _ownerNameController.text,
                        'address': finalAddress,
                        'state': _selectedState ?? '',
                        'city': _selectedCity ?? '',
                        'pincode': _pincodeController.text,
                        'fssai_number': _fssaiController.text,
                        'gst_number': _gstController.text,
                        'bank_name': _bankNameController.text,
                        'account_number': _accountNumberController.text,
                        'ifsc_code': _ifscController.text,
                      };
                      
                      Map<String, File> profileFiles = {};
                      if (_uploadedImages.containsKey('Upload Your Business Proof')) profileFiles['business_proof'] = File(_uploadedImages['Upload Your Business Proof']!);
                      if (_uploadedImages.containsKey('Front Side')) profileFiles['aadhaar_front'] = File(_uploadedImages['Front Side']!);
                      if (_uploadedImages.containsKey('Back Side')) profileFiles['aadhaar_back'] = File(_uploadedImages['Back Side']!);
                      if (_uploadedImages.containsKey('Upload Your Pan Card')) profileFiles['pan_card'] = File(_uploadedImages['Upload Your Pan Card']!);
                      if (_uploadedImages.containsKey('Upload Your Fssai License')) profileFiles['fssai_license'] = File(_uploadedImages['Upload Your Fssai License']!);
                      if (_uploadedImages.containsKey('Upload Your Gst Image')) profileFiles['gst_image'] = File(_uploadedImages['Upload Your Gst Image']!);

                      await _profileService.updateProfile(data: profileData, files: profileFiles);

                      // 2. Create Hotel
                      // Map amenities names to IDs
                      final Map<String, int> amenityIds = {
                        "Free WiFi": 1, "Air Conditioning": 2, "Room Service": 3, "Swimming Pool": 4, "Free Parking": 5,
                        "Wifi": 6, "Rest Rooms": 7, "Fuel Stations": 8, "Dining Facilities": 9, "Comfortable Rooms": 10,
                        "ATM": 11, "Convenience Stores": 12, "First Aid": 13, "Fitness center": 14, "Food Outlets": 15,
                        "Showers": 16, "Laundry Services": 17, "Seating Areas": 18
                      };
                      
                      List<int> selectedAmenities = [];
                      _amenities.forEach((key, isSelected) {
                        if (isSelected && amenityIds.containsKey(key)) {
                          selectedAmenities.add(amenityIds[key]!);
                        }
                      });

                      final createdHotel = await _hotelService.addHotel(HotelModel(
                        name: _hotelNameController.text,
                        description: "Registration submitted from App",
                        city: _selectedCity ?? "Unknown City",
                        address: finalAddress,
                        latitude: _latitude,
                        longitude: _longitude,
                        pricePerNight: enteredPrice,
                        totalRooms: totalSlots,
                        amenities: selectedAmenities,
                      ));
                      
                      // Upload hotel images if any are selected
                      if (_uploadedImages.isNotEmpty) {
                          await _hotelService.uploadHotelImages(createdHotel.id!, _uploadedImages);
                      }
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration API called successfully!'), backgroundColor: Colors.green),
                        );
                        // Navigate to dashboard
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Backend Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B), // Dark button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
