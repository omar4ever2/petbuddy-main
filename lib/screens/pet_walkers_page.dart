import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet_walking.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';

class PetWalkersPage extends StatefulWidget {
  const PetWalkersPage({Key? key}) : super(key: key);

  @override
  State<PetWalkersPage> createState() => _PetWalkersPageState();
}

class _PetWalkersPageState extends State<PetWalkersPage> {
  bool _isLoading = true;
  List<PetWalker> _walkers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWalkers();
  }

  Future<void> _loadWalkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final walkersData = await supabaseService.getAvailablePetWalkers();

      setState(() {
        _walkers = walkersData.map((data) => PetWalker.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading walkers: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pet walkers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PetWalker> get _filteredWalkers {
    if (_searchQuery.isEmpty) {
      return _walkers;
    }

    return _walkers.where((walker) {
      final name = walker.name.toLowerCase();
      final specialty = walker.specialties.join(' ').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || specialty.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pet Walkers'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search walkers by name or specialty',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),

          // Walkers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWalkers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No walkers available'
                              : 'No walkers found for "$_searchQuery"',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWalkers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _filteredWalkers.length,
                          itemBuilder: (context, index) {
                            final walker = _filteredWalkers[index];
                            return _buildWalkerCard(walker, isDarkMode);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkerCard(PetWalker walker, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/pet_walker_details',
            arguments: walker.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Walker image and basic info
            Row(
              children: [
                // Walker image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Image.network(
                    walker.imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey,
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),

                // Walker info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          walker.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${walker.rating.toStringAsFixed(1)} (${walker.completedWalks} walks)',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Price
                        Text(
                          'LE ${walker.hourlyRate.toStringAsFixed(2)}/hour',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 40, 108, 100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Book button
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/book_pet_walk',
                        arguments: walker,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 40, 108, 100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),

            // Specialties
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: walker.specialties.map((specialty) {
                  return Chip(
                    label: Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    backgroundColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    padding: const EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
