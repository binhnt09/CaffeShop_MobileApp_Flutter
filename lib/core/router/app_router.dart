import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import Screens
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/customer/branch_selection/screens/branch_selection_screen.dart';
import '../../features/customer/menu/menu_screen.dart';
import '../../features/customer/cart_checkout/screens/cart_screen.dart';
import '../../features/customer/cart_checkout/screens/checkout_screen.dart';
import '../../features/customer/order_tracking/screens/order_tracking_screen.dart';
import '../../features/customer/loyalty/screens/loyalty_screen.dart';
import '../../features/customer/profile/screens/profile_screen.dart';
import '../../features/staff/pos/screens/pos_counter_screen.dart';
import '../../features/staff/pos/screens/pos_history_screen.dart';
import '../../features/staff/kds/screens/kds_kitchen_screen.dart';
import '../../features/manager/inventory/screens/inventory_screen.dart';
import '../../features/manager/dashboard/screens/manager_dashboard_screen.dart';
import '../../features/admin/menu_management/screens/global_menu_screen.dart';
import '../../features/admin/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/admin/user_management/screens/user_management_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Customer routes
      GoRoute(
        path: '/branch-select',
        builder: (context, state) => const BranchSelectionScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/track/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? 'CF-9823';
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/loyalty',
        builder: (context, state) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Staff POS routes
      GoRoute(
        path: '/pos',
        builder: (context, state) => const POSCounterScreen(),
      ),
      GoRoute(
        path: '/pos/history',
        builder: (context, state) => const POSHistoryScreen(),
      ),

      // Staff KDS route
      GoRoute(
        path: '/kds',
        builder: (context, state) => const KDSKitchenScreen(),
      ),

      // Manager routes
      GoRoute(
        path: '/manager/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/manager/dashboard',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/menu',
        builder: (context, state) => const GlobalMenuScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Không tìm thấy trang: ${state.uri}'),
      ),
    ),
  );
}
