import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class CategoryItem extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  const CategoryItem({
    Key? key,
    required this.id,
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? const Color.fromARGB(255, 37, 150, 190);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              height: 70,
              margin: const EdgeInsets.only(top: 5),
              width: 70,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? themeColor.withOpacity(0.15)
                    : themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : themeColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ThemeUtils.textColor(isDarkMode),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
