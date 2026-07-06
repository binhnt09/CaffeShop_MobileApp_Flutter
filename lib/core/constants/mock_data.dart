import 'package:uuid/uuid.dart';

class MockUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role; // CUSTOMER, CASHIER, BARISTA, MANAGER, ADMIN
  final int loyaltyPoints;
  final String memberTier; // BRONZE, SILVER, GOLD, PLATINUM
  final String? branchId; // For staff/manager

  MockUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.loyaltyPoints = 0,
    this.memberTier = 'BRONZE',
    this.branchId,
  });
}

class MockBranch {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final double distanceKm; // Calculated/mocked dynamically

  MockBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    required this.distanceKm,
  });
}

class MockCategory {
  final String id;
  final String name;
  final String icon;

  MockCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class MockTopping {
  final String id;
  final String name;
  final double price;
  bool isSelected;

  MockTopping({
    required this.id,
    required this.name,
    required this.price,
    this.isSelected = false,
  });

  MockTopping copy() {
    return MockTopping(id: id, name: name, price: price, isSelected: isSelected);
  }
}

class MockProduct {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double basePrice;
  final String imageUrl;
  final bool isAvailable;
  final List<String> sizes; // S, M, L
  final List<MockTopping> toppings;

  MockProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.basePrice,
    required this.imageUrl,
    required this.isAvailable,
    required this.sizes,
    required this.toppings,
  });
}

class MockCartItem {
  final String id;
  final MockProduct product;
  String size;
  int sugarLevel; // 0, 30, 50, 70, 100
  int iceLevel; // 0, 50, 100 (Không đá, Ít đá, Bình thường)
  List<MockTopping> selectedToppings;
  int quantity;

  MockCartItem({
    required this.id,
    required this.product,
    this.size = 'M',
    this.sugarLevel = 100,
    this.iceLevel = 100,
    required this.selectedToppings,
    this.quantity = 1,
  });

  double get unitPrice {
    double price = product.basePrice;
    if (size == 'S') price -= 5000;
    if (size == 'L') price += 10000;
    for (var topping in selectedToppings) {
      price += topping.price;
    }
    return price;
  }

  double get totalPrice => unitPrice * quantity;
}

class MockOrder {
  final String id;
  final String orderCode;
  final String branchName;
  final List<MockCartItem> items;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod; // CASH, MOMO, VNPAY
  final String status; // PENDING, CONFIRMED, BREWING, READY, COMPLETED, CANCELLED
  final DateTime createdAt;
  final String source; // MOBILE_APP, POS

  MockOrder({
    required this.id,
    required this.orderCode,
    required this.branchName,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.source,
  });
}

class MockCoupon {
  final String code;
  final String description;
  final String discountType; // PERCENT, FIXED
  final double discountValue;
  final double minOrder;

  MockCoupon({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
  });
}

class MockInventoryItem {
  final String id;
  final String name;
  final String unit;
  double currentStock;
  final double lowStockThreshold;

  MockInventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.lowStockThreshold,
  });

  double get percentage => (currentStock / (lowStockThreshold * 3)).clamp(0.0, 1.0);
}

class MockData {
  // Pre-configured users
  static final List<MockUser> users = [
    MockUser(
      id: 'usr_cust',
      fullName: 'Nguyễn Văn Khách',
      email: 'customer@coffee.com',
      phone: '0912345678',
      role: 'CUSTOMER',
      loyaltyPoints: 320,
      memberTier: 'GOLD',
    ),
    MockUser(
      id: 'usr_cash',
      fullName: 'Trần Thị Thu Ngân',
      email: 'cashier@coffee.com',
      phone: '0987654321',
      role: 'CASHIER',
      branchId: 'br_hbt',
    ),
    MockUser(
      id: 'usr_bar',
      fullName: 'Phạm Văn Pha Chế',
      email: 'barista@coffee.com',
      phone: '0901234567',
      role: 'BARISTA',
      branchId: 'br_hbt',
    ),
    MockUser(
      id: 'usr_mgr',
      fullName: 'Lê Hoàng Quản Lý',
      email: 'manager@coffee.com',
      phone: '0934567890',
      role: 'MANAGER',
      branchId: 'br_hbt',
    ),
    MockUser(
      id: 'usr_adm',
      fullName: 'Vũ Quốc Admin',
      email: 'admin@coffee.com',
      phone: '0977777777',
      role: 'ADMIN',
    ),
  ];

