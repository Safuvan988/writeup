import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:write_up/app/theme_data/app_colors.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class BlogDetailScreen extends StatefulWidget {
  final BlogData blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;
  int _readingTimeMin = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          setState(() {
            _scrollProgress = maxScroll > 0
                ? (currentScroll / maxScroll).clamp(0.0, 1.0)
                : 0.0;
          });
        }
      });

    _calculateReadingTime();
  }

  void _calculateReadingTime() {
    // Average reading speed is 200 words per minute.
    final words = widget.blog.description
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
    setState(() {
      _readingTimeMin = (words / 200).ceil();
      if (_readingTimeMin < 1) _readingTimeMin = 1;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final d = DateTime.parse(rawDate).toLocal();
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
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Read Blog',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.white),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Check out this blog: ${widget.blog.title}\n\n${widget.blog.description}',
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.blog.image != null && widget.blog.image!.isNotEmpty)
              Image.network(
                widget.blog.image!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 250,
                  color: AppColors.forest4,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.forest3,
                    size: 50,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: widget.blog.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forest3.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: AppColors.forest1,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.blog.title,
                    style: GoogleFonts.texturina(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.forest3,
                        backgroundImage:
                            (widget.blog.authorImage != null &&
                                widget.blog.authorImage!.isNotEmpty)
                            ? NetworkImage(widget.blog.authorImage!)
                            : null,
                        child:
                            (widget.blog.authorImage == null ||
                                widget.blog.authorImage!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                color: AppColors.forest1,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.blog.authorName ?? 'Unknown Author',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
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
                                  _formatDate(widget.blog.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.forest2,
                                    fontSize: 12,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.circle,
                                    size: 4,
                                    color: AppColors.forest2,
                                  ),
                                ),
                                SvgPicture.asset(
                                  'assets/icons/time-03-stroke-rounded.svg',
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.forest2,
                                    BlendMode.srcIn,
                                  ),
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_readingTimeMin min read',
                                  style: const TextStyle(
                                    color: AppColors.forest2,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.forest3),
                  const SizedBox(height: 24),
                  ...widget.blog.description
                      .split(RegExp(r'\n\s*\n|\n'))
                      .where((para) => para.trim().isNotEmpty)
                      .map((para) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            para.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.forest1,
                              height: 1.6,
                            ),
                          ),
                        );
                      }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
