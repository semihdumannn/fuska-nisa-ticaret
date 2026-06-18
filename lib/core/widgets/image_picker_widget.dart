import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// ImagePickerWidget
// Gorsel sec → Firebase Storage'a yukle → URL callback
// ---------------------------------------------------------------------------
class ImagePickerWidget extends ConsumerStatefulWidget {
  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
    this.size = 200,
  });

  final String? initialImageUrl;
  final void Function(String imageUrl) onImageUploaded;
  final double size;

  @override
  ConsumerState<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends ConsumerState<ImagePickerWidget> {
  String? _currentImageUrl;
  File? _localFile;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  // -----------------------------------------------------------------------
  // Kaynak sec bottom sheet
  // -----------------------------------------------------------------------
  Future<void> _showSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SourcePickerSheet(
        onCamera: () {
          Navigator.of(ctx).pop();
          _pickAndProcess(ImageSource.camera);
        },
        onGallery: () {
          Navigator.of(ctx).pop();
          _pickAndProcess(ImageSource.gallery);
        },
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Gorsel sec, sikistir, yukle
  // -----------------------------------------------------------------------
  Future<void> _pickAndProcess(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (picked == null) return;

      final file = File(picked.path);

      // Upload öncesi sıkıştır: max 800px, %85 kalite → ~70-80% boyut tasarrufu
      final compressedPath =
          '${file.parent.path}/compressed_${file.uri.pathSegments.last}';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        compressedPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );
      final uploadFile = compressed != null ? File(compressed.path) : file;

      if (!mounted) return;
      setState(() {
        _localFile = file;
        _isUploading = true;
        _uploadProgress = 0;
      });

      final url = await _uploadToStorage(uploadFile);

      if (mounted) {
        setState(() {
          _currentImageUrl = url;
          _isUploading = false;
        });
        widget.onImageUploaded(url);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError(e.toString());
      }
    }
  }

  // -----------------------------------------------------------------------
  // Firebase Storage upload
  // -----------------------------------------------------------------------
  Future<String> _uploadToStorage(File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = file.path.split('.').last;
    final fileName = '${timestamp}_product.$ext';
    final ref = FirebaseStorage.instance.ref('products/$fileName');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );

    task.snapshotEvents.listen((snapshot) {
      if (mounted && snapshot.totalBytes > 0) {
        setState(() {
          _uploadProgress =
              snapshot.bytesTransferred / snapshot.totalBytes;
        });
      }
    });

    await task;
    return await ref.getDownloadURL();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Görsel yüklenemedi: $message',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _showSourcePicker,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            _buildImageContainer(),
            if (_isUploading) _buildUploadOverlay(),
            if (!_isUploading && _hasImage()) _buildEditBadge(),
          ],
        ),
      ),
    );
  }

  bool _hasImage() => _currentImageUrl != null || _localFile != null;

  Widget _buildImageContainer() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.imageBg,
        border: _hasImage()
            ? null
            : Border.all(
                color: AppColors.primary,
                width: 2,
                style: BorderStyle.solid,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    // Yerel dosya secilmis
    if (_localFile != null) {
      return Image.file(
        _localFile!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      );
    }

    // Firebase URL
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: widget.size * 0.22,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'Fotograf Ekle',
          style: TextStyle(
            fontSize: widget.size * 0.07,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black54,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                color: AppColors.textWhite,
                strokeWidth: 3,
              ),
            ),
            if (_uploadProgress > 0) ...[
              const SizedBox(height: 8),
              Text(
                '%${(_uploadProgress * 100).toInt()}',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.edit_outlined,
          color: AppColors.textWhite,
          size: 16,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kaynak secim bottom sheet
// ---------------------------------------------------------------------------
class _SourcePickerSheet extends StatelessWidget {
  const _SourcePickerSheet({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotograf Sec',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Kamera',
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Galeriden',
                  onTap: onGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
