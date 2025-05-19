import 'package:flutter/material.dart';
import '../models/adoptable_pet.dart';
import '../screens/adoptable_pet_details_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdoptablePetCard extends StatelessWidget {
  final AdoptablePet pet;

  const AdoptablePetCard({
    Key? key,
    required this.pet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get a color based on species for visual distinction
    Color speciesColor = Colors.teal;
    if (pet.species.toLowerCase() == 'dog') {
      speciesColor = Colors.brown;
    } else if (pet.species.toLowerCase() == 'cat') {
      speciesColor = Colors.orange;
    } else if (pet.species.toLowerCase() == 'bird') {
      speciesColor = Colors.blue;
    }

    // Get appropriate icon
    IconData speciesIcon = Icons.pets;
    if (pet.species.toLowerCase() == 'bird') {
      speciesIcon = FontAwesomeIcons.crow;
    } else if (pet.species.toLowerCase() == 'cat') {
      speciesIcon = FontAwesomeIcons.cat;
    } else if (pet.species.toLowerCase() == 'dog') {
      speciesIcon = FontAwesomeIcons.dog;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdoptablePetDetailsPage(petId: pet.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 180,
        decoration: BoxDecoration(
          color: ThemeUtils.cardColor(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pet image with gradient overlay and species badge
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                        ? Image.network(
                            pet.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.pets,
                                color:
                                    isDarkMode ? Colors.grey[600] : Colors.grey,
                              ),
                            ),
                          ),
                  ),
                ),

                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),

                // Pet name on gradient
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Species badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pet.species,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Free Adoption badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Free',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Pet info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location and age
                  if (pet.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color.fromARGB(255, 40, 108, 100),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            pet.location!,
                            style: TextStyle(
                              fontSize: 10,
                              color: ThemeUtils.secondaryTextColor(isDarkMode),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Color.fromARGB(255, 40, 108, 100),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        pet.ageText,
                        style: TextStyle(
                          fontSize: 10,
                          color: ThemeUtils.secondaryTextColor(isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Features
                  _buildPetFeatures(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetFeatures(bool isDarkMode) {
    // Customize pet features for birds
    if (pet.species.toLowerCase() == 'bird') {
      return Row(
        children: [
          if (pet.isVaccinated)
            _buildFeatureDot('Vaccinated', Colors.green, isDarkMode),
          if (pet.isHouseTrained)
            _buildFeatureDot('Trained', Colors.orange, isDarkMode),
          _buildFeatureDot('Can sing', Colors.purple, isDarkMode),
        ],
      );
    } else {
      // Original features for other pets
      return Row(
        children: [
          if (pet.isVaccinated)
            _buildFeatureDot('Vaccinated', Colors.green, isDarkMode),
          if (pet.isNeutered)
            _buildFeatureDot('Neutered', Colors.blue, isDarkMode),
          if (pet.isHouseTrained)
            _buildFeatureDot('Trained', Colors.orange, isDarkMode),
        ],
      );
    }
  }

  Widget _buildFeatureDot(String label, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: label,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
