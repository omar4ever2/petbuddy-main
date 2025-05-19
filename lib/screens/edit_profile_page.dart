import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _imageFile;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      if (supabaseService.isAuthenticated) {
        final profileData = await supabaseService.getUserProfile();

        _usernameController.text = profileData['username'] ?? '';
        _fullNameController.text = profileData['full_name'] ?? '';
        _phoneController.text = profileData['phone'] ?? '';
        _currentAvatarUrl = profileData['avatar_url'];
      }
    } catch (e) {
      print('Error loading profile data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      String? avatarUrl = _currentAvatarUrl;

      // Upload new avatar if selected
      if (_imageFile != null) {
        avatarUrl = await supabaseService.uploadProfileImage(_imageFile!);
        // Update the current avatar URL to reflect the change
        setState(() {
          _currentAvatarUrl = avatarUrl;
        });
      }

      // Create profile data map
      final profileData = {
        'username': _usernameController.text,
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'avatar_url': avatarUrl,
      };

      // Update profile data in Supabase
      await supabaseService.updateUserProfile(profileData);

      // Notify the user of successful update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color.fromARGB(255, 40, 108, 100),
        ),
      );

      // Refresh user data in the SupabaseService
      await supabaseService.refreshUserData();

      Navigator.pop(context, profileData);
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
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
          'Edit Profile',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: themeColor.withOpacity(0.1),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : _currentAvatarUrl != null &&
                                        _currentAvatarUrl!.isNotEmpty
                                    ? NetworkImage(_currentAvatarUrl!)
                                    : null as ImageProvider<Object>?,
                            child: _imageFile == null &&
                                    (_currentAvatarUrl == null ||
                                        _currentAvatarUrl!.isEmpty)
                                ? Text(
                                    _usernameController.text.isNotEmpty
                                        ? _usernameController.text[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
