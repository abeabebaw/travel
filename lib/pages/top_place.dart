import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_app/pages/place_details.dart';
import 'package:travel_app/services/api_service.dart';

class TopPlace extends StatefulWidget {
  final Map<String, dynamic> user;

  const TopPlace({super.key, required this.user});

  @override
  State<TopPlace> createState() => _TopPlaceState();
}

class _TopPlaceState extends State<TopPlace> {
  List<Map<String, dynamic>> topPlaces = [];
  final _apiService = ApiService();
  Map<int, bool> _likeStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTopPlaces();
  }

  Future<void> _fetchTopPlaces() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedPlaces = await _apiService.fetchTopPlaces();
      setState(() {
        // Filter places with like_count >= 3
        topPlaces = fetchedPlaces.where((p) => (p['like_count'] ?? 0) >= 3).toList();
      });
      for (var place in topPlaces) {
        final isLiked = await _apiService.checkLikeStatus(place['id'], widget.user['id']);
        setState(() {
          _likeStatus[place['id']] = isLiked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching top places: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(int placeId) async {
    try {
      await _apiService.likePlace(placeId, widget.user['id']);
      final isLiked = await _apiService.checkLikeStatus(placeId, widget.user['id']);
      // Re-fetch top places to ensure accurate like count and list
      final fetchedPlaces = await _apiService.fetchTopPlaces();
      setState(() {
        _likeStatus[placeId] = isLiked;
        // Re-apply filter after fetching
        topPlaces = fetchedPlaces.where((p) => (p['like_count'] ?? 0) >= 3).toList();
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
        topPlaces.removeWhere((p) => p['id'] == placeId);
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
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
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
      body: RefreshIndicator(
        onRefresh: _fetchTopPlaces,
        color: const Color(0xFF273671),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF273671)))
            : topPlaces.isEmpty
                ? const Center(child: Text('No top places found', style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: topPlaces.length,
                    itemBuilder: (context, index) {
                      final place = topPlaces[index];
                      final isLiked = _likeStatus[place['id']] ?? false;
                      final likeCount = place['like_count'] ?? 0;

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
                                    child: CachedNetworkImage(
                                      imageUrl: 'http://localhost:3000/${place['image']}',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => Container(
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
                                          '$likeCount',
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