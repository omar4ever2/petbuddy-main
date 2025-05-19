import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet_walking.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';

class MyPetWalksPage extends StatefulWidget {
  const MyPetWalksPage({Key? key}) : super(key: key);

  @override
  State<MyPetWalksPage> createState() => _MyPetWalksPageState();
}

class _MyPetWalksPageState extends State<MyPetWalksPage> {
  bool _isLoading = true;
  List<PetWalking> _walks = [];
  String _activeFilter = 'upcoming'; // upcoming, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadWalks();
  }

  Future<void> _loadWalks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final walksData = await supabaseService.getUserPetWalks();

      setState(() {
        _walks = walksData.map((data) {
          // Extract walker details from nested data structure if available
          final walkerData = data['pet_walkers'];
          Map<String, dynamic> cleanedData = {...data};

          if (walkerData != null) {
            cleanedData.remove('pet_walkers');
            cleanedData['walker_name'] = walkerData['name'];
            cleanedData['walker_image'] = walkerData['image_url'];
            cleanedData['walker_rating'] = walkerData['rating'];
          }

          return PetWalking.fromJson(cleanedData);
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pet walks: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pet walks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PetWalking> get _filteredWalks {
    final now = DateTime.now();

    switch (_activeFilter) {
      case 'upcoming':
        return _walks.where((walk) {
          return walk.walkDate.isAfter(now) && walk.status != 'cancelled';
        }).toList();
      case 'completed':
        return _walks.where((walk) {
          return walk.status == 'completed' ||
              (walk.walkDate.isBefore(now) && walk.status == 'confirmed');
        }).toList();
      case 'cancelled':
        return _walks.where((walk) => walk.status == 'cancelled').toList();
      default:
        return _walks;
    }
  }

  Future<void> _cancelWalk(PetWalking walk) async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Show confirmation dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel Walk?'),
          content: Text(
              'Are you sure you want to cancel the walk with ${walk.petName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (result == true) {
        await supabaseService.cancelPetWalk(walk.id);

        // Refresh walks
        _loadWalks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Walk cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error cancelling walk: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel walk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rateWalker(PetWalking walk) async {
    double rating = 5.0;

    // Show rating dialog
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rate ${walk.walkerName ?? "Walker"}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(rating),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(rating),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 40, 108, 100),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Rating'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final supabaseService =
            Provider.of<SupabaseService>(context, listen: false);
        await supabaseService.ratePetWalker(walk.walkerId!, result, walk.id);

        // Refresh walks
        _loadWalks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your rating!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error rating walker: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit rating: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Excellent';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Pet Walks'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterTab('upcoming', 'Upcoming', isDarkMode),
                _buildFilterTab('completed', 'Completed', isDarkMode),
                _buildFilterTab('cancelled', 'Cancelled', isDarkMode),
              ],
            ),
          ),

          // Walks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWalks.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : RefreshIndicator(
                        onRefresh: _loadWalks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredWalks.length,
                          itemBuilder: (context, index) {
                            final walk = _filteredWalks[index];
                            return _buildWalkCard(walk, isDarkMode);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/pet_walkers');
        },
        backgroundColor: const Color.fromARGB(255, 40, 108, 100),
        child: const Icon(Icons.add),
        tooltip: 'Book New Walk',
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, bool isDarkMode) {
    final isActive = _activeFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? const Color.fromARGB(255, 40, 108, 100)
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? const Color.fromARGB(255, 40, 108, 100)
                  : isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    String message;
    switch (_activeFilter) {
      case 'upcoming':
        message = 'No upcoming walks scheduled';
        break;
      case 'completed':
        message = 'No completed walks yet';
        break;
      case 'cancelled':
        message = 'No cancelled walks';
        break;
      default:
        message = 'No pet walks found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk,
            size: 80,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _activeFilter == 'upcoming'
                ? 'Book a walk to get started'
                : 'Your walks will appear here',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (_activeFilter == 'upcoming') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/pet_walkers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 40, 108, 100),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Book a Walk'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalkCard(PetWalking walk, bool isDarkMode) {
    final now = DateTime.now();
    final isPast = walk.walkDate.isBefore(now);
    final isCancelled = walk.status == 'cancelled';
    final isCompleted =
        walk.status == 'completed' || (isPast && walk.status == 'confirmed');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          // Status indicator
          Container(
            decoration: BoxDecoration(
              color: _getStatusColor(walk.status, isPast),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: double.infinity,
            child: Text(
              _getStatusText(walk.status, isPast),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Walk details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and time
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(walk.walkDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${PetWalking.timeOfDayToString(walk.startTime)} - ${PetWalking.timeOfDayToString(walk.endTime)} (${walk.duration.toStringAsFixed(1)} hours)',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pet
                Row(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      walk.petName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Walker info
                if (walk.walkerId != null) ...[
                  Row(
                    children: [
                      // Walker image
                      if (walk.walkerImage != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(walk.walkerImage!),
                          radius: 20,
                          onBackgroundImageError: (e, _) {},
                        )
                      else
                        CircleAvatar(
                          backgroundColor:
                              isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          radius: 20,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Walker name and rating
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              walk.walkerName ?? 'Walker',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            if (walk.walkerRating != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    walk.walkerRating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Price
                      Text(
                        'LE ${walk.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color.fromARGB(255, 40, 108, 100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        walk.location,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                // Notes (if any)
                if (walk.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 18,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          walk.notes,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons
                if (!isCancelled) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button (for upcoming walks)
                      if (!isPast && !isCompleted)
                        ElevatedButton(
                          onPressed: () => _cancelWalk(walk),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.red,
                            backgroundColor:
                                isDarkMode ? Colors.grey[850] : Colors.white,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Cancel'),
                        ),

                      // Rate button (for completed walks)
                      if (isCompleted && walk.walkerId != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _rateWalker(walk),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 40, 108, 100),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(walk.walkerRating != null
                              ? 'Rate Again'
                              : 'Rate Walker'),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, bool isPast) {
    switch (status) {
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        if (isPast) return Colors.green;
        return const Color.fromARGB(255, 40, 108, 100);
    }
  }

  String _getStatusText(String status, bool isPast) {
    switch (status) {
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'pending':
        return isPast ? 'Completed' : 'Pending';
      case 'confirmed':
        return isPast ? 'Completed' : 'Confirmed';
      default:
        return isPast ? 'Completed' : status.toUpperCase();
    }
  }
}
