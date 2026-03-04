import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:write_up/app/theme_data/app_colors.dart';
import 'package:write_up/src/app_cards/blog_card.dart';
import 'package:write_up/src/modules/home_screen/controller/blog_service.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';
import 'package:write_up/src/core/services/storage_service.dart';
import 'package:write_up/src/modules/home_screen/view/create_blog_screen.dart';
import 'package:write_up/src/modules/home_screen/view/home_screen.dart';
import 'package:write_up/src/modules/profile/view/profile_screen.dart';
import 'package:write_up/app/utils/snackbar_utils.dart';
import 'package:write_up/src/modules/auth/model/user_model.dart';
import 'package:write_up/src/modules/home_screen/view/blog_detail_screen.dart';
import 'package:share_plus/share_plus.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BlogService _blogService = BlogService();
  final StorageService _storage = StorageService();
  int _displayCount = 10;

  List<BlogData> _allBlogs = [];
  List<BlogData> _bookmarkedBlogs = [];
  List<String> _bookmarkedIds = [];
  bool _isLoading = true;
  String? _error;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _displayCount = 10;
    });
    try {
      final user = await _storage.getUser();
      final blogs = await _blogService.getAllBlogs();
      final ids = await _storage.getBookmarkedBlogIds();

      if (!mounted) return;

      setState(() {
        _user = user;
        _allBlogs = blogs;
        _bookmarkedIds = ids;
        _filterBookmarkedBlogs();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterBookmarkedBlogs() {
    _bookmarkedBlogs = _allBlogs
        .where((blog) => _bookmarkedIds.contains(blog.id))
        .toList();
  }

  Future<void> _toggleBookmark(String blogId) async {
    await _storage.toggleBookmark(blogId);
    final ids = await _storage.getBookmarkedBlogIds();
    setState(() {
      _bookmarkedIds = ids;
      _filterBookmarkedBlogs();
    });
  }

  Future<void> _handleEdit(BlogData blog) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateBlogScreen(blog: blog)),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _handleDelete(BlogData blog) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Blog',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this blog?',
          style: TextStyle(color: AppColors.forest1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.forest2),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                final token = await _storage.getToken();
                await _blogService.deleteBlog(blog.id!, token: token);
                if (context.mounted) {
                  Navigator.pop(context, true);
                  AppSnackbar.showSuccess(
                    context,
                    message: 'Blog deleted successfully!',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context, false);
                  AppSnackbar.show(
                    context,
                    title: 'Delete Failed',
                    message: e.toString().replaceFirst('Exception: ', ''),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Bookmarks',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _BottomNav(
        selected: 1,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomeScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          } else if (i == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ProfileScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          }
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: _error != null
                    ? _ErrorState(message: _error!, onRetry: _loadData)
                    : _bookmarkedBlogs.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        itemCount:
                            min(_bookmarkedBlogs.length, _displayCount) +
                            (_bookmarkedBlogs.length > _displayCount ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _displayCount) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _displayCount += 10;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forest3,
                                  foregroundColor: AppColors.white,
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Load More'),
                              ),
                            );
                          }
                          final blog = _bookmarkedBlogs[index];
                          final isOwnBlog =
                              _user != null && (blog.authorName == _user!.name);
                          return BlogCard(
                            blog: blog,
                            isBookmarked: true,
                            onBookmarkToggle: () => _toggleBookmark(blog.id!),
                            onShare: () {
                              SharePlus.instance.share(
                                ShareParams(
                                  text:
                                      'Check out this blog: ${blog.title}\n\n${blog.description}',
                                ),
                              );
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BlogDetailScreen(blog: blog),
                                ),
                              );
                            },
                            trailing: isOwnBlog
                                ? PopupMenuButton<String>(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _handleEdit(blog);
                                      } else if (value == 'delete') {
                                        _handleDelete(blog);
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    color: AppColors.forest3,
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: AppColors.forest1,
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/edit-04-stroke-rounded.svg',
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    AppColors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Edit',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/delete-02-stroke-rounded.svg',
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    AppColors.error,
                                                    BlendMode.srcIn,
                                                  ),
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.forest4,
        border: Border(top: BorderSide(color: AppColors.forest3, width: 0.5)),
      ),
      child: Row(
        children: [
          _NavItem(
            assetPath: 'assets/icons/home-03-stroke-rounded.svg',
            label: 'Home',
            selected: selected == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            assetPath: 'assets/icons/bookmark-02-stroke-rounded.svg',
            label: 'Bookmarks',
            selected: selected == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            assetPath: 'assets/icons/user-03-stroke-rounded.svg',
            label: 'Profile',
            selected: selected == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.forest1 : AppColors.forest3;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                assetPath,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                width: 26,
                height: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 56, color: AppColors.forest3),
          const SizedBox(height: 12),
          const Text(
            'No bookmarks yet',
            style: TextStyle(fontSize: 16, color: AppColors.forest2),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 52,
              color: AppColors.forest2,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.forest1, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