  // Pre-configured branches
  static final List<MockBranch> branches = [
    MockBranch(
      id: 'br_hbt',
      name: 'CaffeShop Hai Bà Trưng',
      address: '120 Hai Bà Trưng, Phường Đa Kao, Quận 1, TP. HCM',
      latitude: 10.7825,
      longitude: 106.6970,
      openTime: '07:00',
      closeTime: '22:30',
      isOpen: true,
      distanceKm: 0.8,
    ),
    MockBranch(
      id: 'br_ndc',
      name: 'CaffeShop Nguyễn Đình Chiểu',
      address: '25 Nguyễn Đình Chiểu, Phường Đa Kao, Quận 1, TP. HCM',
      latitude: 10.7865,
      longitude: 106.6995,
      openTime: '07:00',
      closeTime: '22:00',
      isOpen: true,
      distanceKm: 1.4,
    ),
    MockBranch(
      id: 'br_lqdon',
      name: 'CaffeShop Lê Quý Đôn',
      address: '15 Lê Quý Đôn, Phường Võ Thị Sáu, Quận 3, TP. HCM',
      latitude: 10.7788,
      longitude: 106.6925,
      openTime: '07:00',
      closeTime: '23:00',
      isOpen: true,
      distanceKm: 2.1,
    ),
    MockBranch(
      id: 'br_cmt8',
      name: 'CaffeShop Cách Mạng Tháng Tám',
      address: '380 Cách Mạng Tháng 8, Phường 10, Quận 3, TP. HCM',
      latitude: 10.7850,
      longitude: 106.6740,
      openTime: '07:30',
      closeTime: '22:00',
      isOpen: false, // Closed for maintenance / out of hours
      distanceKm: 3.5,
    ),
    MockBranch(
      id: 'br_pnp',
      name: 'CaffeShop Phan Xích Long',
      address: '198 Phan Xích Long, Phường 2, Quận Phú Nhuận, TP. HCM',
      latitude: 10.7985,
      longitude: 106.6890,
      openTime: '07:00',
      closeTime: '22:30',
      isOpen: true,
      distanceKm: 4.2,
    ),
  ];

  // Pre-configured categories
  static final List<MockCategory> categories = [
    MockCategory(id: 'cat_coffee', name: 'Cà Phê Ý / Phin', icon: '☕'),
    MockCategory(id: 'cat_tea', name: 'Trà Trái Cây / Sữa', icon: '🍵'),
    MockCategory(id: 'cat_ice', name: 'Đá Xay / Frosty', icon: '🥤'),
    MockCategory(id: 'cat_cake', name: 'Bánh Ngọt / Mặn', icon: '🍰'),
    MockCategory(id: 'cat_snack', name: 'Snack / Hạt', icon: '🍿'),
  ];

  // Pre-configured toppings
  static final List<MockTopping> toppings = [
    MockTopping(id: 'top_peach', name: 'Đào Miếng', price: 10000),
    MockTopping(id: 'top_jelly', name: 'Thạch Trà Đen', price: 8000),
    MockTopping(id: 'top_boba', name: 'Trân Châu Hoàng Kim', price: 10000),
    MockTopping(id: 'top_cheese', name: 'Macchiato Phô Mai', price: 12000),
    MockTopping(id: 'top_pudding', name: 'Pudding Trứng', price: 10000),
    MockTopping(id: 'top_cream', name: 'Kem Whipping', price: 8000),
  ];

