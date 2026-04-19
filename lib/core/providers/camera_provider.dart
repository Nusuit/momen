import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraControllerState {
  const CameraControllerState({
    required this.cameras,
    required this.activeIndex,
    this.controller,
    this.isInitializing = false,
  });

  final List<CameraDescription> cameras;
  final int activeIndex;
  final CameraController? controller;
  final bool isInitializing;

  bool get isReady =>
      controller != null && controller!.value.isInitialized && !isInitializing;

  bool get hasMultipleCameras => cameras.length > 1;

  CameraControllerState copyWith({
    List<CameraDescription>? cameras,
    int? activeIndex,
    CameraController? controller,
    bool? isInitializing,
    bool clearController = false,
  }) {
    return CameraControllerState(
      cameras: cameras ?? this.cameras,
      activeIndex: activeIndex ?? this.activeIndex,
      controller: clearController ? null : (controller ?? this.controller),
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

final cameraControllerProvider =
    NotifierProvider<CameraControllerNotifier, CameraControllerState>(
  CameraControllerNotifier.new,
);

class CameraControllerNotifier extends Notifier<CameraControllerState> {
  CameraController? _activeController;

  @override
  CameraControllerState build() {
    ref.onDispose(_disposeCurrentController);
    _initCamera();
    return const CameraControllerState(
      cameras: [],
      activeIndex: 0,
      isInitializing: true,
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(cameras: cameras, isInitializing: false);
        return;
      }
      await _createController(cameras, state.activeIndex);
    } catch (_) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> _createController(
    List<CameraDescription> cameras,
    int index,
  ) async {
    state = state.copyWith(cameras: cameras, isInitializing: true);
    _disposeCurrentController();

    final controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      _activeController = controller;
      state = state.copyWith(
        cameras: cameras,
        activeIndex: index,
        controller: controller,
        isInitializing: false,
      );
    } catch (_) {
      await controller.dispose();
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> switchCamera() async {
    final cameras = state.cameras;
    if (cameras.length < 2) return;
    final nextIndex = (state.activeIndex + 1) % cameras.length;
    await _createController(cameras, nextIndex);
  }

  void _disposeCurrentController() {
    _activeController?.dispose();
    _activeController = null;
  }
}
