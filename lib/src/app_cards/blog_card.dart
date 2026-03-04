import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:write_up/app/theme_data/app_colors.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';
import 'package:google_fonts/google_fonts.dart';

class BlogCard extends StatelessWidget {
  final BlogData blog;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onShare;

  const BlogCard({
    super.key,
    required this.blog,
    this.onTap,
    this.trailing,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final String category = blog.tags.isNotEmpty ? blog.tags.first : 'Blogging';
    final words = blog.description
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
    int readingTimeMin = (words / 200).ceil();
    if (readingTimeMin < 1) readingTimeMin = 1;

    String formattedDate = '';
    if (blog.createdAt != null) {
      try {
        final d = DateTime.parse(blog.createdAt!).toLocal();
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final period = d.hour >= 12 ? 'PM' : 'AM';
        final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
        formattedDate =
            '${d.day} ${months[d.month - 1]} ${d.year}, $hour:${d.minute.toString().padLeft(2, '0')} $period';
      } catch (e) {
        formattedDate = blog.createdAt!;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.forest3.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest4.withValues(alpha: 0.6),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: (blog.image != null && blog.image!.isNotEmpty)
                      ? Image.network(
                          blog.image!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ImagePlaceholder(height: 200),
                        )
                      : const _ImagePlaceholder(height: 200),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest3.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.forest1,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onShare != null)
                        GestureDetector(
                          onTap: onShare,
                          child: Container(
                            margin: EdgeInsets.only(
                              right: onBookmarkToggle != null ? 8 : 0,
                            ),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share_outlined,
                              color: AppColors.forest1,
                              size: 20,
                            ),
                          ),
                        ),
                      if (onBookmarkToggle != null)
                        GestureDetector(
                          onTap: onBookmarkToggle,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isBookmarked
                                  ? AppColors.forest1
                                  : AppColors.surface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/bookmark-02-stroke-rounded.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                isBookmarked
                                    ? AppColors.white
                                    : AppColors.forest1,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: GoogleFonts.texturina(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.forest1,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (formattedDate.isNotEmpty) ...[
                        SvgPicture.asset(
                          'assets/icons/calendar-03-stroke-rounded.svg',
                          colorFilter: const ColorFilter.mode(
                            AppColors.forest2,
                            BlendMode.srcIn,
                          ),
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.forest2,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      SvgPicture.asset(
                        'assets/icons/time-03-stroke-rounded.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.forest2,
                          BlendMode.srcIn,
                        ),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$readingTimeMin min read',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.forest2,
                        ),
                      ),
                      if (trailing != null) ...[const Spacer(), trailing!],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double height;

  const _ImagePlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.forest4,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.forest3,
        size: 32,
      ),
    );
  }
}
