import 'package:flutter/material.dart';
import 'package:travel_app/pages/add_place.dart';
import 'package:travel_app/pages/place_details.dart';
import 'package:travel_app/services/api_service.dart';

class Place extends StatefulWidget {
  final Map<String, dynamic> user;

  const Place({super.key, required this.user});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  List<Map<String, dynamic>> places = [];
  Map<int, bool> _likeStatus = {};
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    try {
      final fetchedPlaces = await _apiService.fetchPlaces();
      setState(() {
        places = fetchedPlaces;
      });
      for (var place in places) {
        final isLiked = await _apiService.checkLikeStatus(place['id'], widget.user['id']);
        setState(() {
          _likeStatus[place['id']] = isLiked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching places: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleLike(int placeId) async {
    try {
      await _apiService.likePlace(placeId, widget.user['id']);
      final isLiked = await _apiService.checkLikeStatus(placeId, widget.user['id']);
      setState(() {
        _likeStatus[placeId] = isLiked;
        final index = places.indexWhere((p) => p['id'] == placeId);
        if (index != -1) {
          places[index]['like_count'] = isLiked
              ? (places[index]['like_count'] ?? 0) + 1
              : (places[index]['like_count'] ?? 1) - 1;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error liking place: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deletePlace(int placeId) async {
    try {
      await _apiService.deletePlace(placeId, widget.user['id']);
      setState(() {
        places.removeWhere((p) => p['id'] == placeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting place: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showDeleteDialog(int placeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: const Text('Are you sure you want to delete this place?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deletePlace(placeId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Places',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF273671),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        actions: [
          if (widget.user['role'] == 'admin')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPlace(user: widget.user),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPlaces,
        color: const Color(0xFF273671),
        child: places.isEmpty
            ? const Center(child: Text('No places found', style: TextStyle(fontSize: 16)))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  final isLiked = _likeStatus[place['id']] ?? false;
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaceDetails(
                              place: place,
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  'http://localhost:3000/${place['image']}',
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error, color: Colors.red, size: 40),
                                  ),
                                ),
                              ),
                              if (widget.user['role'] == 'admin')
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(place['id']),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF273671),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  place['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      place['location'],
                                      style: const TextStyle(
                                        color: Color(0xFF273671),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (place['rating'] > 0)
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            place['rating'].toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Color(0xFF273671),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => _toggleLike(place['id']),
                                    ),
                                    Text(
                                      '${place['like_count'] ?? 0}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}