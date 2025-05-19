import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../models/vaccine_appointment.dart';
import '../utils/theme_utils.dart';
import '../widgets/vaccine_appointment_card.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
  String? _errorMessage;
  bool _showOnlyUpcoming = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      if (!supabaseService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Please sign in to see your appointments';
          _isLoading = false;
        });
        return;
      }

      // Load appointments based on filter
      final appointments = _showOnlyUpcoming
          ? await supabaseService.getUpcomingVaccineAppointments()
          : await supabaseService.getAllVaccineAppointments();

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _errorMessage = 'Failed to load appointments: $e';
        _isLoading = false;
      });
    }
  }

  // Cancel an appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      await supabaseService.cancelVaccineAppointment(appointmentId);

      // Update the appointment status in the local list
      setState(() {
        _appointments = _appointments.map((appointment) {
          if (appointment['id'] == appointmentId) {
            return {...appointment, 'status': 'cancelled'};
          }
          return appointment;
        }).toList();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const themeColor = ThemeUtils.themeColor;

    return Scaffold(
      backgroundColor: ThemeUtils.backgroundColor(isDarkMode),
      appBar: AppBar(
        title: const Text('My Appointments',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Toggle switch for showing only upcoming appointments
          Row(
            children: [
              Text(
                'Upcoming only',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              Switch(
                value: _showOnlyUpcoming,
                activeColor: themeColor,
                onChanged: (value) {
                  setState(() {
                    _showOnlyUpcoming = value;
                    // Reload appointments with the new filter
                    _loadAppointments();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        color: themeColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorMessage()
                : _appointments.isEmpty
                    ? _buildEmptyState()
                    : _buildAppointmentsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeUtils.themeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 70,
              color: ThemeUtils.themeColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No appointments found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Book your first vaccine appointment to keep your pet healthy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Go back to previous screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Book Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeUtils.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeUtils.themeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        final status = appointment['status'] as String;
        final isCompleted = status == 'completed';
        final isCancelled = status == 'cancelled';

        // Convert appointment data to VaccineAppointment model
        final vaccineAppointment = VaccineAppointment.fromJson(appointment);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: VaccineAppointmentCard(
            appointment: vaccineAppointment,
            onCancel: () => _cancelAppointment(appointment['id']),
          ),
        );
      },
    );
  }
}
