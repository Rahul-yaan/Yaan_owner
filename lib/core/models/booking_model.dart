import '../utils/date_formatter.dart';

class BookingModel {
  final int id;
  final int hotelId;
  final int userId;
  final String status;
  final String checkIn;
  final String checkOut;
  final double totalAmount;
  final double totalPayable;
  final double pricePerNight;
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
    required this.totalPayable,
    required this.pricePerNight,
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
    double pricePN = double.tryParse((json['price_per_night'] ?? json['hotel']?['price_per_night'])?.toString() ?? '0') ?? 0.0;
    double baseAmt = double.tryParse(json['total_amount']?.toString() ?? '0') ?? (pricePN > 0 ? pricePN : 0.0);
    double discAmt = double.tryParse((json['promotion_applied'] ?? json['discount_amount'] ?? json['discount'])?.toString() ?? '0') ?? 0.0;
    double discountedBase = (baseAmt - discAmt) > 0 ? (baseAmt - discAmt) : 0.0;
    double calculatedGst = double.tryParse((json['gst_amount'] ?? json['gst'])?.toString() ?? '0') ?? (discountedBase * 0.18);
    double calculatedPayable = double.tryParse(json['total_payable']?.toString() ?? '0') ?? (discountedBase + calculatedGst);

    if (calculatedPayable == 0 && baseAmt > 0) {
      calculatedPayable = baseAmt + calculatedGst;
    }

    return BookingModel(
      id: json['id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? 'pending',
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'] ?? '',
      totalAmount: baseAmt,
      totalPayable: calculatedPayable,
      pricePerNight: pricePN,
      user: json['user'],
      hotel: json['hotel'],
      slot: json['slot'] ?? json['booking_date'] ?? json['check_in'] ?? 'N/A',
      truckType: json['truck_type'] ?? '4 Wheel',
      truckNo: json['truck_no'] ?? 'N/A',
      logisticsName: json['logistics_name'] ?? 'N/A',
      logisticsNumber: json['logistics_number'] ?? 'N/A',
      discount: discAmt,
      gst: calculatedGst,
      bookingDate: json['booking_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
    );
  }

  // Helper getters based on UI
  String get userName => user?['name'] ?? 'Unknown';
  String get userPhone => user?['phone'] ?? '';
  String get hotelName => hotel?['name'] ?? '';

  String get displaySlot => DateFormatter.formatSlotDate(slot, checkIn: checkIn, checkOut: checkOut);
}
