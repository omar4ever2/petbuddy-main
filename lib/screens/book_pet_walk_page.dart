import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet_walking.dart';
import '../models/pet.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';

class BookPetWalkPage extends StatefulWidget {
  final PetWalker walker;

  const BookPetWalkPage({Key? key, required this.walker}) : super(key: key);

  @override
  State<BookPetWalkPage> createState() => _BookPetWalkPageState();
}

class _BookPetWalkPageState extends State<BookPetWalkPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingPets = true;
  List<Pet> _userPets = [];

  // Form fields
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedPetId;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  // Calculate duration between two TimeOfDay objects in hours
  double _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return (endMinutes - startMinutes) / 60.0;
  }

  // Calculate total price
  double get _totalPrice {
    final duration = _calculateDuration(_startTime, _endTime);
    return duration * widget.walker.hourlyRate;
  }

  @override
  void initState() {
    super.initState();
    _loadUserPets();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _isLoadingPets = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final petsData = await supabaseService.getUserPets();

      if (petsData.isNotEmpty) {
        setState(() {
          _userPets = petsData.map((data) => Pet.fromJson(data)).toList();
          _selectedPetId = _userPets.first.id;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load your pets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPets = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;

        // Ensure end time is after start time
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;

        if (endMinutes <= startMinutes) {
          // Set end time to start time + 1 hour
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null && picked != _endTime) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final pickedMinutes = picked.hour * 60 + picked.minute;

      if (pickedMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userPets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to add a pet before booking a walk'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Get selected pet name
      final selectedPet =
          _userPets.firstWhere((pet) => pet.id == _selectedPetId);

      // Prepare walk data
      final walkData = {
        'walker_id': widget.walker.id,
        'pet_id': _selectedPetId,
        'pet_name': selectedPet.name,
        'walk_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'start_time':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'duration': _calculateDuration(_startTime, _endTime),
        'location': _locationController.text,
        'notes': _notesController.text,
        'price': _totalPrice,
        'walker_name': widget.walker.name,
        'walker_image': widget.walker.imageUrl,
      };

      // Submit the booking
      final response = await supabaseService.schedulePetWalk(walkData);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Booking Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color.fromARGB(255, 40, 108, 100),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your pet walk has been scheduled successfully.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Booking #${response['id'].toString().substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 40, 108, 100),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Navigate back to previous screens
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Navigate to my bookings page
                  Navigator.of(context).pushReplacementNamed('/my_pet_walks');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 40, 108, 100),
                  foregroundColor: Colors.white,
                ),
                child: const Text('View My Bookings'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error booking pet walk: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book pet walk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Book Pet Walk'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      ),
      body: _isLoadingPets
          ? const Center(child: CircularProgressIndicator())
          : _userPets.isEmpty
              ? _buildNoPetsView(isDarkMode)
              : _buildBookingForm(isDarkMode),
    );
  }

  Widget _buildNoPetsView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pets Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to add a pet before booking a walk',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add_pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 40, 108, 100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add a Pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Walker information card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(widget.walker.imageUrl),
                      onBackgroundImageError: (e, _) {},
                      child: const Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.walker.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.walker.rating.toStringAsFixed(1)} (${widget.walker.completedWalks} walks)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'LE ${widget.walker.hourlyRate.toStringAsFixed(2)}/hour',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 40, 108, 100),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Select pet
            Text(
              'Select Pet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPetId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
              ),
              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              items: _userPets.map((pet) {
                return DropdownMenuItem<String>(
                  value: pet.id,
                  child: Text(pet.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPetId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a pet';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date and time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEE, MMM d, yyyy')
                                    .format(_selectedDate),
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Start time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectStartTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startTime.format(context),
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // End time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectEndTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endTime.format(context),
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duration and total price
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[800]!.withOpacity(0.5)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration: ${_calculateDuration(_startTime, _endTime).toStringAsFixed(1)} hours',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Total: LE ${_totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 40, 108, 100),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Location
            Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter pickup/walking location',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Notes
            Text(
              'Special Instructions (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Any special instructions for the walker',
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
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Book button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 40, 108, 100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'BOOK NOW',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
