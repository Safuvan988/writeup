import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:write_up/app/theme_data/app_colors.dart';
import 'package:write_up/src/app_cards/blog_card.dart';
import 'package:write_up/src/modules/home_screen/controller/blog_service.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';
import 'package:write_up/app/utils/snackbar_utils.dart';
import 'package:write_up/src/modules/home_screen/view/home_screen.dart';
import 'package:write_up/src/modules/home_screen/view/blog_detail_screen.dart';
import 'package:write_up/src/modules/home_screen/view/create_blog_screen.dart';
import 'package:write_up/src/modules/home_screen/view/bookmarks_screen.dart';
import 'package:write_up/src/core/services/storage_service.dart';
import 'package:write_up/src/modules/auth/model/user_model.dart';
import 'package:write_up/src/modules/auth/view/login_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BlogService _blogService = BlogService();
  final StorageService _storage = StorageService();
  List<BlogData> _blogs = [];
  List<String> _bookmarkedIds = [];
  bool _isLoading = true;
  String? _error;
  int _displayCount = 10;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUser();
    await _loadBlogs();
  }

  Future<void> _loadUser() async {
    final user = await _storage.getUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _loadBlogs() async {
    try {
      final token = await _storage.getToken();
      final blogs = await _blogService.getMyBlogs(token: token);
      final bookmarkedIds = await _storage.getBookmarkedBlogIds();

      if (!mounted) return;
      setState(() {
        _blogs = blogs;
        _bookmarkedIds = bookmarkedIds;
        _isLoading = false;
        _displayCount = 10;
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
    if (!mounted) return;
    setState(() {
      _bookmarkedIds = ids;
    });
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
    await showDialog<bool>(
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
                  _loadBlogs();
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
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _user?.name ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.forest2),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.forest1,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: AppColors.forest2),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.forest3,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.forest2,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;
                  final updatedUser = User(
                    id: _user?.id ?? '',
                    name: newName,
                    email: _user?.email ?? '',
                  );
                  await _storage.saveUser(updatedUser);

                  if (!mounted) return;
                  setState(() => _user = updatedUser);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }

                  if (context.mounted) {
                    AppSnackbar.showSuccess(
                      context,
                      message: 'Profile updated!',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest3,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.forest2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _BottomNav(
        selected: 2,
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
          } else if (i == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const BookmarksScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          }
        },
      ),
      body: RefreshIndicator(
        color: AppColors.forest2,
        backgroundColor: AppColors.surface,
        onRefresh: _loadBlogs,
        child: CustomScrollView(
          slivers: [
            // Sliver App Bar
            SliverAppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              pinned: true,
              centerTitle: true,
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar ring
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.forest3, width: 2.5),
                      color: AppColors.surface,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/user-03-stroke-rounded.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.forest2,
                        BlendMode.srcIn,
                      ),
                      width: 44,
                      height: 44,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    (_user?.name == null || _user!.name.isEmpty)
                        ? 'User'
                        : _user!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email != null
                        ? '@${_user!.email.split('@')[0]}'
                        : '@user',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.forest2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat('Posts', _blogs.length.toString()),
                      const SizedBox(width: 40),
                      _buildStat('Followers', '1.2k'),
                      const SizedBox(width: 40),
                      _buildStat('Following', '850'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Edit Profile Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _showEditProfileSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest3,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final bool?
                          confirm = await showModalBottomSheet<bool>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppColors.forest3.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                28,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon badge
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/icons/logout-01-stroke-rounded.svg',
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.error,
                                        BlendMode.srcIn,
                                      ),
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Are you sure you want to log out?\nYou\'ll need to sign in again to continue.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.forest2,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  // Logout button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: AppColors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Yes, Log Out',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Cancel button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.forest2,
                                        side: BorderSide(
                                          color: AppColors.forest3.withValues(
                                            alpha: 0.6,
                                          ),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (confirm == true) {
                            await _storage.clearAll();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/logout-01-stroke-rounded.svg',
                          colorFilter: const ColorFilter.mode(
                            AppColors.error,
                            BlendMode.srcIn,
                          ),
                          width: 18,
                          height: 18,
                        ),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // My Blogs Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Blogs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    color: AppColors.forest3,
                    thickness: 1,
                    height: 1,
                  ),
                ],
              ),
            ),

            // Blogs List (Sliver View)
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.forest2),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.forest1),
                  ),
                ),
              )
            else if (_blogs.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No blogs yet',
                    style: TextStyle(color: AppColors.forest2),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == min(_blogs.length, _displayCount)) {
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
                      final blog = _blogs[index];
                      return BlogCard(
                        blog: blog,
                        isBookmarked: _bookmarkedIds.contains(blog.id),
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
                        trailing: PopupMenuButton<String>(
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
                                    colorFilter: const ColorFilter.mode(
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
                                    colorFilter: const ColorFilter.mode(
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
                        ),
                      );
                    },
                    childCount:
                        min(_blogs.length, _displayCount) +
                        (_blogs.length > _displayCount ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────

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
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
