import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/listings_provider.dart';
import '../../models/listing_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListingsProvider>(context, listen: false).loadListings();
      Provider.of<ListingEngagementProvider>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: Consumer2<ListingsProvider, ListingEngagementProvider>(
        builder: (context, listingsProvider, engagement, child) {
          if (listingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = listingsProvider.listings
              .where((l) => engagement.isFavorite(l.listingId))
              .toList();

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Aucun favori pour le moment', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await listingsProvider.loadListings();
              await engagement.load();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (context, index) => _FavoriteCard(listing: favorites[index]),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Listing listing;
  const _FavoriteCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed('/listing-detail', arguments: listing),
        title: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${listing.subject} · ${listing.tutorName ?? 'Tuteur'}'),
        trailing: Consumer<ListingEngagementProvider>(
          builder: (context, engagement, _) => IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pink),
            onPressed: () => engagement.toggleFavorite(listing.listingId),
          ),
        ),
      ),
    );
  }
}
