import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/vaccine_appointment.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import '../widgets/vaccine_appointment_card.dart';
import '../screens/my_appointments_page.dart';

class VaccineBookingPage extends StatefulWidget {
  const VaccineBookingPage({Key? key}) : super(key: key);

  @override
  State<VaccineBookingPage> createState() => _VaccineBookingPageState();
}

class _VaccineBookingPageState extends State<VaccineBookingPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingAppointments = true;
  List<Map<String, dynamic>> _vaccineTypes = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _filteredVaccineTypes = [];
  bool _showOnlyUpcoming = true;
  String? _errorMessage;
  late TabController _tabController;
  final Color themeColor = const Color.fromARGB(255, 40, 108, 100);

  // Form fields
  final _petNameController = TextEditingController();
  String _petType = 'Dog';
  String? _vaccineType;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final _notesController = TextEditingController();

  final List<String> _petTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Hamster',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Filter vaccine types based on selected pet type
  void _filterVaccineTypes() {
    if (_vaccineTypes.isEmpty) return;

    setState(() {
      _filteredVaccineTypes = _vaccineTypes.where((vaccine) {
        // Include if pet_type is null (meaning it's for all pets)
        // or if it matches the selected pet type
        return vaccine['pet_type'] == null || vaccine['pet_type'] == _petType;
      }).toList();

      // Reset vaccine type if it's not in the filtered list
      if (_filteredVaccineTypes.isEmpty) {
        _vaccineType = null;
      } else {
        // Check if current vaccine type exists in filtered list
        bool vaccineTypeExists = false;
        if (_vaccineType != null) {
          vaccineTypeExists = _filteredVaccineTypes
              .any((vaccine) => vaccine['name'] == _vaccineType);
        }

        // If current vaccine type doesn't exist in filtered list, set to first one
        if (!vaccineTypeExists) {
          _vaccineType = _filteredVaccineTypes[0]['name'];
        }
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingAppointments = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Load vaccine types
      final vaccineTypes = await supabaseService.getVaccineTypes();

      // Load upcoming appointments
      final upcomingAppointments =
          await supabaseService.getUpcomingVaccineAppointments();

      setState(() {
        _vaccineTypes = vaccineTypes;

        // Filter vaccine types based on pet type
        _filterVaccineTypes();

        _upcomingAppointments = upcomingAppointments;
        _isLoading = false;
        _isLoadingAppointments = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _isLoadingAppointments = false;
        _errorMessage = 'Failed to load data: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Make sure we have a selected vaccine type
      if (_vaccineType == null) {
        throw Exception('Please select a vaccine type');
      }

      final appointmentData = {
        'pet_name': _petNameController.text,
        'pet_type': _petType,
        'vaccine_type': _vaccineType,
        'appointment_date': appointmentDateTime.toIso8601String(),
        'notes': _notesController.text,
      };

      final response =
          await supabaseService.createVaccineAppointment(appointmentData);

      // Add the new appointment to the list to show it immediately
      setState(() {
        _upcomingAppointments = [response, ..._upcomingAppointments];
      });

      // Reset form
      _petNameController.clear();
      _notesController.clear();
      setState(() {
        _petType = 'Dog';
        _filterVaccineTypes(); // Re-filter vaccine types
        _selectedDate = DateTime.now().add(const Duration(days: 1));
        _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      });

      if (mounted) {
        // Show a success dialog with option to view appointments
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Appointment Booked!'),
            content: const Text(
              'Your pet vaccination appointment has been successfully scheduled.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Switch to Appointments tab after successful booking
                  _tabController.animateTo(0);
                },
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyAppointmentsPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeUtils.themeColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View All Appointments'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error booking appointment: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content:
              const Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      await supabaseService.cancelVaccineAppointment(appointmentId);

      // Update the local list to reflect the cancellation
      setState(() {
        _upcomingAppointments = _upcomingAppointments.map((appointment) {
          if (appointment['id'] == appointmentId) {
            return {...appointment, 'status': 'cancelled'};
          }
          return appointment;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error cancelling appointment: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeUtils.backgroundColor(isDarkMode),
      appBar: AppBar(
        title: const Text('Pet Vaccination',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Add a button to view all appointments
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'My Appointments',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyAppointmentsPage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: themeColor,
        elevation: 0,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              text: 'My Appointments',
              icon: Icon(Icons.calendar_today, color: Colors.white),
            ),
            Tab(
              text: 'Book New',
              icon: Icon(Icons.add_circle_outline, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoading && _errorMessage == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: themeColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: ThemeUtils.textColor(isDarkMode),
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.textColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ThemeUtils.secondaryTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsTab(isDarkMode),
                    _buildBookingTab(isDarkMode),
                  ],
                ),
    );
  }

  Widget _buildAppointmentsTab(bool isDarkMode) {
    // Filter out cancelled appointments if showing only upcoming
    final displayedAppointments = _upcomingAppointments
        .where((appointment) =>
            !_showOnlyUpcoming || appointment['status'] != 'cancelled')
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Your Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.textColor(isDarkMode),
                ),
              ),
              const Spacer(),
              Switch(
                value: _showOnlyUpcoming,
                onChanged: (value) {
                  setState(() {
                    _showOnlyUpcoming = value;
                  });
                },
                activeColor: themeColor,
              ),
              Text(
                'Hide cancelled',
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeUtils.secondaryTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingAppointments
              ? Center(
                  child: CircularProgressIndicator(color: themeColor),
                )
              : displayedAppointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming appointments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: ThemeUtils.textColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book a vaccine appointment for your pet',
                            style: TextStyle(
                              fontSize: 14,
                              color: ThemeUtils.secondaryTextColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _tabController.animateTo(1);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Book Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: themeColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayedAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = displayedAppointments[index];
                          final vaccineAppointment =
                              VaccineAppointment.fromJson(appointment);
                          return VaccineAppointmentCard(
                            appointment: vaccineAppointment,
                            onCancel: vaccineAppointment.status == 'pending' ||
                                    vaccineAppointment.status == 'confirmed'
                                ? () =>
                                    _cancelAppointment(vaccineAppointment.id)
                                : null,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBookingTab(bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book a Vaccine Appointment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.textColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 24),

              // Pet Name
              TextFormField(
                controller: _petNameController,
                decoration: InputDecoration(
                  labelText: 'Pet Name',
                  hintText: 'Enter your pet\'s name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pets),
                  filled: true,
                  fillColor: ThemeUtils.inputBackgroundColor(isDarkMode),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pet\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pet Type
              DropdownButtonFormField<String>(
                value: _petType,
                decoration: InputDecoration(
                  labelText: 'Pet Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                  filled: true,
                  fillColor: ThemeUtils.inputBackgroundColor(isDarkMode),
                ),
                items: _petTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _petType = value;
                      // Refilter vaccine types when pet type changes
                      _filterVaccineTypes();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Vaccine Type
              _filteredVaccineTypes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ThemeUtils.cardColor(isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No vaccine types available for $_petType. Please choose a different pet type.',
                              style: TextStyle(
                                color: ThemeUtils.textColor(isDarkMode),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value:
                          _filteredVaccineTypes.isEmpty ? null : _vaccineType,
                      decoration: InputDecoration(
                        labelText: 'Vaccine Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.medical_services),
                        filled: true,
                        fillColor: ThemeUtils.inputBackgroundColor(isDarkMode),
                      ),
                      items: _filteredVaccineTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['name'],
                          child: Text(type['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _vaccineType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a vaccine type';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                          filled: true,
                          fillColor:
                              ThemeUtils.inputBackgroundColor(isDarkMode),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                          filled: true,
                          fillColor:
                              ThemeUtils.inputBackgroundColor(isDarkMode),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any special instructions or concerns',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                  filled: true,
                  fillColor: ThemeUtils.inputBackgroundColor(isDarkMode),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Book button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _filteredVaccineTypes.isEmpty
                      ? null
                      : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
