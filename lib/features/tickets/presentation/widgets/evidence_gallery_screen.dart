import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class EvidenceGalleryScreen extends StatefulWidget {
  final List<ImageProvider> imageProviders;
  final int initialIndex;
  final bool isEditing;
  final ValueChanged<int>? onDelete;

  const EvidenceGalleryScreen({
    super.key,
    required this.imageProviders,
    required this.isEditing,
    this.onDelete,
    this.initialIndex = 0,
  });

  @override
  State<EvidenceGalleryScreen> createState() => _EvidenceGalleryScreenState();
}

class _EvidenceGalleryScreenState extends State<EvidenceGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<ImageProvider> _imageProviders;

  @override
  void initState() {
    super.initState();
    _imageProviders = List.of(widget.imageProviders);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < _imageProviders.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _deleteCurrentImage() {
    if (!widget.isEditing || widget.onDelete == null) return;

    widget.onDelete!(_currentIndex);
    if (_imageProviders.length == 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _imageProviders.removeAt(_currentIndex);
      if (_currentIndex >= _imageProviders.length) {
        _currentIndex = _imageProviders.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProviders.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: _imageProviders[index],
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: _imageProviders[index],
                  ),
                );
              },
              itemCount: _imageProviders.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),

            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: Icon(Icons.close, color: AppColors.primaryLight),
                  ),

                  Text(
                    'Image ${_currentIndex + 1} of ${_imageProviders.length}',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 16,
                    ),
                  ),

                  IconButton(
                    onPressed: widget.isEditing && widget.onDelete != null
                        ? _deleteCurrentImage
                        : null,
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentIndex > 0 ? _goToPrevious : null,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2D),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1E1E20),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: _currentIndex < _imageProviders.length - 1
                        ? _goToNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0D47A1,
                      ), // Blue pill style
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1E1E20),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
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
