class BookingModel {
  final int id;
  final int hotelId;
  final int userId;
  final String status;
  final String checkIn;
  final String checkOut;
  final double totalAmount;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? hotel;
  final String slot;
  final String truckType;
  final String truckNo;
  final String logisticsName;
  final String logisticsNumber;
  final double discount;
  final double gst;
  final String bookingDate;
  final String createdAt;
  final String paymentStatus;

  BookingModel({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    this.user,
    this.hotel,
    this.slot = '',
    this.truckType = '',
    this.truckNo = '',
    this.logisticsName = '',
    this.logisticsNumber = '',
    this.discount = 0.0,
    this.gst = 0.0,
    this.bookingDate = '',
    this.createdAt = '',
    this.paymentStatus = 'pending',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? 'pending',
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      user: json['user'],
      hotel: json['hotel'],
      slot: json['slot'] ?? json['booking_date'] ?? json['check_in'] ?? 'N/A', // Replaced hardcoded '17 April, 2024' with actual dates
      truckType: json['truck_type'] ?? '4 Wheel',
      truckNo: json['truck_no'] ?? 'GJ05HV5555',
      logisticsName: json['logistics_name'] ?? 'VRL Logistics',
      logisticsNumber: json['logistics_number'] ?? '98999 89999',
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      gst: double.tryParse(json['gst']?.toString() ?? '0') ?? 0.0,
      bookingDate: json['booking_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
    );
  }

  // Helper getters based on UI
  String get userName => user?['name'] ?? 'Unknown';
  String get userPhone => user?['phone'] ?? '';
  String get hotelName => hotel?['name'] ?? '';
}
