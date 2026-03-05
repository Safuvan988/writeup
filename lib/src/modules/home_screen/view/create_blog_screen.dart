import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:write_up/app/theme_data/app_colors.dart';
import 'package:write_up/app/utils/snackbar_utils.dart';
import 'package:write_up/src/core/services/upload_service.dart';
import 'package:write_up/src/core/services/storage_service.dart';
import 'package:write_up/src/modules/home_screen/controller/blog_service.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';

class CreateBlogScreen extends StatefulWidget {
  final BlogData? blog;
  const CreateBlogScreen({super.key, this.blog});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _categories = [
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
  String? _selectedCategory;
  final TextEditingController _customCategoryController =
      TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final _blogService = BlogService();
  final _uploadService = UploadService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  bool get isEditing => widget.blog != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    _initBlogData();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.getCategories();
      if (mounted && categories.isNotEmpty) {
        setState(() {
          _categories = categories;
          if (!_categories.contains('Others')) {
            _categories.add('Others');
          }

          // Re-validate selection after categories load
          if (_selectedCategory == null ||
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = _categories.contains('Others')
                ? 'Others'
                : _categories.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  void _initBlogData() {
    if (widget.blog != null) {
      _titleController.text = widget.blog!.title;
      _descriptionController.text = widget.blog!.description;

      // Map existing category or first tag to current categories
      String existingCategory = 'Others';
      if (widget.blog!.category != 'Others' &&
          _categories.contains(widget.blog!.category)) {
        existingCategory = widget.blog!.category;
      } else if (widget.blog!.tags.isNotEmpty) {
        final firstTag = widget.blog!.tags.first.replaceAll('#', '').trim();
        // Try to match capitalized tag to enum
        final capitalized = firstTag.isNotEmpty
            ? firstTag[0].toUpperCase() + firstTag.substring(1).toLowerCase()
            : '';

        if (_categories.contains(capitalized)) {
          existingCategory = capitalized;
        } else if (capitalized == 'Technology') {
          existingCategory = 'Tech';
        }
      }

      _selectedCategory = existingCategory;
      _uploadedImageUrl = widget.blog!.image;
    } else {
      _selectedCategory = _categories.contains('Others')
          ? 'Others'
          : _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedImageUrl = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);
    try {
      final token = await _storage.getToken();
      final url = await _uploadService.uploadSingleImage(
        _selectedImage!,
        token: token,
      );
      if (url != null) {
        setState(() => _uploadedImageUrl = url);
        if (mounted) {
          AppSnackbar.showSuccess(
            context,
            message: 'Image uploaded successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: 'Upload Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitBlog() async {
    if (!_formKey.currentState!.validate()) return;

    // Image is required
    if (_selectedImage == null && _uploadedImageUrl == null) {
      AppSnackbar.show(
        context,
        title: 'Image Required',
        message: 'Please select and upload a cover image.',
      );
      return;
    }

    // Auto-upload if image picked but not yet uploaded
    if (_selectedImage != null && _uploadedImageUrl == null) {
      await _uploadImage();
      if (_uploadedImageUrl == null) return; // upload failed
    }

    setState(() => _isSubmitting = true);
    try {
      final String finalCategory = _selectedCategory ?? 'Others';

      final List<String> tags = <String>[];
      // We still add the category as a tag for backward compatibility or UI filtering if needed
      tags.add('#${finalCategory.toLowerCase()}');

      // Parse extra tags from the text field
      final extraTagsText = _tagsController.text.trim();
      if (extraTagsText.isNotEmpty) {
        final parsedTags = extraTagsText
            .split(',')
            .map((t) {
              final trimmed = t.trim().toLowerCase();
              return trimmed.startsWith('#') ? trimmed : '#$trimmed';
            })
            .where((t) => t.length > 1)
            .toList();
        tags.addAll(parsedTags);
      }

      final request = BlogRequestModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: tags,
        category: finalCategory,
        image: _uploadedImageUrl,
      );

      final token = await _storage.getToken();

      if (isEditing) {
        await _blogService.updateBlog(widget.blog!.id!, request, token: token);
      } else {
        await _blogService.createBlog(request, token: token);
      }

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          message: isEditing
              ? 'Blog updated successfully!'
              : 'Blog created successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: isEditing ? 'Update Failed' : 'Creation Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Blog' : 'Create Blog',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.forest3, width: 1.5),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : (_uploadedImageUrl != null &&
                                _uploadedImageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _uploadedImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: AppColors.forest2,
                                        ),
                                      ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: AppColors.forest2,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Select Cover Image',
                                    style: TextStyle(color: AppColors.forest2),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 12),

              if (_selectedImage != null && _uploadedImageUrl == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadImage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 22),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest3,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

              if (_uploadedImageUrl != null &&
                  _selectedImage == null &&
                  isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: SvgPicture.asset(
                      'assets/icons/license-draft-stroke-rounded.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.forest2,
                        BlendMode.srcIn,
                      ),
                      width: 18,
                      height: 18,
                    ),
                    label: const Text(
                      'Change Image',
                      style: TextStyle(color: AppColors.forest2),
                    ),
                  ),
                ),

              if (_uploadedImageUrl != null &&
                  (_selectedImage == null || _uploadedImageUrl != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/checkmark-square-03-stroke-rounded.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.forest1,
                          BlendMode.srcIn,
                        ),
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing && _selectedImage == null
                            ? 'Current image'
                            : 'Image Uploaded',
                        style: const TextStyle(
                          color: AppColors.forest2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Title*',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest1,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hintText: 'Enter blog title',
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Description*',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest1,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Write your content here...',
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                minLines: 6,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Category*',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest1,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    if (newValue != 'Other (Custom)') {
                      _customCategoryController.clear();
                    }
                  });
                },
                validator: (v) => v == null ? 'Category is required' : null,
              ),
              if (_selectedCategory == 'Other (Custom)') ...[
                const SizedBox(height: 16),
                const Text(
                  'Custom Category Name*',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _customCategoryController,
                  hintText: 'Enter custom category (e.g. Finance)',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Custom category name is required'
                      : null,
                ),
              ],
              const SizedBox(height: 16),

              const Text(
                'Tags (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest1,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _tagsController,
                hintText: 'Enter tags separated by commas (e.g. tech, coding)',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isUploading)
                      ? null
                      : _submitBlog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest3,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : Text(
                          isEditing ? 'Update Blog' : 'Publish Blog',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int? maxLines = 1,
    int? minLines,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.forest2),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest3, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest2, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
