import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../views/admin/dashboard_screen.dart';
import '../views/admin/assignment_screen.dart';
import '../views/admin/global_history_screen.dart';
import '../views/admin/engineers_screen.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  const SideMenu({super.key, required this.selectedIndex});

  void _navigateTo(BuildContext context, int index) {
    if (selectedIndex == index) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const DashboardScreen();
        break;
      case 1:
        nextScreen = const AssignmentScreen();
        break;
      case 2:
        nextScreen = const GlobalHistoryScreen();
        break;
      case 3:
        nextScreen = const EngineersScreen(); // Activation de la page Ingénieurs
        break;
    // case 4: nextScreen = const SettingsScreen(); // À ajouter plus tard
      default:
        nextScreen = const DashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextScreen,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo ONT
          Image.asset(
            'assets/images/logo_ont.png',
            height: 60,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 60, width: 60,
              decoration: BoxDecoration(
                  color: AppColors.redONT,
                  borderRadius: BorderRadius.circular(12)
              ),
              child: const Center(
                  child: Text("ONT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
            ),
          ),
          const SizedBox(height: 40),

          _menuItem(context, 0, Icons.dashboard_rounded, "Tableau de Bord"),
          _menuItem(context, 1, Icons.assignment_ind_rounded, "Assignation"),
          _menuItem(context, 2, Icons.history_rounded, "Historique"),
          _menuItem(context, 3, Icons.people_alt_rounded, "Ingénieurs"),
          _menuItem(context, 4, Icons.settings_rounded, "Paramètres"),

          const Spacer(),
          const Divider(indent: 20, endIndent: 20),

          _menuItem(context, 9, Icons.logout_rounded, "Déconnexion", isExit: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, int index, IconData icon, String label, {bool isExit = false}) {
    bool isSelected = selectedIndex == index;

    return ListTile(
      onTap: () {
        if (isExit) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          _navigateTo(context, index);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(
        icon,
        size: 22,
        color: isExit ? Colors.redAccent : (isSelected ? AppColors.redONT : Colors.blueGrey.shade300),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isExit ? Colors.redAccent : (isSelected ? AppColors.redONT : Colors.blueGrey.shade700),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Container(
        width: 3,
        height: 20,
        decoration: BoxDecoration(
            color: AppColors.redONT,
            borderRadius: BorderRadius.circular(10)
        ),
      )
          : null,
    );
  }
}