  // Pre-configured products
  static final List<MockProduct> products = [
    // Coffee
    MockProduct(
      id: 'prod_cf_den',
      name: 'Cà Phê Đen Đá Phin',
      description: 'Cà phê rang xay đậm vị truyền thống pha phin giấy organic tinh chất đậm đà gu Việt.',
      categoryId: 'cat_coffee',
      basePrice: 29000,
      imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['S', 'M', 'L'],
      toppings: [toppings[2], toppings[3]], // Boba, Cheese
    ),
    MockProduct(
      id: 'prod_cf_sua',
      name: 'Cà Phê Sữa Đá Sài Gòn',
      description: 'Cà phê pha phin truyền thống hòa quyện cùng sữa đặc béo ngậy đầy sảng khoái.',
      categoryId: 'cat_coffee',
      basePrice: 35000,
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['S', 'M', 'L'],
      toppings: [toppings[2], toppings[3], toppings[4]], // Boba, Cheese, Pudding
    ),
    MockProduct(
      id: 'prod_cf_bacxiu',
      name: 'Bạc Xỉu Đá Caramel',
      description: 'Nhiều sữa ít cà phê, thêm lớp caramel thơm ngậy dịu ngọt nâng tầm phong cách.',
      categoryId: 'cat_coffee',
      basePrice: 39000,
      imageUrl: 'https://images.unsplash.com/photo-1570968915860-54d5c301fc9f?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['S', 'M', 'L'],
      toppings: [toppings[3], toppings[4]],
    ),
    MockProduct(
      id: 'prod_cf_latte',
      name: 'Latte Art Macchiato',
      description: 'Espresso đậm vị hòa cùng sữa tươi đánh nóng mịn màng nghệ thuật tạo hình đặc sắc.',
      categoryId: 'cat_coffee',
      basePrice: 49000,
      imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M', 'L'],
      toppings: [toppings[3]],
    ),
    MockProduct(
      id: 'prod_cf_coconut',
      name: 'Cà Phê Cốt Dừa Đá Xay',
      description: 'Cà phê phin kết hợp cốt dừa béo lạnh ngậy thơm, món ngon bestseller hè này.',
      categoryId: 'cat_coffee',
      basePrice: 49000,
      imageUrl: 'https://images.unsplash.com/photo-1594911774802-8822a707cff3?q=80&w=300&auto=format&fit=crop',
      isAvailable: false, // Out of stock at branch
      sizes: ['M', 'L'],
      toppings: [toppings[2], toppings[5]],
    ),

    // Tea
    MockProduct(
      id: 'prod_tea_peach',
      name: 'Trà Đào Cam Sả',
      description: 'Trà đen thơm ngọt mát cùng đào miếng giòn rụm kết hợp sả tươi và nước cam ép.',
      categoryId: 'cat_tea',
      basePrice: 45000,
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M', 'L'],
      toppings: [toppings[0], toppings[1]], // Peach, Jelly
    ),
    MockProduct(
      id: 'prod_tea_lotus',
      name: 'Trà Sen Vàng Hạt Sen',
      description: 'Trà Oolong thanh mát đi cùng củ năng giòn ngọt, hạt sen bùi ngậy và kem sữa.',
      categoryId: 'cat_tea',
      basePrice: 49000,
      imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M', 'L'],
      toppings: [toppings[1], toppings[3]],
    ),
    MockProduct(
      id: 'prod_tea_matcha',
      name: 'Matcha Latte Nhật Bản',
      description: 'Bột trà xanh Uji organic kết hợp sữa tươi nguyên kem dịu ngọt, bổ dưỡng.',
      categoryId: 'cat_tea',
      basePrice: 55000,
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['S', 'M', 'L'],
      toppings: [toppings[2], toppings[4]],
    ),

    // Ice blended
    MockProduct(
      id: 'prod_ice_cookie',
      name: 'Frosty Cookie Đá Xay',
      description: 'Bánh oreo xay nhuyễn cùng sữa, kem whipping béo ngậy và sốt chocolate Bỉ ngọt ngào.',
      categoryId: 'cat_ice',
      basePrice: 59000,
      imageUrl: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M', 'L'],
      toppings: [toppings[5]],
    ),
    MockProduct(
      id: 'prod_ice_mango',
      name: 'Mango Smoothie Yogurt',
      description: 'Xoài chín tươi xay mịn cùng sữa chua Hy Lạp thanh mát và sốt xoài tự làm đậm hương.',
      categoryId: 'cat_ice',
      basePrice: 59000,
      imageUrl: 'https://images.unsplash.com/photo-1553530979-7ee52a2670c2?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M', 'L'],
      toppings: [toppings[1]],
    ),

