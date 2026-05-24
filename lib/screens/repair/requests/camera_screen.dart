import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:Delta/provider/app_provider.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraWorking extends StatefulWidget {
  const CameraWorking({super.key});

  @override
  State<CameraWorking> createState() => _CameraWorkingState();
}

class _CameraWorkingState extends State<CameraWorking> {
  List<String> allImages = [];
  int photoCounter = 1;
  int videoCounter = 1;

  // Video recording state
  bool isRecording = false;
  int recordingSeconds = 0;
  Timer? recordingTimer;
  final int maxRecordingSeconds = 15;
  bool permissionsGranted = false;

  // Mode state
  bool isVideoMode = false;
  final Key _cameraKey = UniqueKey();

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      setState(() {
        permissionsGranted = true;
      });
    }
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecordingTimer(CameraState state) {
    setState(() {
      isRecording = true;
      recordingSeconds = 0;
    });

    recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        recordingSeconds++;
      });

      // Stop recording after 15 seconds
      if (recordingSeconds >= maxRecordingSeconds) {
        _stopRecording(state);
      }
    });
  }

  void _stopRecording(CameraState state) {
    recordingTimer?.cancel();
    state.when(
      onVideoRecordingMode: (videoState) {
        videoState.stopRecording();
      },
    );

    setState(() {
      isRecording = false;
      recordingSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final myImagesProv = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          KeyedSubtree(
            key: _cameraKey,
            child: CameraAwesomeBuilder.awesome(
              saveConfig: SaveConfig.photoAndVideo(
                initialCaptureMode: isVideoMode
                    ? CaptureMode.video
                    : CaptureMode.photo,
                videoOptions: VideoOptions(
                  enableAudio: Platform.isAndroid,
                  quality: VideoRecordingQuality.fhd,
                ),
              ),
              onMediaCaptureEvent: (MediaCapture capture) async {
                SharedPreferences prefx = await SharedPreferences.getInstance();
                final file = File(capture.captureRequest.path!);

                if (await file.exists() && mounted) {
                  final isVideo = capture.captureRequest.path!.contains(
                    'video_',
                  );

                  debugPrint(
                    '📸 ${isVideo ? "Video" : "Photo"} captured: ${file.path}',
                  );
                  myImagesProv.getMyImages(file.path);
                  setState(() {
                    if (isVideo) {
                      videoCounter++;
                    } else {
                      photoCounter++;
                    }
                  });

                  // Show success feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isVideo
                            ? 'تم تسجيل الفيديو ${myImagesProv.allImagesList.where((p) => p.contains('video_')).length} ✅'
                            : 'تم التقاط الصورة ${myImagesProv.allImagesList.where((p) => p.contains('photo_')).length} ✅',
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              bottomActionsBuilder: (state) {
                return _buildBottomActions(state);
              },
              topActionsBuilder: (state) {
                return _buildTopActions(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActions(CameraState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button (hidden during recording)
            if (!isRecording)
              IconButton(
                onPressed: () {
                  Navigator.pop(context, allImages);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.arrow_left_3,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
            else
              SizedBox(width: 48),

            // Visit info (hidden during recording)
            if (!isRecording)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.camera, color: Colors.white, size: 26),
                  ],
                ),
              )
            else
              SizedBox(width: 100),

            // Photos counter (hidden during recording)
            if (allImages.isNotEmpty && !isRecording)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${allImages.length}',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(CameraState state) {
    return Consumer<AppProvider>(
      builder: (context, app, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Left: Flip camera OR Gallery (photo mode)
                    GestureDetector(
                      onTap: app.allImagesList.isNotEmpty ? _showGallery : null,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: app.allImagesList.isNotEmpty
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: app.allImagesList.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    _buildMediaPreview(app.allImagesList.last),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${app.allImagesList.length}',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Icon(
                                Iconsax.gallery,
                                color: Colors.white.withOpacity(0.5),
                                size: 24,
                              ),
                      ),
                    ),

                    // Center: Capture button
                    state.when(
                      onPhotoMode: (photoState) =>
                          AwesomeCaptureButton(state: state),
                      onVideoMode: (videoState) => GestureDetector(
                        onTap: () {
                          videoState.startRecording();
                          _startRecordingTimer(state);
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      onVideoRecordingMode: (recordingState) => GestureDetector(
                        onTap: () => _stopRecording(state),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      onPreparingCamera: (_) => SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                    Consumer<AppProvider>(
                      builder: (context, app, child) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: app.allImagesList.isNotEmpty
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.tick_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview(String path) {
    final isVideo = path.contains('video_');

    if (isVideo) {
      return Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: Icon(Iconsax.video_play, color: Colors.white, size: 30),
            ),
          ),
        ],
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  void _showGallery() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Consumer<AppProvider>(
          builder: (context, app, child) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'الملفات المُلتقطة (${app.allImagesList.length})',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Iconsax.close_circle),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: app.allImagesList.length,
                    itemBuilder: (context, index) {
                      final isVideo = app.allImagesList[index].contains(
                        'video_',
                      );

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            _buildMediaPreview(app.allImagesList[index]),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isVideo ? Iconsax.video : Iconsax.camera,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVideo
                                          ? 'فيديو ${index + 1}'
                                          : 'صورة ${index + 1}',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
