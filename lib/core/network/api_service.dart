import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/mock_data.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  // Helper method to make GET requests
  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed with status: ${response.statusCode}');
  }

  // Helper to make POST requests
  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed with status: ${response.statusCode}');
  }

  // --- BRANCHES ---
  Future<List<MockBranch>> getBranches() async {
    final res = await _get('/api/branches');
    if (res['success'] == true && res['data'] is List) {
      final List data = res['data'];
      return data.map((item) {
        return MockBranch(
          id: item['id'].toString(),
          name: item['branchName'] ?? 'Chi nhánh',
          address: item['address'] ?? 'Địa chỉ',
          latitude: item['latitude'] != null ? double.parse(item['latitude'].toString()) : 10.776,
          longitude: item['longitude'] != null ? double.parse(item['longitude'].toString()) : 106.698,
          openTime: '07:00',
          closeTime: '22:00',
          isOpen: item['status'] == 'Open' || item['status'] == 'Active',
          distanceKm: 0.0,
        );
      }).toList();
    }
    throw Exception('Failed to load branches from API');
  }

  // --- CATEGORIES ---
  Future<List<MockCategory>> getCategories() async {
    final res = await _get('/api/categories');
    if (res['success'] == true && res['data'] is List) {
      final List data = res['data'];
      return data.map((item) {
        return MockCategory(
          id: item['id'].toString(),
          name: item['name'] ?? 'Danh mục',
          icon: _getCategoryIcon(item['name']),
        );
      }).toList();
    }
    throw Exception('Failed to load categories from API');
  }

  // --- PRODUCTS / MENU ITEMS ---
  Future<List<MockProduct>> getProducts() async {
    final res = await _get('/api/menu-items');
    if (res['success'] == true && res['data'] is List) {
      final List data = res['data'];
      return data.map((item) {
        return MockProduct(
          id: item['id'].toString(),
          name: item['name'] ?? 'Món ăn',
          description: item['description'] ?? 'Mô tả món ăn',
          categoryId: item['categoryId']?.toString() ?? '1',
          basePrice: item['basePrice'] != null ? double.parse(item['basePrice'].toString()) : 35000.0,
          imageUrl: item['imageUrl'] ?? 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300&auto=format&fit=crop',
          isAvailable: item['status'] == 'Available' || item['status'] == 'Active',
          sizes: ['S', 'M', 'L'], // default sizes
          toppings: [], // loaded on demand
        );
      }).toList();
    }
    throw Exception('Failed to load products from API');
  }

  // --- TOPPINGS & CUSTOMIZATIONS BY MENU ITEM ---
  Future<Map<String, dynamic>> getCustomizationsForProduct(String productId) async {
    final intId = int.tryParse(productId);
    if (intId == null) throw Exception('Invalid product id');

    final resGroups = await _get('/api/customization-groups/menu-item/$intId');
    if (resGroups['success'] == true && resGroups['data'] is List) {
      final List groupsData = resGroups['data'];
      List<String> sizes = [];
      List<MockTopping> toppings = [];

      for (var group in groupsData) {
        final int groupId = group['id'];
        final String groupName = group['groupName'] ?? '';
        final bool isSize = groupName.toLowerCase().contains('size');

        // 2. Fetch options for this group
        final resOptions = await _get('/api/customization-options?groupId.equals=$groupId');
        if (resOptions['success'] == true && resOptions['data'] is List) {
          final List optionsData = resOptions['data'];
          for (var option in optionsData) {
            final String optionName = option['optionName'] ?? '';
            final double extraPrice = option['extraPrice'] != null 
                ? double.parse(option['extraPrice'].toString()) 
                : 0.0;

            if (isSize) {
              sizes.add(optionName);
            } else {
              toppings.add(MockTopping(
                id: option['id'].toString(),
                name: optionName,
                price: extraPrice,
                isSelected: false,
              ));
            }
          }
        }
      }

      return {
        'sizes': sizes.isNotEmpty ? sizes : ['S', 'M', 'L'],
        'toppings': toppings,
      };
    }
    throw Exception('Failed to load customizations from API');
  }

  // Helper to map category names to icons
  String _getCategoryIcon(String? name) {
    if (name == null) return 'local_cafe';
    final n = name.toLowerCase();
    if (n.contains('cà phê') || n.contains('coffee')) return 'local_cafe';
    if (n.contains('trà') || n.contains('tea')) return 'emoji_food_beverage';
    if (n.contains('bánh') || n.contains('cake') || n.contains('pastry')) return 'cake';
    if (n.contains('đá xay') || n.contains('ice blend')) return 'ac_unit';
    return 'local_cafe';
  }

  // Helper GET với JWT token
  Future<dynamic> _getAuth(String path, String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('GET $path failed: ${response.statusCode}');
  }

  // Helper POST với JWT token
  Future<dynamic> _postAuth(String path, Map<String, dynamic> body, String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.post(uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('POST $path failed: ${response.statusCode} - ${response.body}');
  }

  // Helper PUT với JWT token
  Future<dynamic> _putAuth(String path, Map<String, dynamic> body, String token) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.put(uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('PUT $path failed: ${response.statusCode}');
  }

  // --- DEV2: Lấy chi nhánh đang mở ---
  Future<List<MockBranch>> getOpenBranches() async {
    try {
      final res = await _get('/api/branches/open');
      if (res['success'] == true && res['data'] is List) {
        return (res['data'] as List).map((item) => MockBranch(
          id: item['id'].toString(),
          name: item['branchName'] ?? 'Chi nhánh',
          address: item['address'] ?? '',
          latitude: double.tryParse(item['latitude']?.toString() ?? '') ?? 10.776,
          longitude: double.tryParse(item['longitude']?.toString() ?? '') ?? 106.698,
          openTime: item['openingTime']?.toString().substring(0, 5) ?? '07:00',
          closeTime: item['closingTime']?.toString().substring(0, 5) ?? '22:00',
          isOpen: item['status'] == 'Open',
          distanceKm: 0.0,
        )).toList();
      }
    } catch (e) { print('getOpenBranches error: $e'); }
    return MockData.branches.where((b) => b.isOpen).toList();
  }

  // --- DEV2: Lấy menu theo chi nhánh ---
  Future<List<MockProduct>> getProductsByBranch(String branchId) async {
    try {
      final res = await _get('/api/menu-items/by-branch/$branchId');
      if (res['success'] == true && res['data'] is List) {
        return (res['data'] as List).map((item) => MockProduct(
          id: item['id'].toString(),
          name: item['name'] ?? '',
          description: item['description'] ?? '',
          categoryId: item['categoryId']?.toString() ?? '1',
          basePrice: double.tryParse(item['basePrice']?.toString() ?? '') ?? 35000.0,
          imageUrl: item['imageUrl'] ?? 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300',
          isAvailable: item['status'] == 'Available',
          sizes: ['S', 'M', 'L'],
          toppings: [],
        )).toList();
      }
    } catch (e) { print('getProductsByBranch error: $e'); }
    return MockData.products;
  }

  // --- DEV2: Chi tiết món + customizations (1 request) ---
  Future<MenuItemDetail?> getMenuItemDetail(String productId) async {
    try {
      final res = await _get('/api/menu-items/$productId/detail');
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        return MenuItemDetail.fromJson(data);
      }
    } catch (e) { print('getMenuItemDetail error: $e'); }
    return null;
  }

  // --- DEV3: Đặt hàng ---
  Future<PlaceOrderResponse?> placeOrder(PlaceOrderRequest request, String token) async {
    try {
      final res = await _postAuth('/api/mobile/orders/place', request.toJson(), token);
      if (res['success'] == true && res['data'] != null)
        return PlaceOrderResponse.fromJson(res['data']);
    } catch (e) { print('placeOrder error: $e'); }
    return null;
  }

  // --- DEV3: Validate coupon ---
  Future<CouponValidationResult> validateCoupon(String code, double orderTotal) async {
    try {
      final res = await _post('/api/coupons/validate', {'code': code, 'orderTotal': orderTotal});
      if (res['success'] == true && res['data'] != null)
        return CouponValidationResult.fromJson(res['data']);
    } catch (e) { print('validateCoupon error: $e'); }
    return CouponValidationResult(valid: false, discountAmount: 0, message: 'Lỗi kết nối', couponCode: code);
  }

  // --- DEV3: Xem loyalty ---
  Future<LoyaltyInfo?> getMyLoyalty(String token) async {
    try {
      final res = await _getAuth('/api/loyalty/me', token);
      if (res['success'] == true && res['data'] != null)
        return LoyaltyInfo.fromJson(res['data']);
    } catch (e) { print('getMyLoyalty error: $e'); }
    return null;
  }

  // --- DEV3: Đổi điểm ---
  Future<Map<String, dynamic>?> redeemPoints(int points, String token) async {
    try {
      final res = await _postAuth('/api/loyalty/redeem', {'points': points}, token);
      if (res['success'] == true) return res['data'];
    } catch (e) { print('redeemPoints error: $e'); }
    return null;
  }

  // --- DEV3: Trạng thái đơn (polling) ---
  Future<String> getOrderStatus(String orderId, String token) async {
    try {
      final res = await _getAuth('/api/mobile/orders/$orderId/status', token);
      if (res['success'] == true && res['data'] != null)
        return res['data']['orderStatus'] ?? 'Pending';
    } catch (e) { print('getOrderStatus error: $e'); }
    return 'Pending';
  }

  // --- Auth: Đăng nhập thật ---
  Future<String?> login(String email, String password) async {
    try {
      final res = await _post('/api/authenticate', {
        'username': email,
        'password': password,
        'rememberMe': true,
      });
      if (res != null && res['id_token'] != null) {
        return res['id_token'] as String;
      }
    } catch (e) {
      print('login error: $e');
    }
    return null;
  }

  // --- Auth: Lấy thông tin user đăng nhập ---
  Future<MockUser?> fetchUserInfo(String email, String token) async {
    try {
      final res = await _getAuth('/api/users?email.equals=$email', token);
      if (res['success'] == true && res['data'] is List && (res['data'] as List).isNotEmpty) {
        final userData = res['data'][0];
        
        int points = 0;
        String tier = 'Bronze';
        try {
          final loyaltyRes = await _getAuth('/api/loyalty/me', token);
          if (loyaltyRes['success'] == true && loyaltyRes['data'] != null) {
            points = loyaltyRes['data']['loyaltyPoints'] ?? 0;
            tier = loyaltyRes['data']['membershipTier'] ?? 'Bronze';
          }
        } catch (_) {}

        return MockUser(
          id: userData['id'].toString(),
          fullName: userData['fullName'] ?? 'Người dùng',
          email: userData['email'] ?? email,
          phone: userData['phone'] ?? '',
          role: userData['roleName'] ?? 'CUSTOMER',
          loyaltyPoints: points,
          memberTier: tier,
          token: token,
        );
      }
    } catch (e) {
      print('fetchUserInfo error: $e');
    }
    return null;
  }

  // --- Admin: Tạo món ---
  Future<bool> createMenuItem(MockProduct product, String token) async {
    try {
      final res = await _postAuth('/api/menu-items', {
        'name': product.name,
        'description': product.description,
        'basePrice': product.basePrice,
        'imageUrl': product.imageUrl,
        'status': product.isAvailable ? 'Available' : 'Unavailable',
        'categoryId': int.tryParse(product.categoryId) ?? 1,
      }, token);
      return res != null;
    } catch (e) {
      print('createMenuItem error: $e');
    }
    return false;
  }

  // --- Admin: Sửa món ---
  Future<bool> updateMenuItem(MockProduct product, String token) async {
    try {
      final res = await _putAuth('/api/menu-items', {
        'id': int.tryParse(product.id),
        'name': product.name,
        'description': product.description,
        'basePrice': product.basePrice,
        'imageUrl': product.imageUrl,
        'status': product.isAvailable ? 'Available' : 'Unavailable',
        'categoryId': int.tryParse(product.categoryId) ?? 1,
      }, token);
      return res != null;
    } catch (e) {
      print('updateMenuItem error: $e');
    }
    return false;
  }
}
