import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/adoptable_pet.dart';
import '../services/supabase_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AdoptablePetDetailsPage extends StatefulWidget {
  final String petId;

  const AdoptablePetDetailsPage({
    Key? key,
    required this.petId,
  }) : super(key: key);

  @override
  State<AdoptablePetDetailsPage> createState() =>
      _AdoptablePetDetailsPageState();
}

class _AdoptablePetDetailsPageState extends State<AdoptablePetDetailsPage> {
  bool _isLoading = true;
  AdoptablePet? _pet;
  String? _errorMessage;
  final Color themeColor = const Color.fromARGB(255, 40, 108, 100);

  @override
  void initState() {
    super.initState();
    _loadPetDetails();
  }

  Future<void> _loadPetDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final petData = await supabaseService.getAdoptablePetById(widget.petId);

      setState(() {
        _pet = AdoptablePet.fromJson(petData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading adoptable pet details: $e');
      setState(() {
        _errorMessage = 'Failed to load pet details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Regarding adoption of ${_pet?.name}',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email to $email')),
      );
    }
  }

  IconData _getSpeciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return FontAwesomeIcons.dog;
      case 'cat':
        return FontAwesomeIcons.cat;
      case 'bird':
        return FontAwesomeIcons.crow;
      default:
        return FontAwesomeIcons.paw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeUtils.backgroundColor(isDarkMode),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : _errorMessage != null
              ? _buildErrorView()
              : _pet == null
                  ? const Center(child: Text('Pet not found'))
                  : _buildPetDetails(isDarkMode),
      floatingActionButton: _pet != null ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
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
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPetDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetDetails(bool isDarkMode) {
    return CustomScrollView(
      slivers: [
        // App bar with pet image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: themeColor,
          flexibleSpace: FlexibleSpaceBar(
            background: _pet!.imageUrl != null && _pet!.imageUrl!.isNotEmpty
                ? Image.network(
                    _pet!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          _getSpeciesIcon(_pet!.species),
                          size: 80,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                      );
                    },
                  )
                : Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      _getSpeciesIcon(_pet!.species),
                      size: 80,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Sharing functionality coming soon')),
                );
              },
              tooltip: 'Share',
            ),
          ],
        ),

        // Pet information
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet name and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pet!.name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ThemeUtils.textColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getSpeciesIcon(_pet!.species),
                                size: 14,
                                color: themeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _pet!.species,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      ThemeUtils.secondaryTextColor(isDarkMode),
                                ),
                              ),
                              if (_pet!.breed != null) ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _pet!.breed!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ThemeUtils.secondaryTextColor(
                                        isDarkMode),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Free Adoption',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Key pet information cards
                _buildInfoCards(isDarkMode),

                const SizedBox(height: 24),

                // Description section
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.textColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _pet!.description ?? 'No description available.',
                  style: TextStyle(
                    color: ThemeUtils.secondaryTextColor(isDarkMode),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Contact information
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.textColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: ThemeUtils.cardColor(isDarkMode),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_pet!.location != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: themeColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pet!.location!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ThemeUtils.textColor(isDarkMode),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_pet!.contactEmail != null) ...[
                          GestureDetector(
                            onTap: () => _launchEmail(_pet!.contactEmail!),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: themeColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pet!.contactEmail!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: themeColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_pet!.contactPhone != null) ...[
                          GestureDetector(
                            onTap: () => _launchCall(_pet!.contactPhone!),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: themeColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pet!.contactPhone!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: themeColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80), // Space for the bottom button
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(bool isDarkMode) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Age card
        _buildInfoCard(
          isDarkMode,
          icon: Icons.cake,
          title: 'Age',
          value: _pet!.ageText,
        ),

        // Gender card
        _buildInfoCard(
          isDarkMode,
          icon: _pet!.gender?.toLowerCase() == 'male'
              ? Icons.male
              : _pet!.gender?.toLowerCase() == 'female'
                  ? Icons.female
                  : Icons.help,
          title: 'Gender',
          value: _pet!.gender?.capitalize() ?? 'Unknown',
        ),

        // Size card
        if (_pet!.size != null)
          _buildInfoCard(
            isDarkMode,
            icon: Icons.straighten,
            title: 'Size',
            value: _pet!.size!.replaceAll('_', ' ').capitalize(),
          ),

        // Vaccinated status
        _buildInfoCard(
          isDarkMode,
          icon: Icons.health_and_safety,
          title: 'Vaccinated',
          value: _pet!.isVaccinated ? 'Yes' : 'No',
          positive: _pet!.isVaccinated,
        ),

        // Neutered status
        _buildInfoCard(
          isDarkMode,
          icon: Icons.cut,
          title: 'Neutered',
          value: _pet!.isNeutered ? 'Yes' : 'No',
          positive: _pet!.isNeutered,
        ),

        // House trained status
        _buildInfoCard(
          isDarkMode,
          icon: Icons.home,
          title: 'House Trained',
          value: _pet!.isHouseTrained ? 'Yes' : 'No',
          positive: _pet!.isHouseTrained,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    bool isDarkMode, {
    required IconData icon,
    required String title,
    required String value,
    bool? positive,
  }) {
    final valueColor = positive == null
        ? ThemeUtils.textColor(isDarkMode)
        : positive
            ? Colors.green[600]
            : Colors.red[400];

    return Card(
      color: ThemeUtils.cardColor(isDarkMode),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: ThemeUtils.secondaryTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: themeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          if (_pet?.contactEmail != null) {
            _launchEmail(_pet!.contactEmail!);
          } else if (_pet?.contactPhone != null) {
            _launchCall(_pet!.contactPhone!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No contact information available')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Contact About Adoption',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
