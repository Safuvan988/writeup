import 'dart:math';
import 'package:write_up/app/utils/snackbar_utils.dart';
import 'package:write_up/src/modules/profile/view/profile_screen.dart';
import 'package:write_up/src/modules/home_screen/view/bookmarks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:write_up/app/theme_data/app_colors.dart';
import 'package:write_up/src/app_cards/blog_card.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';
import 'package:write_up/src/modules/home_screen/controller/blog_service.dart';
import 'package:write_up/src/modules/home_screen/view/create_blog_screen.dart';
import 'package:write_up/src/core/services/storage_service.dart';
import 'package:write_up/src/modules/auth/model/user_model.dart';
import 'package:write_up/src/modules/home_screen/view/blog_detail_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BlogService _blogService = BlogService();
  final StorageService _storage = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<BlogData> _blogs = [];
  List<BlogData> _filtered = [];
  List<String> _bookmarkedIds = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;
  User? _user;
  int _displayCount = 8;

  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUser(), _loadCategories(), _loadBlogs()]);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.getCategories();
      if (mounted) {
        setState(() {
          _categories = ['All', ...categories];
          // Ensure "Others" is at the end if it exists
          if (_categories.contains('Others')) {
            _categories.remove('Others');
            _categories.add('Others');
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadUser() async {
    final user = await _storage.getUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final blogs = await _blogService.getAllBlogs(category: _selectedCategory);
      final ids = await _storage.getBookmarkedBlogIds();
      if (!mounted) return;

      setState(() {
        _blogs = blogs;
        _filtered = blogs;
        _bookmarkedIds = ids;

        // Update categories list to strictly match the server enum
        _categories = [
          'All',
          'Tech',
          'Lifestyle',
          'Food',
          'Travel',
          'Health',
          'Business',
          'Fashion',
          'Education',
          'Others',
        ];

        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }

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

  Future<void> _toggleBookmark(String blogId) async {
    await _storage.toggleBookmark(blogId);
    final ids = await _storage.getBookmarkedBlogIds();
    setState(() {
      _bookmarkedIds = ids;
    });
  }

  void _applyFilters() {
    setState(() {
      _displayCount = 8;
      _filtered = _blogs.where((b) {
        final q = _searchController.text.toLowerCase();
        final matchesSearch =
            b.title.toLowerCase().contains(q) ||
            b.description.toLowerCase().contains(q);

        return matchesSearch;
      }).toList();
    });
  }

  void _onSearch(String query) {
    _applyFilters();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _displayCount = 8;
    });
    _loadBlogs();
  }

  Future<void> _handleEdit(BlogData blog) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateBlogScreen(blog: blog)),
    );
    if (result == true) {
      _loadBlogs();
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
      _loadBlogs();
    }
  }

  void _openRandomBlog() {
    if (_blogs.isNotEmpty) {
      final random = Random();
      final blog = _blogs[random.nextInt(_blogs.length)];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BlogDetailScreen(blog: blog)),
      );
    } else {
      AppSnackbar.show(
        context,
        title: 'No Blogs',
        message: 'There are no blogs to pick from!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _BottomNav(
        selected: _selectedTab,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const BookmarksScreen(),
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
          } else {
            setState(() => _selectedTab = i);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBlogScreen()),
          );
          if (result == true) {
            _loadBlogs();
          }
        },
        backgroundColor: AppColors.primary,
        child: SvgPicture.asset(
          'assets/icons/plus-sign-square-stroke-rounded.svg',
          colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
          width: 26,
          height: 26,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Write Up',
                        style: GoogleFonts.texturina(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_user != null)
                        Text(
                          'Hi, ${_user!.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.forest1,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openRandomBlog,
                    tooltip: 'Surprise Me',
                    icon: SvgPicture.asset(
                      'assets/icons/gift-stroke-rounded.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                      width: 26,
                      height: 26,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 15, color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search blogs...',
                  hintStyle: const TextStyle(
                    color: AppColors.forest2,
                    fontSize: 15,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/search-02-stroke-rounded.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.forest2,
                        BlendMode.srcIn,
                      ),
                      width: 20,
                      height: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.forest3,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.forest2,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => _onCategorySelected(category),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.forest1
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.forest1
                              : AppColors.forest3,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.surface
                              : AppColors.forest2,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Blog list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBlogs,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: _error != null
                          ? _ErrorState(message: _error!, onRetry: _loadBlogs)
                          : _filtered.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount:
                                  min(_filtered.length, _displayCount) +
                                  (_filtered.length > _displayCount ? 1 : 0),
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
                                          _displayCount += 8;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forest3,
                                        foregroundColor: AppColors.white,
                                        minimumSize: const Size(
                                          double.infinity,
                                          45,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Load More'),
                                    ),
                                  );
                                }
                                final blog = _filtered[index];
                                final isOwnBlog =
                                    _user != null &&
                                    (blog.authorName == _user!.name);
                                return BlogCard(
                                  blog: blog,
                                  isBookmarked: _bookmarkedIds.contains(
                                    blog.id,
                                  ),
                                  onBookmarkToggle: () =>
                                      _toggleBookmark(blog.id!),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
          ],
        ),
      ),
    );
  }
}

// Bottom navigation

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

// Helpers

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 56, color: AppColors.forest3),
          SizedBox(height: 12),
          Text(
            'No blogs yet',
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
