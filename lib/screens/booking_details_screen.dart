import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/booking_model.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _breakfastCompleted = true;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Base room price set by hotel owner (e.g. ₹ 42.37)
    double originalBase = widget.booking.pricePerNight > 0 
        ? widget.booking.pricePerNight 
        : (widget.booking.totalAmount > 0 
            ? (widget.booking.totalAmount + widget.booking.discount)
            : (widget.booking.totalPayable > 0 ? (widget.booking.totalPayable / 1.18 + widget.booking.discount) : 0.0));

    // 2. Discount / Offer from admin (e.g. ₹ 8.47 if Case 2, or 0 if Case 1)
    double discountAmount = widget.booking.discount;
    double netBase = (originalBase - discountAmount) > 0 ? (originalBase - discountAmount) : 0.0;
    if (netBase <= 0 && widget.booking.totalAmount > 0) {
      netBase = widget.booking.totalAmount;
    }

    // 3. Owner 66% Net Share (without GST): 66% of netBase (e.g. ₹ 27.96 in Case 1; ₹ 22.37 in Case 2)
    double ownerNetPayable = ((netBase * 0.66) * 100).roundToDouble() / 100.0;

    // 4. Platform Fee 34% (without GST): 34% of netBase (e.g. ₹ 14.40 in Case 1; ₹ 11.53 in Case 2)
    double platformFee = ((netBase * 0.34) * 100).roundToDouble() / 100.0;

    // 5. GST 18%: 18% of owner payout (e.g. ₹ 5.04 in Case 1; ₹ 4.03 in Case 2)
    double totalGstOnBase = ((netBase * 0.18) * 100).roundToDouble() / 100.0;
    double ownerGst = ((totalGstOnBase * 0.66) * 100).roundToDouble() / 100.0;
    if (ownerGst <= 0 && ownerNetPayable > 0) {
      ownerGst = ((ownerNetPayable * 0.18) * 100).roundToDouble() / 100.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Booking Detail', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking ID : ${widget.booking.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // User Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('User Name', style: TextStyle(color: Colors.grey)),
                      Text(widget.booking.userName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('User Contact No.', style: TextStyle(color: Colors.grey)),
                      Text(widget.booking.userPhone, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _makePhoneCall(widget.booking.userPhone),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      ),
                      child: const Text('CALL NOW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Breakfast Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Breakfast Completed', style: TextStyle(fontWeight: FontWeight.w500)),
                  Switch(
                    value: _breakfastCompleted,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      setState(() {
                        _breakfastCompleted = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Booking Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Slot', widget.booking.displaySlot),
                  const SizedBox(height: 12),
                  _buildDetailRow('Truck Type', widget.booking.truckType),
                  const SizedBox(height: 12),
                  _buildDetailRow('Truck No', widget.booking.truckNo),
                  const SizedBox(height: 12),
                  _buildDetailRow('Logistics Name', widget.booking.logisticsName),
                  const SizedBox(height: 12),
                  _buildDetailRow('Logistics Number', widget.booking.logisticsNumber),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payment Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  // Total Amount (Room Base Price)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.grey)),
                      Row(
                        children: [
                          if (widget.booking.discount > 0) ...[
                            Text('₹ ${originalBase.toStringAsFixed(2)}', 
                              style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('₹ ${netBase.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ] else
                            Text('₹ ${originalBase.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  if (widget.booking.discount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Promotion Applied', style: TextStyle(color: Colors.grey)),
                        Text('₹ ${widget.booking.discount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fees ( 34 % )', style: TextStyle(color: Colors.grey)),
                      Text('₹ ${platformFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST ( 18 % )', style: TextStyle(color: Colors.grey)),
                      Text('₹ ${ownerGst.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Payable Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹ ${ownerNetPayable.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B), // Dark button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
