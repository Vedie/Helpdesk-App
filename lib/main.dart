import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/ticket_controller.dart';
import 'controllers/auth_controller.dart';
import 'services/notification_service.dart';
import 'views/login_screen.dart';
import 'views/admin/dashboard_screen.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialisation des Notifications (FCM)
  // On ne l'active que sur mobile (iOS/Android) car la config est différente sur Web
  if (!kIsWeb) {
    await NotificationService.init();
  }

  runApp(const HelpDeskApp());
}

class HelpDeskApp extends StatelessWidget {
  const HelpDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TicketController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HelpDesk ONT',
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: AppColors.blueONT,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.blueONT,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        // Logique de démarrage : Web pour Dashboard, Mobile pour Login
        home: kIsWeb ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }
}