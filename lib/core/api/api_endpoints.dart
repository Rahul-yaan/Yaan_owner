class ApiEndpoints {
  // Replace this with your actual Laravel backend base URL.
  // For local Android emulator, usually http://10.0.2.2:8000/api
  // For local iOS simulator, usually http://127.0.0.1:8000/api
  // For a live server, use the https domain.
  static const String baseUrl = 'http://192.168.1.74:8000/api';
  
  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  
  // Hotel endpoints
  static const String hotels = '/owner/hotels';
}
