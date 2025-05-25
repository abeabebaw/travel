import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_app/pages/add_place.dart';
import 'package:travel_app/pages/add_agency.dart';
import 'package:travel_app/pages/add_tour_schedule.dart';
import 'package:travel_app/pages/agency.dart';
import 'package:travel_app/pages/login.dart';
import 'package:travel_app/pages/place_details.dart';
import 'package:travel_app/pages/top_place.dart';
import 'package:travel_app/services/api_service.dart';

class Home extends StatefulWidget {
  final Map<String, dynamic> user;

  const Home({super.key, required this.user});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> places = [];
  List<Map<String, dynamic>> filteredPlaces = [];
  final _apiService = ApiService();
  int _currentIndex = 0;
  Map<int, bool> _likeStatus = {};
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _searchController.addListener(_filterPlaces);
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedPlaces = await _apiService.fetchPlaces();
      setState(() {
        places = fetchedPlaces;
        filteredPlaces = fetchedPlaces;
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPlaces() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredPlaces = places.where((place) {
        return place['title'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _toggleLike(int placeId) async {
    try {
      await _apiService.likePlace(placeId, widget.user['id']);
      final isLiked = await _apiService.checkLikeStatus(placeId, widget.user['id']);
      // Re-fetch the place to ensure accurate like count
      final fetchedPlaces = await _apiService.fetchPlaces();
      setState(() {
        _likeStatus[placeId] = isLiked;
        places = fetchedPlaces;
        filteredPlaces = places.where((place) {
          return place['title'].toLowerCase().contains(_searchController.text.toLowerCase());
        }).toList();
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
        filteredPlaces.removeWhere((p) => p['id'] == placeId);
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

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      TopPlace(user: widget.user),
      Agency(user: widget.user),
      if (widget.user['role'] == 'admin') AddPlace(user: widget.user),
      if (widget.user['role'] == 'admin') AddAgency(user: widget.user),
      if (widget.user['role'] == 'admin') AddTourSchedule(user: widget.user),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Travel Explorer',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF273671),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF273671),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Top Places'),
          const BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Agencies'),
          if (widget.user['role'] == 'admin')
            const BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add Post'),
          if (widget.user['role'] == 'admin')
            const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Add Agency'),
          if (widget.user['role'] == 'admin')
            const BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Add Tour'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search places by name...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF273671)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchPlaces,
            color: const Color(0xFF273671),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF273671)))
                : filteredPlaces.isEmpty
                    ? const Center(child: Text('No places found', style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredPlaces.length,
                        itemBuilder: (context, index) {
                          final place = filteredPlaces[index];
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
        ),
      ],
    );
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

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF273671),
            child: Text(
              widget.user['username'][0].toUpperCase(),
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user['username'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF273671)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user['email'],
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Role: ${widget.user['role']}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF273671),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}