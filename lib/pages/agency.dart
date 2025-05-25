import 'package:flutter/material.dart';
import 'package:travel_app/services/api_service.dart';

class Agency extends StatefulWidget {
  final Map<String, dynamic> user;

  const Agency({super.key, required this.user});

  @override
  State<Agency> createState() => _AgencyState();
}

class _AgencyState extends State<Agency> {
  List<Map<String, dynamic>> agencies = [];
  Map<int, List<Map<String, dynamic>>> tourSchedules = {};
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchAgencies();
  }

  Future<void> _fetchAgencies() async {
    try {
      final fetchedAgencies = await _apiService.fetchAgencies();
      setState(() {
        agencies = fetchedAgencies;
      });
      for (var agency in agencies) {
        final schedules = await _apiService.fetchTourSchedules(agency['id']);
        setState(() {
          tourSchedules[agency['id']] = schedules;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching agencies: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchAgencies,
        color: const Color(0xFF273671),
        child: agencies.isEmpty
            ? const Center(child: Text('No agencies found', style: TextStyle(fontSize: 16)))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: agencies.length,
                itemBuilder: (context, index) {
                  final agency = agencies[index];
                  final schedules = tourSchedules[agency['id']] ?? [];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            agency['image'] != null
                                ? 'http://localhost:3000/${agency['image']}'
                                : 'https://via.placeholder.com/400x200',
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
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agency['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF273671),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                agency['description'] ?? 'No description available',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contact: ${agency['contact'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Color(0xFF273671),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tour Schedules',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              schedules.isEmpty
                                  ? const Text(
                                      'No tours scheduled',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    )
                                  : Column(
                                      children: schedules.map((schedule) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Place: ${schedule['place_title']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF273671),
                                                  ),
                                                ),
                                                Text('Date: ${schedule['tour_date']}'),
                                                Text('Price: \$${schedule['price']}'),
                                                if (schedule['description'] != null)
                                                  Text(
                                                    'Details: ${schedule['description']}',
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}