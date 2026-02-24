import 'dart:async';

import 'package:cloudreve_view/common/api.dart';
import 'package:cloudreve_view/common/util.dart';
import 'package:cloudreve_view/controller.dart';
import 'package:cloudreve_view/entity/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cloudreve_view/l10n/app_localizations.dart';

class PreviewVideoPage extends StatefulWidget {
  final File file;

  const PreviewVideoPage({super.key, required this.file});
  @override
  State<StatefulWidget> createState() {
    return _previewVideoPageState();
  }
}

class _previewVideoPageState extends State<PreviewVideoPage>
    with TickerProviderStateMixin {
  final Controller _controller = Get.find<Controller>();
  VideoPlayerController? videoPlayerController;
  PersistentBottomSheetController? bottomSheetController;
  AnimationController? topSheetController;
  var isPlaying = false.obs;
  var isFullScreen = false.obs;
  int volume = 100;
  int progress = 0;
  Timer? timer;
  var position = Duration.zero.obs;
  var duration = Duration.zero.obs;

  void closeBottomSheet() {
    timer?.cancel();
    if (bottomSheetController != null) {
      bottomSheetController!.close();
    }
    bottomSheetController = null;
    if (topSheetController != null) {
      topSheetController!.reverse();
    }
    topSheetController = null;
  }

  void resetTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 3), closeBottomSheet);
  }

  @override
  void dispose() {
    videoPlayerController?.removeListener(playerChange);
    videoPlayerController?.dispose();
    SystemChrome.setSystemUIChangeCallback(null);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    if (isFullScreen.value) exitFullscreen();
    super.dispose();
  }

  void playerChange() {
    if (videoPlayerController == null) return;

    if (videoPlayerController!.value.isPlaying) {
      position.value = videoPlayerController!.value.position;
    } else {
      resetTimer();
    }
    if (videoPlayerController!.value.isInitialized) {
      duration.value = videoPlayerController!.value.duration;
    }
  }

  void fullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  String _tr(String key, String fallback, {Map<String, String> params = const {}}) {
    return _controller.trCloudreve(
      key,
      fallback: fallback,
      params: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (videoPlayerController == null) {
      Api().getPreviewFileUrl(widget.file).then((resp) {
        if (mounted && resp.isNotEmpty) {
          setState(() {
            videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(resp));
            videoPlayerController!.addListener(playerChange);
          });
        }
      });
    }

    SystemChrome.setSystemUIChangeCallback((data) {
      if (mounted) {
        isFullScreen.value = !data;
      }
      return Future.value();
    });

    return Obx(() {
      _controller.cloudreveI18n.length;
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: Colors.black,
        body: videoPlayerController == null
            ? Column(
                children: [
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(value: null),
                    ),
                  ),
                  Expanded(child: Text(_tr('fileManager.preparingOpenFile', l10n.parsingLink)))
                ],
              )
            : FutureBuilder(
                future: videoPlayerController!.initialize(),
                builder: (context, builder) {
                if (builder.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      if (isFullScreen.value) {
                        print("Slide ${details.localPosition}");
                      }
                      resetTimer();
                    },
                    onDoubleTap: () {
                      if (isPlaying.value) {
                        videoPlayerController!.pause();
                        isPlaying.value = false;
                      } else {
                        videoPlayerController!.play();
                        isPlaying.value = true;
                      }
                    },
                    onTap: () {
                      if (bottomSheetController == null) {
                        timer = Timer(const Duration(seconds: 3), closeBottomSheet);
                        bottomSheetController = showBottomSheet(
                          context: context,
                          builder: (context) {
                            return Obx(() {
                              return Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (isPlaying.value) {
                                        videoPlayerController!.pause();
                                        isPlaying.value = false;
                                      } else {
                                        videoPlayerController!.play();
                                        isPlaying.value = true;
                                      }
                                    },
                                    icon: isPlaying.value
                                        ? const Icon(Icons.pause_circle, size: 40)
                                        : const Icon(Icons.play_circle, size: 40),
                                  ),
                                  Expanded(
                                    child: VideoProgressIndicator(
                                      videoPlayerController!,
                                      allowScrubbing: true,
                                    ),
                                  ),
                                  Obx(() {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                      child: Text(
                                        "${position.toString().split('.').first}/${duration.toString().split('.').first}",
                                      ),
                                    );
                                  }),
                                  Obx(() {
                                    return IconButton(
                                      onPressed: () {
                                        if (isFullScreen.value) {
                                          exitFullscreen();
                                        } else {
                                          fullscreen();
                                        }
                                      },
                                      icon: Icon(
                                        isFullScreen.value
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                        size: 40,
                                      ),
                                    );
                                  })
                                ],
                              );
                            });
                          },
                        );
                        topSheetController = Util.showTopSheet(
                          context: context,
                          vsync: this,
                          child: AppBar(title: Text(widget.file.name)),
                        );
                      } else {
                        closeBottomSheet();
                      }
                    },
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(videoPlayerController!),
                      ),
                    ),
                  );
                }

                  return Column(
                    children: [
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(value: null),
                        ),
                      ),
                      Expanded(child: Text(_tr('fileManager.preparingOpenFile', l10n.videoLoading)))
                    ],
                  );
                },
              ),
      );
    });
  }
}
