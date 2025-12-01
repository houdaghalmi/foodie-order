import 'package:flutter/material.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération de l'argument (nom utilisateur)
    final String user = ModalRoute.of(context)!.settings.arguments as String? ?? "Food Lover";
    final size = MediaQuery.of(context).size;
    final primaryColor = const Color(0xFF2CB14A);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // AppBar transparente car on a notre propre header
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // --- HEADER SECTION ---
          Stack(
            children: [
              ClipPath(
                clipper: DashboardHeaderClipper(),
                child: Container(
                  height: size.height * 0.35,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF1E8F33)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                           
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bonjour, $user",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8), 
                                    fontSize: 16
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Qu'allez-vous \nmanger aujourd'hui ?",
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 25, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                      ],
                    ),
                  ),
                ),
              ),
              // Image flottante décorative (optionnel)
              Positioned(
                right: -20,
                bottom: 20,
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    "assets/images/dashboard_user.png", // Assure-toi que l'image existe
                    width: 180,
                  ),
                ),
              ),
            ],
          ),

          // --- CONTENT GRID ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2, // 2 cartes par ligne
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                children: [
                  _buildDashboardCard(
                    context,
                    title: "Commander",
                    subtitle: "Nouvelle commande",
                    icon: Icons.restaurant_menu_rounded,
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.pushNamed(context, '/add_order', arguments: user),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Mes Commandes",
                    subtitle: "Historique & Suivi",
                    icon: Icons.receipt_long_rounded,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.pushNamed(context, '/list_orders', arguments: user),
                  ),
                  // Tu peux ajouter d'autres cartes ici (Profil, Favoris, etc.)
                  _buildDashboardCard(
                    context,
                    title: "Mon Profil",
                    subtitle: "Infos personnelles",
                    icon: Icons.person_rounded,
                    color: Colors.purpleAccent,
                    onTap: () {}, // À implémenter
                  ),
                   _buildDashboardCard(
                    context,
                    title: "Support",
                    subtitle: "Aide en ligne",
                    icon: Icons.headset_mic_rounded,
                    color: Colors.teal,
                    onTap: () {}, // À implémenter
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Clipper pour la courbe légère
class DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}