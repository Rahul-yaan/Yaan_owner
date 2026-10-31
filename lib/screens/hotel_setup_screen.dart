import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/hotel_service.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../core/models/hotel_model.dart';
import '../core/utils/india_locations.dart';
import '../widgets/yaan_ui.dart';
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
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(text: '42.37');
  final TextEditingController _totalSlotsController = TextEditingController(text: '10');

  // Only keep typed text while moving between steps (these values were never sent, same as before)
  final TextEditingController _breakfastNameController = TextEditingController();
  final Map<String, TextEditingController> _parkingOriginal = {};
  final Map<String, TextEditingController> _parkingDiscount = {};

  // 5-step layout
  int _step = 0;
  final ScrollController _scroll = ScrollController();
  static const List<String> _stepNames = [
    'Hotel & owner',
    'Location',
    'KYC documents',
    'Pricing & amenities',
    'Bank & submit',
  ];

  static const List<String> _wheels = [
    '4 Wheel', '6 Wheel', '8 Wheel', '10 Wheel',
    '12 Wheel', '14 Wheel', '16 Wheel', '18 Wheel',
    '22 Wheel', '22+ Wheel'
  ];

  @override
  void initState() {
    super.initState();
    for (final w in _wheels) {
      _parkingOriginal[w] = TextEditingController();
      _parkingDiscount[w] = TextEditingController();
    }
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
    _aadhaarController.dispose();
    _panController.dispose();
    _priceController.dispose();
    _totalSlotsController.dispose();
    _breakfastNameController.dispose();
    for (final c in _parkingOriginal.values) {
      c.dispose();
    }
    for (final c in _parkingDiscount.values) {
      c.dispose();
    }
    _scroll.dispose();
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

  Future<void> _openMap() async {
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ---------------------------------------------------------------------------
  // Step checks: the same rules and messages as the final submit, shown earlier
  // ---------------------------------------------------------------------------
  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (!_uploadedImages.containsKey('Upload Your Hotel Image')) { _showError('Please upload: Upload Your Hotel Image'); return false; }
        if (_hotelNameController.text.isEmpty) { _showError('Hotel Name is required'); return false; }
        if (_ownerNameController.text.isEmpty) { _showError('Owner Name is required'); return false; }
        return true;
      case 1:
        if (_address.isEmpty) { _showError('Address is required'); return false; }
        return true;
      case 2:
        for (final img in ['Upload Your Business Proof', 'Front Side', 'Back Side']) {
          if (!_uploadedImages.containsKey(img)) { _showError('Please upload: $img'); return false; }
        }
        final aadhaarNumber = _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
        if (!RegExp(r'^[2-9]\d{11}$').hasMatch(aadhaarNumber)) { _showError('Enter a valid 12-digit Aadhaar number'); return false; }
        if (!_uploadedImages.containsKey('Upload Your Pan Card')) { _showError('Please upload: Upload Your Pan Card'); return false; }
        final panNumber = _panController.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
        if (!RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(panNumber)) { _showError('Enter a valid PAN number (e.g. ABCDE1234F)'); return false; }
        if (!_uploadedImages.containsKey('Upload Your Fssai License')) { _showError('Please upload: Upload Your Fssai License'); return false; }
        if (_fssaiController.text.isEmpty) { _showError('FSSAI Number is required'); return false; }
        if (_gstController.text.isEmpty) { _showError('GST Number is required'); return false; }
        if (!_uploadedImages.containsKey('Upload Your Gst Image')) { _showError('Please upload: Upload Your Gst Image'); return false; }
        return true;
      case 3:
        final enteredPrice = double.tryParse(_priceController.text) ?? 0.0;
        if (enteredPrice < 42.37) { _showError('Price cannot be less than 42.37'); return false; }
        final totalSlots = int.tryParse(_totalSlotsController.text) ?? 10;
        if (totalSlots < 1) { _showError('Total slots must be at least 1'); return false; }
        return true;
      default:
        return true;
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validateStep(_step)) return;
    if (_step < _stepNames.length - 1) _goToStep(_step + 1);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      _goToStep(_step - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Final submit: unchanged from the old SIGN UP button
  // ---------------------------------------------------------------------------
  Future<void> _submit() async {
    void showError(String msg) => _showError(msg);

    if (_hotelNameController.text.isEmpty) { showError('Hotel Name is required'); return; }
    if (_ownerNameController.text.isEmpty) { showError('Owner Name is required'); return; }
    if (_address.isEmpty) { showError('Address is required'); return; }

    final aadhaarNumber = _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
    final panNumber = _panController.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (!RegExp(r'^[2-9]\d{11}$').hasMatch(aadhaarNumber)) { showError('Enter a valid 12-digit Aadhaar number'); return; }
    if (!RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(panNumber)) { showError('Enter a valid PAN number (e.g. ABCDE1234F)'); return; }
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
        'aadhaar_number': aadhaarNumber,
        'pan_number': panNumber,
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
        // Shows the server's validation messages (e.g. "Aadhaar number must contain exactly 12 digits.")
        final msg = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isEmpty ? 'Registration failed. Please try again.' : msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Field widgets (new look)
  // ---------------------------------------------------------------------------
  Widget _buildTextField(
    String hintText, {
    String? label,
    bool enabled = true,
    TextEditingController? controller,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    IconData? icon,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) YaanFieldLabel(label),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: YaanColors.ink, fontSize: 15),
            decoration: yaanInputDecoration(hint: hintText, icon: icon, prefixText: prefixText, enabled: enabled),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocomplete(
    String label,
    String hintText,
    List<String> options, {
    Function(String)? onSelectedValue,
    Function(String)? onChangedValue,
    String? initialText,
    Key? key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YaanFieldLabel(label),
          Autocomplete<String>(
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
                style: const TextStyle(color: YaanColors.ink, fontSize: 15),
                onChanged: (val) {
                  if (onChangedValue != null) {
                    onChangedValue(val);
                  }
                },
                decoration: yaanInputDecoration(
                  hint: hintText,
                  suffix: const Icon(Icons.keyboard_arrow_down_rounded, color: YaanColors.muted),
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
                  borderRadius: BorderRadius.circular(14),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 240.0,
                      maxWidth: MediaQuery.of(context).size.width - 64,
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
                            style: const TextStyle(fontSize: 14, color: YaanColors.ink),
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
        ],
      ),
    );
  }

  /// Upload tile. [label] is the key the submit code uses, so it must not change.
  Widget _uploadTile(String label, {required String title, double height = 88, bool big = false}) {
    final bool hasImage = _uploadedImages.containsKey(label);
    return Semantics(
      button: true,
      label: hasImage ? '$title uploaded, tap to replace' : 'Upload $title',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pickImage(label),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hasImage ? YaanColors.greenTint : const Color(0xFFFFF8F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? const Color(0xFFBFE5CD) : const Color(0xFFE8B4AD),
              width: hasImage ? 1 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: big ? 52 : 36,
                height: big ? 52 : 36,
                decoration: BoxDecoration(
                  color: hasImage ? YaanColors.green : YaanColors.brandTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasImage ? Icons.check_rounded : (big ? Icons.photo_camera_outlined : Icons.file_upload_outlined),
                  color: hasImage ? Colors.white : YaanColors.brand,
                  size: big ? 24 : 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasImage ? '$title uploaded' : title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasImage ? YaanColors.greenText : YaanColors.ink,
                  fontSize: big ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (big || hasImage)
                Text(
                  hasImage ? 'Tap to replace' : 'Choose a photo from your gallery',
                  style: const TextStyle(color: YaanColors.muted, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docCard({required String title, required List<String> imageLabels, required List<Widget> children}) {
    final done = imageLabels.every(_uploadedImages.containsKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: YaanCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                YaanStatusChip(
                  label: done ? 'Uploaded' : 'Required',
                  fg: done ? YaanColors.greenText : YaanColors.amberText,
                  bg: done ? YaanColors.greenTint : YaanColors.amberTint,
                  dot: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.free_breakfast_outlined, color: YaanColors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(
            value: _freeBreakfast,
            activeTrackColor: YaanColors.green,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            onChanged: (value) {
              setState(() {
                _freeBreakfast = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParkingPriceGrid() {
    InputDecoration small(String hint) => yaanInputDecoration(hint: hint).copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        );

    return YaanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Parking amount by truck type', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text("Leave blank for truck types you don't allow.", style: TextStyle(color: YaanColors.muted, fontSize: 12)),
          const SizedBox(height: 12),
          const Row(
            children: [
              SizedBox(width: 86, child: Text('TRUCK', style: TextStyle(color: YaanColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4))),
              Expanded(child: Text('ORIGINAL ₹', style: TextStyle(color: YaanColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4))),
              SizedBox(width: 8),
              Expanded(child: Text('DISCOUNT ₹', style: TextStyle(color: YaanColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4))),
            ],
          ),
          const SizedBox(height: 8),
          for (final w in _wheels)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(w, style: const TextStyle(color: YaanColors.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _parkingOriginal[w],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 14),
                      decoration: small('Original Price'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _parkingDiscount[w],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 14, color: YaanColors.green, fontWeight: FontWeight.w600),
                      decoration: small('Discount Price'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    final selected = _amenities.values.where((v) => v).length;
    return YaanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Amenities', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600))),
              Text('$selected selected', style: const TextStyle(color: YaanColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amenities.keys.map((key) {
              final on = _amenities[key] ?? false;
              return FilterChip(
                label: Text(key),
                selected: on,
                showCheckmark: true,
                checkmarkColor: YaanColors.brand,
                labelStyle: TextStyle(
                  color: on ? YaanColors.brand : YaanColors.ink,
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                selectedColor: YaanColors.brandTint,
                side: BorderSide(color: on ? YaanColors.brand : YaanColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                onSelected: (bool value) {
                  setState(() {
                    _amenities[key] = value;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Steps
  // ---------------------------------------------------------------------------
  Widget _stepIntro(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: YaanColors.ink, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: YaanColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget? _rejectionBanner() {
    final status = (_kycStatus ?? '').toLowerCase();
    if (!status.contains('reject')) return null;
    final reason = (_rejectionReason ?? _kycMessage ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YaanColors.redTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8C9C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: YaanColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin rejected your application', style: TextStyle(color: YaanColors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Reason: $reason', style: const TextStyle(color: Color(0xFF7A1B12), fontSize: 12, height: 1.4)),
                ],
                const SizedBox(height: 2),
                const Text('Fix the details below and submit again.', style: TextStyle(color: Color(0xFF7A1B12), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepHotel() {
    final banner = _rejectionBanner();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?banner,
        _stepIntro('Tell us about your hotel', 'Drivers see this on your hotel page in the Yaan app.'),
        _uploadTile('Upload Your Hotel Image', title: 'Upload your hotel image', height: 170, big: true),
        const SizedBox(height: 14),
        YaanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Enter Hotel Name', label: 'Hotel name', controller: _hotelNameController, textCapitalization: TextCapitalization.words),
              _buildTextField('Enter Owner Name', label: 'Owner name', controller: _ownerNameController, textCapitalization: TextCapitalization.words),
              _buildTextField(_ownerPhone, label: 'Mobile number', enabled: false, icon: Icons.lock_outline_rounded),
              _buildTextField('Enter Email ID', label: 'Email ID', controller: _emailController, keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepLocation() {
    final hasAddress = _address.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro('Where is your hotel?', 'Drivers find you by your highway and city.'),
        YaanCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7ECF1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 44,
                  color: hasAddress ? YaanColors.brand : const Color(0xFF9AA4B1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ADDRESS', style: TextStyle(color: YaanColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            hasAddress ? _address : 'No location picked yet',
                            style: TextStyle(
                              color: hasAddress ? YaanColors.ink : YaanColors.muted,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: _openMap,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: Text(hasAddress ? 'Change on map' : 'Pick on map'),
                      style: TextButton.styleFrom(
                        foregroundColor: YaanColors.brand,
                        backgroundColor: YaanColors.brandTint,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        YaanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAutocomplete(
                'State',
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
                'Road / highway',
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
              _buildTextField('Pincode', label: 'Pincode', controller: _pincodeController, keyboardType: TextInputType.number),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepDocuments() {
    const docLabels = [
      'Upload Your Business Proof', 'Front Side', 'Back Side',
      'Upload Your Pan Card', 'Upload Your Fssai License', 'Upload Your Gst Image',
    ];
    final uploaded = docLabels.where(_uploadedImages.containsKey).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _stepIntro('Upload your documents', 'The admin checks these before approving your hotel.')),
            YaanStatusChip(
              label: '$uploaded of ${docLabels.length} uploaded',
              fg: uploaded == docLabels.length ? YaanColors.greenText : YaanColors.amberText,
              bg: uploaded == docLabels.length ? YaanColors.greenTint : YaanColors.amberTint,
              dot: false,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: YaanColors.blueTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC7D7EE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.photo_camera_outlined, color: YaanColors.blueText, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Take photos in good light, flat on a table, with all 4 corners showing. Blurry photos are the most common reason for rejection.',
                  style: TextStyle(color: YaanColors.blueText, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        _docCard(
          title: 'Business proof',
          imageLabels: const ['Upload Your Business Proof'],
          children: [_uploadTile('Upload Your Business Proof', title: 'Upload business proof')],
        ),
        _docCard(
          title: 'Aadhaar card',
          imageLabels: const ['Front Side', 'Back Side'],
          children: [
            Row(
              children: [
                Expanded(child: _uploadTile('Front Side', title: 'Front side', height: 96)),
                const SizedBox(width: 10),
                Expanded(child: _uploadTile('Back Side', title: 'Back side', height: 96)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField('Enter Aadhaar Number (12 digits)', label: 'Aadhaar number (12 digits)', controller: _aadhaarController, keyboardType: TextInputType.number),
          ],
        ),
        _docCard(
          title: 'PAN card',
          imageLabels: const ['Upload Your Pan Card'],
          children: [
            _uploadTile('Upload Your Pan Card', title: 'Upload PAN card'),
            const SizedBox(height: 12),
            _buildTextField('Enter PAN Number (e.g. ABCDE1234F)', label: 'PAN number', controller: _panController, textCapitalization: TextCapitalization.characters),
          ],
        ),
        _docCard(
          title: 'FSSAI licence',
          imageLabels: const ['Upload Your Fssai License'],
          children: [
            _uploadTile('Upload Your Fssai License', title: 'Upload FSSAI licence'),
            const SizedBox(height: 12),
            _buildTextField('Enter Fssai Number', label: 'FSSAI number', controller: _fssaiController),
          ],
        ),
        _docCard(
          title: 'GST certificate',
          imageLabels: const ['Upload Your Gst Image'],
          children: [
            _buildTextField('Enter Gst No', label: 'GST number', controller: _gstController, textCapitalization: TextCapitalization.characters),
            _uploadTile('Upload Your Gst Image', title: 'Upload GST certificate'),
          ],
        ),
      ],
    );
  }

  Widget _stepPricing() {
    void changeSlots(int delta) {
      final current = int.tryParse(_totalSlotsController.text) ?? 10;
      final next = (current + delta) < 1 ? 1 : current + delta;
      setState(() => _totalSlotsController.text = '$next');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro('Set your prices', 'Room price, parking slots and what your hotel offers.'),
        YaanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total parking slots', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('How many trucks can park', style: TextStyle(color: YaanColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(color: YaanColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _slotButton(Icons.remove, 'Fewer slots', () => changeSlots(-1), filled: false),
                        SizedBox(
                          width: 48,
                          child: TextField(
                            controller: _totalSlotsController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: YaanColors.ink, fontSize: 17, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                        _slotButton(Icons.add, 'More slots', () => changeSlots(1), filled: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Enter Price per night (Min 42.37)',
                label: 'Room price per night',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: '₹ ',
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Minimum ₹42.37', style: TextStyle(color: YaanColors.muted, fontSize: 11)),
              ),
              _buildSwitch('Free Breakfast'),
              if (_freeBreakfast) ...[
                const SizedBox(height: 12),
                _buildTextField('Enter Breakfast Name', label: 'Breakfast name', controller: _breakfastNameController),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildParkingPriceGrid(),
        const SizedBox(height: 14),
        _buildAmenities(),
      ],
    );
  }

  Widget _slotButton(IconData icon, String tooltip, VoidCallback onTap, {required bool filled}) {
    return Material(
      color: filled ? YaanColors.brand : YaanColors.ground,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: filled ? Colors.white : YaanColors.ink, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _stepBank() {
    Widget reviewRow(String title, String detail, int step) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: YaanColors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: YaanColors.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: YaanColors.muted, fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _goToStep(step),
              style: TextButton.styleFrom(foregroundColor: YaanColors.brand),
              child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final location = [
      if (_selectedRoad != null && _selectedRoad!.isNotEmpty) _selectedRoad,
      if (_selectedCity != null && _selectedCity!.isNotEmpty) _selectedCity,
      if (_selectedState != null && _selectedState!.isNotEmpty) _selectedState,
    ].join(', ');
    final amenityCount = _amenities.values.where((v) => v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro('Where should we send your payouts?', 'Your share of each booking is paid to this account.'),
        YaanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Enter Bank Name', label: 'Bank name', controller: _bankNameController, textCapitalization: TextCapitalization.words),
              _buildTextField('Enter Account Number', label: 'Account number', controller: _accountNumberController, keyboardType: TextInputType.number),
              _buildTextField('Enter IFSC Code', label: 'IFSC code', controller: _ifscController, textCapitalization: TextCapitalization.characters),
            ],
          ),
        ),
        const SizedBox(height: 14),
        YaanCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('Check before you submit', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              reviewRow('Hotel & owner', '${_hotelNameController.text} · ${_ownerNameController.text}', 0),
              reviewRow('Location', location.isNotEmpty ? location : _address, 1),
              reviewRow('KYC documents', 'Aadhaar, PAN, FSSAI, GST', 2),
              reviewRow('Pricing & amenities', '₹${_priceController.text}/night · ${_totalSlotsController.text} slots · $amenityCount amenities', 3),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your hotel will go live on Yaan after the admin approves it.',
          style: TextStyle(color: YaanColors.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Page
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isLast = _step == _stepNames.length - 1;
    final steps = [_stepHotel, _stepLocation, _stepDocuments, _stepPricing, _stepBank];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: YaanColors.ground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: YaanColors.ink,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          titleSpacing: 16,
          shape: const Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
          title: Row(
            children: [
              YaanBackButton(onTap: _back),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hotel registration', style: TextStyle(color: YaanColors.ink, fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(
                      'Step ${_step + 1} of ${_stepNames.length} · ${_stepNames[_step]}',
                      style: const TextStyle(color: YaanColors.muted, fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: YaanStepProgress(current: _step + 1, total: _stepNames.length),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: steps[_step](),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(child: YaanOutlineButton(text: 'Back', onPressed: _isSubmitting ? null : _back, height: 54)),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: YaanPrimaryButton(
                      text: isLast ? 'Submit for approval' : 'Continue',
                      icon: isLast ? Icons.send_rounded : Icons.arrow_forward_rounded,
                      loading: _isSubmitting,
                      onPressed: isLast ? _submit : _next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
