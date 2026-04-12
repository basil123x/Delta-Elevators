import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OrderPlaying extends StatefulWidget {
  final String bookId;
  const OrderPlaying({super.key, required this.bookId});

  @override
  State<OrderPlaying> createState() => _OrderPlayingState();
}

class _OrderPlayingState extends State<OrderPlaying> {
  
  String get videoUrl =>
      "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/Processing/${widget.bookId}/playing/1.mp4";

  void _openVideoPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openVideoPlayer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(7),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                // thumbnail من أول فريم - لو مش شغال هيظهر أيقونة فيديو
                videoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.video_file,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // أيقونة play فوق الـ thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ── شاشة الـ Video Player ──────────────────────────────
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _videoController.initialize().then((_) {
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowMuting: false, // ← الصوت مفتوح دايمًا
        showControls: true,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}