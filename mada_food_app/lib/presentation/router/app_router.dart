// lib/presentation/router/app_router.dart
import 'package:go_router/go_router.dart';

import '../pages/role_selection_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/client/restaurant_list_page.dart';
import '../pages/restaurateur/restaurateur_home_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/admin_restaurants_page.dart';
import '../pages/admin/admin_users_page.dart';
import '../pages/admin/admin_orders_page.dart';
import '../pages/admin/admin_order_detail_page.dart';
import '../pages/admin/create_restaurateur_page.dart';
import '../pages/admin/create_restaurant_page.dart';
import '../pages/restaurateur/ajouter_plat_page.dart';
import '../pages/restaurateur/modifier_plat_page.dart';
import '../pages/client/restaurant_detail_page.dart';
import '../pages/client/cart_page.dart';
import '../pages/client/order_history_page.dart';
import '../pages/client/profile_page.dart';
import '../pages/client/order_tracking_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const RoleSelectionPage(),
  routes: [
    // 1. Sélection du Rôle
    GoRoute(
      path: '/',
      builder: (context, state) => const RoleSelectionPage(),
    ),
    
    // 2. Login
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'CLIENT';
        return LoginPage(role: role);
      },
    ),
    
    // 3. Register
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'CLIENT';
        return RegisterPage(role: role);
      },
    ),
    
    // 4. Pages Clients
    GoRoute(
      path: '/client-home',
      builder: (context, state) => const RestaurantListPage(),
    ),
    GoRoute(
      path: '/client/restaurant/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RestaurantDetailPage(restaurantId: id);
      },
    ),
    GoRoute(
      path: '/client/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/client/orders',
      builder: (context, state) => const OrderHistoryPage(),
    ),
    GoRoute(
      path: '/client/order/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return OrderTrackingPage(orderId: id);
      },
    ),
    GoRoute(
      path: '/client/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    
    // 5. Pages Restaurateur
    GoRoute(
      path: '/restaurateur-home',
      builder: (context, state) => const RestaurateurHomePage(),
    ),
    GoRoute(
      path: '/restaurateur/plats/ajouter',
      builder: (context, state) => const AjoutPlatPage(),  // ✅ CORRIGÉ : AjoutPlatPage
    ),
    GoRoute(
      path: '/restaurateur/plats/modifier/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ModifierPlatPage(platId: id);
      },
    ),
    
   
    // 6. Pages Admin
    GoRoute(
      path: '/admin-home',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/restaurants',
      builder: (context, state) => const AdminRestaurantsPage(),
    ),
    GoRoute(
      path: '/admin/restaurants/create',
      builder: (context, state) => const CreateRestaurantPage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersPage(),
    ),
    GoRoute(
      path: '/admin/users/create-restaurateur',
      builder: (context, state) => const CreateRestaurateurPage(),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const AdminOrdersPage(),
    ),
    GoRoute(
      path: '/admin/order/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AdminOrderDetailPage(orderId: id);
      },
    ),
  ],
);