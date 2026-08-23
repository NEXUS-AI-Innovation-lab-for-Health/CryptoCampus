import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          Consumer<MessagingProvider>(
            builder: (context, messaging, child) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Messagerie',
                  onPressed: () => Navigator.of(context).pushNamed('/messages'),
                ),
                if (messaging.unreadTotal > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${messaging.unreadTotal}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mon profil',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final isTutor = user?.isTutor ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              user?.firstName.isNotEmpty == true
                                  ? user!.firstName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Utilisateur',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    isTutor ? 'Tuteur' : 'Étudiant',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _MenuCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Mon Wallet',
                  subtitle: 'Solde CCT, bénéficiaires, code de parrainage',
                  color: Colors.purple,
                  onTap: () => Navigator.of(context).pushNamed('/balance'),
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.shopping_bag,
                  title: 'Annonces de tutorat',
                  subtitle: 'Trouver un tuteur',
                  color: Colors.blue,
                  onTap: () => Navigator.of(context).pushNamed('/shop'),
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.favorite_outline,
                  title: 'Mes favoris',
                  subtitle: 'Annonces mises de côté',
                  color: Colors.pink,
                  onTap: () => Navigator.of(context).pushNamed('/favorites'),
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.event_note,
                  title: 'Mes Réservations',
                  subtitle: 'Voir mes réservations de cours',
                  color: Colors.orange,
                  onTap: () => Navigator.of(context).pushNamed('/bookings'),
                ),
                if (isTutor) ...[
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.add_circle,
                    title: 'Créer un cours',
                    subtitle: 'Proposer un cours de tutorat',
                    color: Colors.green,
                    onTap: () => Navigator.of(context).pushNamed('/create-request'),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.list_alt,
                    title: 'Mes annonces',
                    subtitle: 'Gérer vos annonces publiées',
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).pushNamed('/my-listings'),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.schedule,
                    title: 'Mes disponibilités',
                    subtitle: 'Gérer vos créneaux de cours',
                    color: Colors.indigo,
                    onTap: () => Navigator.of(context).pushNamed('/availability'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
