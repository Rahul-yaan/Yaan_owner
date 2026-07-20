import 'package:flutter/foundation.dart';
import '../core/models/hotel_model.dart';
import '../services/hotel_service.dart';

class HotelProvider with ChangeNotifier {
  final HotelService _hotelService = HotelService();

  List<HotelModel> _hotels = [];
  List<HotelModel> get hotels => _hotels;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHotels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hotels = await _hotelService.getHotels();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHotel(HotelModel hotel) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newHotel = await _hotelService.addHotel(hotel);
      _hotels.add(newHotel);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
