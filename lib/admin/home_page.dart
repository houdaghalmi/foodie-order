import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String user = ModalRoute.of(context)!.settings.arguments as String? ?? "Admin";
    final size = MediaQuery.of(context).size;
    // On peut utiliser une couleur légèrement différente pour l'admin (ex: Bleu Nuit ou garder le Vert)
    final adminColor = const Color(0xFF2CB14A); // Bleu gris foncé professionnel

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: adminColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: "Se déconnecter",
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête simple pour l'admin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20, top: 10),
            decoration: BoxDecoration(
              color: adminColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
              
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bienvenue, $user",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Gérez votre restaurant",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Liste des actions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Gestion des Repas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                
                // Carte: Ajouter un repas
                _buildAdminActionCard(
                  context,
                  title: "Ajouter un repas",
                  description: "Créer un nouveau plat pour le menu",
                  icon: Icons.add_circle_outline,
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/add_meals'),
                ),

                const SizedBox(height: 15),

                // Carte: Liste des repas
                _buildAdminActionCard(
                  context,
                  title: "Liste des repas",
                  description: "Modifier, supprimer ou voir le menu",
                  icon: Icons.list_alt_rounded,
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/list_meals'),
                ),

                const SizedBox(height: 25),
                
                const Text(
                  "Autres Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                
                // Exemple d'action future
                _buildAdminActionCard(
                  context,
                  title: "Statistiques (Bientôt)",
                  description: "Voir les ventes et performances",
                  icon: Icons.bar_chart_rounded,
                  color: Colors.blueGrey,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
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
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}