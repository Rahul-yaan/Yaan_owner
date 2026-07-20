class OwnerProfileModel {
  final int id;
  final int userId;
  final String hotelName;
  final String ownerName;
  final String address;
  final String state;
  final String city;
  final String pincode;
  final String fssaiNumber;
  final String gstNumber;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  
  final String businessProof;
  final String aadhaarFront;
  final String aadhaarBack;
  final String panCard;
  final String fssaiLicense;
  final String gstImage;
  
  final bool isProfileComplete;

  OwnerProfileModel({
    required this.id,
    required this.userId,
    this.hotelName = '',
    this.ownerName = '',
    this.address = '',
    this.state = '',
    this.city = '',
    this.pincode = '',
    this.fssaiNumber = '',
    this.gstNumber = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.businessProof = '',
    this.aadhaarFront = '',
    this.aadhaarBack = '',
    this.panCard = '',
    this.fssaiLicense = '',
    this.gstImage = '',
    this.isProfileComplete = false,
  });

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    return OwnerProfileModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      hotelName: json['hotel_name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      address: json['address'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      fssaiNumber: json['fssai_number'] ?? '',
      gstNumber: json['gst_number'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      businessProof: json['business_proof'] ?? '',
      aadhaarFront: json['aadhaar_front'] ?? '',
      aadhaarBack: json['aadhaar_back'] ?? '',
      panCard: json['pan_card'] ?? '',
      fssaiLicense: json['fssai_license'] ?? '',
      gstImage: json['gst_image'] ?? '',
      isProfileComplete: json['is_profile_complete'] == 1 || json['is_profile_complete'] == true,
    );
  }
}
