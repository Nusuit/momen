import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/core/providers/camera_provider.dart';
import 'package:momen/core/utils/spending_parser.dart';
import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/presentation/state/memories_provider.dart';
import 'package:momen/features/feed/domain/entities/captured_post.dart';
import 'package:momen/features/feed/presentation/state/create_post_controller.dart';
import 'dart:io';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({
    required this.onClose,
    required this.showAmountInput,
    this.onSwipeToMemories,
    super.key,
  });

  final VoidCallback onClose;
  final bool showAmountInput;
  final VoidCallback? onSwipeToMemories;

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  static const double _swipeVelocityThreshold = 350;

  bool _isCapturing = false;
  XFile? _capturedPhoto;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isFormattingAmount = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_syncAmountFromCaption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final cameraState = ref.read(cameraControllerProvider);
    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing || _capturedPhoto != null) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() => _capturedPhoto = photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot capture photo. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_capturedPhoto != null || _isCapturing) return;
    await ref.read(cameraControllerProvider.notifier).switchCamera();
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _capturedPhoto != null) return;
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (!mounted || selected == null) return;
      setState(() => _capturedPhoto = selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open gallery. Please try again.')),
      );
    }
  }

  void _retakePhoto() => setState(() => _capturedPhoto = null);

  void _syncAmountFromCaption() {
    if (_isFormattingAmount || _amountController.text.trim().isNotEmpty) return;
    final amounts = SpendingParser.parseVndAmounts(_captionController.text);
    if (amounts.isEmpty) return;
    final suggestion = _formatVndDigits(amounts.last.toString());
    _isFormattingAmount = true;
    _amountController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    _isFormattingAmount = false;
  }

  void _onAmountChanged(String value) {
    if (_isFormattingAmount) return;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final formatted = _formatVndDigits(digits);
    if (value == formatted) return;
    _isFormattingAmount = true;
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingAmount = false;
  }

  String _formatVndDigits(String rawDigits) {
    if (rawDigits.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < rawDigits.length; i++) {
      final reversedIndex = rawDigits.length - i;
      buffer.write(rawDigits[i]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  int? _parseAmountVnd(String rawAmount) {
    final digits = rawAmount.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _submitPost() async {
    final photo = _capturedPhoto;
    if (photo == null) return;

    final caption = _captionController.text.trim();
    final amountVnd = _parseAmountVnd(_amountController.text.trim());
    final post = CapturedPost(
      imageLocalPath: photo.path,
      caption: caption,
      amountVnd: amountVnd,
    );
    final pendingPostsNotifier = ref.read(pendingPostsProvider.notifier);
    final createPostController = ref.read(createPostControllerProvider.notifier);

    // Add optimistic pending post immediately so the user sees it right away
    final tempId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    pendingPostsNotifier.add(MemoryPost(
      id: tempId,
      imageUrl: photo.path,
      caption: caption,
      amountVnd: amountVnd,
      createdAt: DateTime.now(),
      ownerId: '',
      isPending: true,
    ));

    // Navigate away immediately — upload happens in background
    widget.onClose();

    try {
      await createPostController.createPost(post);
      // remove() also invalidates memoriesProvider + memoryCountProvider
      pendingPostsNotifier.remove(tempId);
    } catch (error) {
      pendingPostsNotifier.markFailed(tempId);
    }
  }

  void _handleBack() {
    if (_capturedPhoto != null) {
      _retakePhoto();
      return;
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCapturedPhoto = _capturedPhoto != null;
    final postState = ref.watch(createPostControllerProvider);
    final isSubmitting = postState.isSubmitting;
    final cameraState = ref.watch(cameraControllerProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (_capturedPhoto != null || isSubmitting) return;
        final vx = details.primaryVelocity ?? 0;
        if (vx <= -_swipeVelocityThreshold) widget.onSwipeToMemories?.call();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p8,
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.r28),
                    border: Border.all(color: colorScheme.outline),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.r28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!hasCapturedPhoto)
                          _CameraPreviewView(
                            cameraState: cameraState,
                          )
                        else
                          Image.file(
                            File(_capturedPhoto!.path),
                            fit: BoxFit.cover,
                          ),
                        Positioned(
                          top: AppSizes.p12,
                          left: AppSizes.p12,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              key: const Key('camera_close_button'),
                              onPressed: _handleBack,
                              icon: const Icon(Icons.close),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!hasCapturedPhoto)
                          Positioned(
                            top: AppSizes.p12,
                            right: AppSizes.p12,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                key: const Key('camera_switch_button'),
                                onPressed: cameraState.hasMultipleCameras &&
                                        !cameraState.isInitializing
                                    ? _switchCamera
                                    : null,
                                icon: const Icon(Icons.flip_camera_ios),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (hasCapturedPhoto)
                          Positioned(
                            left: AppSizes.p12,
                            right: AppSizes.p12,
                            bottom: AppSizes.p12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p12,
                                vertical: AppSizes.p8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(AppSizes.r16),
                              ),
                              child: TextField(
                                key: const Key('camera_caption_overlay_field'),
                                controller: _captionController,
                                minLines: 1,
                                maxLines: 2,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Write a caption...',
                                  hintStyle: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        if (_isCapturing)
                          const ColoredBox(
                            color: Color(0x88000000),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              if (!hasCapturedPhoto)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      key: const Key('camera_gallery_button'),
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                    ),
                    FilledButton(
                      key: const Key('camera_capture_button'),
                      onPressed: cameraState.isReady ? _capturePhoto : null,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(AppSizes.p24),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Icon(Icons.circle),
                    ),
                    const SizedBox(width: AppSizes.i32),
                  ],
                )
              else
                _CapturedPreviewActions(
                  showAmountInput: widget.showAmountInput,
                  amountController: _amountController,
                  onAmountChanged: _onAmountChanged,
                  onRetake: _retakePhoto,
                  onSubmit: _submitPost,
                  isSubmitting: false,
                  submitProgress: postState.progress,
                  submitMessage: postState.message,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraPreviewView extends StatelessWidget {
  const _CameraPreviewView({required this.cameraState});

  final CameraControllerState cameraState;

  @override
  Widget build(BuildContext context) {
    if (cameraState.isInitializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.camera_alt, color: Colors.white70, size: 72),
        ),
      );
    }

    return CameraPreview(controller);
  }
}

class _CapturedPreviewActions extends StatelessWidget {
  const _CapturedPreviewActions({
    required this.showAmountInput,
    required this.amountController,
    required this.onAmountChanged,
    required this.onRetake,
    required this.onSubmit,
    required this.isSubmitting,
    required this.submitProgress,
    required this.submitMessage,
  });

  final bool showAmountInput;
  final TextEditingController amountController;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onRetake;
  final Future<void> Function() onSubmit;
  final bool isSubmitting;
  final double submitProgress;
  final String submitMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('camera_post_capture_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAmountInput) ...[
            TextField(
              key: const Key('camera_amount_field'),
              controller: amountController,
              enabled: !isSubmitting,
              onChanged: onAmountChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (VND)',
                hintText: 'Enter amount spent',
              ),
            ),
            const SizedBox(height: AppSizes.p12),
          ],
          Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: FilledButton(
                  key: const Key('camera_retake_button'),
                  onPressed: isSubmitting ? null : onRetake,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 88,
                height: 88,
                child: FilledButton(
                  key: const Key('camera_submit_button'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: isSubmitting ? null : onSubmit,
                  child: const Icon(Icons.arrow_forward_rounded, size: 52),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 42, height: 42),
            ],
          ),
        ],
      ),
    );
  }
}