    // Cakes
    MockProduct(
      id: 'prod_cake_tira',
      name: 'Tiramisu Cacao Truyền Thống',
      description: 'Bánh phô mai Mascarpone mềm mịn, ngấm đẫm rượu Kahlúa và cà phê espresso thơm phức.',
      categoryId: 'cat_cake',
      basePrice: 39000,
      imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M'],
      toppings: [],
    ),
    MockProduct(
      id: 'prod_cake_croissant',
      name: 'Croissant Bơ Tỏi Nướng Kèm Trứng',
      description: 'Bánh sừng bò ngàn lớp thơm nức hương bơ Pháp, ăn kèm phết bơ tỏi và chà bông.',
      categoryId: 'cat_cake',
      basePrice: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M'],
      toppings: [],
    ),
    MockProduct(
      id: 'prod_cake_cheese',
      name: 'Mousse Chanh Dây Phô Mai',
      description: 'Sự kết hợp chua ngọt sảng khoái từ chanh dây tươi và cốt kem phô mai béo ngậy.',
      categoryId: 'cat_cake',
      basePrice: 42000,
      imageUrl: 'https://images.unsplash.com/photo-1524351199679-46cddf530c04?q=80&w=300&auto=format&fit=crop',
      isAvailable: true,
      sizes: ['M'],
      toppings: [],
    ),
  ];

  // Pre-configured coupons
  static final List<MockCoupon> coupons = [
    MockCoupon(code: 'COFFEE10', description: 'Giảm 10% cho toàn bộ đơn hàng', discountType: 'PERCENT', discountValue: 10, minOrder: 50000),
    MockCoupon(code: 'SAVE20K', description: 'Giảm trực tiếp 20.000đ cho đơn từ 80k', discountType: 'FIXED', discountValue: 20000, minOrder: 80000),
    MockCoupon(code: 'FREESHIP', description: 'Giảm 15.000đ phí giao hàng', discountType: 'FIXED', discountValue: 15000, minOrder: 40000),
  ];

  // Pre-configured inventory items
  static final List<MockInventoryItem> inventoryItems = [
    MockInventoryItem(id: 'inv_bean_arabica', name: 'Hạt Arabica Cầu Đất (kg)', unit: 'kg', currentStock: 45.0, lowStockThreshold: 15.0),
    MockInventoryItem(id: 'inv_bean_robusta', name: 'Hạt Robusta Buôn Ma Thuột (kg)', unit: 'kg', currentStock: 80.0, lowStockThreshold: 20.0),
    MockInventoryItem(id: 'inv_milk_condensed', name: 'Sữa Đặc Ngôi Sao Phương Nam (hộp)', unit: 'hộp', currentStock: 12.0, lowStockThreshold: 10.0), // Low stock!
    MockInventoryItem(id: 'inv_milk_fresh', name: 'Sữa Tươi Tiệt Trùng Dalat Milk (lít)', unit: 'lít', currentStock: 25.0, lowStockThreshold: 8.0),
    MockInventoryItem(id: 'inv_tea_olong', name: 'Trà Oolong Lâm Đồng (kg)', unit: 'kg', currentStock: 12.5, lowStockThreshold: 5.0),
    MockInventoryItem(id: 'inv_tea_black', name: 'Hồng Trà Đặc Sản (kg)', unit: 'kg', currentStock: 3.2, lowStockThreshold: 5.0), // Low stock!
    MockInventoryItem(id: 'inv_syrup_caramel', name: 'Syrup Caramel Monin (chai)', unit: 'chai', currentStock: 6.0, lowStockThreshold: 2.0),
    MockInventoryItem(id: 'inv_syrup_peach', name: 'Syrup Đào Teisseire (chai)', unit: 'chai', currentStock: 1.0, lowStockThreshold: 2.0), // Low stock!
    MockInventoryItem(id: 'inv_peach_slice', name: 'Đào Hộp Kronos (hộp)', unit: 'hộp', currentStock: 18.0, lowStockThreshold: 6.0),
    MockInventoryItem(id: 'inv_boba', name: 'Trân Châu Hoàng Kim sống (kg)', unit: 'kg', currentStock: 15.0, lowStockThreshold: 5.0),
    MockInventoryItem(id: 'inv_sugar_liquid', name: 'Đường Nước Đậm Đặc (lít)', unit: 'lít', currentStock: 40.0, lowStockThreshold: 10.0),
    MockInventoryItem(id: 'inv_cup_m', name: 'Ly Giấy CaffeShop Size M (cái)', unit: 'cái', currentStock: 850.0, lowStockThreshold: 300.0),
    MockInventoryItem(id: 'inv_cup_l', name: 'Ly Giấy CaffeShop Size L (cái)', unit: 'cái', currentStock: 120.0, lowStockThreshold: 200.0), // Low stock!
    MockInventoryItem(id: 'inv_straw', name: 'Ống Hút Bã Mía (cái)', unit: 'cái', currentStock: 2000.0, lowStockThreshold: 500.0),
    MockInventoryItem(id: 'inv_bag', name: 'Túi Mang Đi Tự Hủy (cái)', unit: 'cái', currentStock: 600.0, lowStockThreshold: 200.0),
  ];

  // Pre-configured mock history orders
  static final List<MockOrder> orderHistory = [
    MockOrder(
      id: 'ord_1',
      orderCode: 'CF-9821',
      branchName: 'CaffeShop Hai Bà Trưng',
      items: [
        MockCartItem(
          id: 'ci_1',
          product: products[1], // Cafe Sua Da
          size: 'L',
          sugarLevel: 70,
          iceLevel: 100,
          selectedToppings: [toppings[4]], // Pudding
          quantity: 2,
        ),
      ],
      totalAmount: 110000,
      discountAmount: 10000,
      finalAmount: 100000,
      paymentMethod: 'VNPAY',
      status: 'COMPLETED',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      source: 'MOBILE_APP',
    ),
    MockOrder(
      id: 'ord_2',
      orderCode: 'CF-9822',
      branchName: 'CaffeShop Hai Bà Trưng',
      items: [
        MockCartItem(
          id: 'ci_2',
          product: products[5], // Tra dao cam sa
          size: 'M',
          selectedToppings: [toppings[0]], // Peach slice
          quantity: 1,
        ),
        MockCartItem(
          id: 'ci_3',
          product: products[10], // Tiramisu
          selectedToppings: [],
          quantity: 1,
        ),
      ],
      totalAmount: 94000,
      discountAmount: 20000,
      finalAmount: 74000,
      paymentMethod: 'MOMO',
      status: 'COMPLETED',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      source: 'MOBILE_APP',
    ),
    MockOrder(
      id: 'ord_3',
      orderCode: 'CF-9823',
      branchName: 'CaffeShop Hai Bà Trưng',
      items: [
        MockCartItem(
          id: 'ci_4',
          product: products[3], // Latte
          size: 'M',
          selectedToppings: [],
          quantity: 1,
        ),
      ],
      totalAmount: 49000,
      discountAmount: 0,
      finalAmount: 49000,
      paymentMethod: 'CASH',
      status: 'BREWING',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      source: 'POS',
    ),
  ];
}
