import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../screens/home_page.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 40, 108, 100),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Create profile data
      final profileData = {
        'username': _usernameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'birth_date': _birthDate != null
            ? _birthDate!.toIso8601String().split('T')[0]
            : null,
      };

      // Save profile to Supabase
      await supabaseService.createUserProfile(profileData);

      if (mounted) {
        // Navigate to home page after successful profile creation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: ${e.toString()}';
      });
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
    const themeColor = Color.fromARGB(255, 40, 108, 100);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Set Up Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s personalize your Pet Buddy experience',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.red[900]!.withOpacity(0.2)
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.red[700]! : Colors.red[300]!,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: isDarkMode ? Colors.red[400] : Colors.red[800],
                      ),
                    ),
                  ),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Choose a unique username',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: isDarkMode ? Colors.grey[400] : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? Colors.grey[800] : null,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : null,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full name field
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: isDarkMode ? Colors.grey[400] : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? Colors.grey[800] : null,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : null,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone number field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: isDarkMode ? Colors.grey[400] : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? Colors.grey[800] : null,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : null,
                    ),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : null,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Birth date field
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        hintText: 'Select your birth date',
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      controller: TextEditingController(
                        text: _birthDate != null
                            ? DateFormat('MMMM d, yyyy').format(_birthDate!)
                            : '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: themeColor.withOpacity(0.6),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Complete Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip button
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (route) => false,
                          );
                        },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
