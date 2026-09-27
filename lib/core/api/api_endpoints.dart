class ApiEndpoints {
  // Replace this with your actual Laravel backend base URL.
  // For local Android emulator, usually http://10.0.2.2:8000/api
  // For local iOS simulator, usually http://127.0.0.1:8000/api
  // For a live server, use the https domain.
  static const String baseUrl = 'https://yaan-backend.onrender.com/api';
  
  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  
  // Hotel endpoints
  static const String hotels = '/owner/hotels';
  static const String hotelQrCode = '/owner/qr-code';
  static const String ownerBookings = '/owner/bookings';
}
