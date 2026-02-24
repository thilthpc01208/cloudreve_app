import 'package:cloudreve_view/common/api.dart';
import 'package:cloudreve_view/common/constants.dart';
import 'package:cloudreve_view/common/util.dart';
import 'package:cloudreve_view/controller.dart';
import 'package:cloudreve_view/entity/file.dart';
import 'package:cloudreve_view/page/preview_pic_page.dart';
import 'package:cloudreve_view/page/preview_video_page.dart';
import 'package:cloudreve_view/widget/common/main_drawser.dart';
import 'package:cloudreve_view/widget/file/file_grid_view.dart';
import 'package:cloudreve_view/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  Controller controller = Get.find<Controller>();
  int _backCount = 0;
  List<String> path = [];

  void goPath(String name) {
    path.add("/$name");
  }

  void backPath() {
    if (path.isNotEmpty) {
      path.removeLast();
    }
  }

  String _tr(String key, String fallback, {Map<String, String> params = const {}}) {
    return controller.trCloudreve(
      key,
      fallback: fallback,
      params: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.user == null) {
      Future.microtask(() {
        Navigator.pushNamed(context, "/login");
      });
      return Container();
    }

    return Obx(() {
      controller.cloudreveI18n.length;
      final l10n = AppLocalizations.of(context)!;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            if (path.isEmpty) {
              _backCount++;
              if (_backCount >= 2) SystemNavigator.pop();

              Util.showSnackbar(
                context: context,
                message: _tr('common.pressAgainToExit', l10n.confirmExit),
              );

              Future.delayed(const Duration(seconds: 2), () {
                _backCount = 0;
              });
            } else {
              setState(() {
                backPath();
              });
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_tr('navbar.myFiles', l10n.mainPageTitle)),
          ),
          drawer: MainDrawser(user: controller.user!),
          body: Column(
            children: [
              Row(),
              FutureBuilder(
                key: ValueKey<String>(path.join()),
                future: Api().directory(path: path.join()),
                builder: (context, builder) {
                  if (builder.hasData && builder.data!.data['code'] == 0) {
                    final rawData = (builder.data!.data['data'] as Map?)
                            ?.cast<String, dynamic>() ??
                        <String, dynamic>{};
                    final rawFiles =
                        (rawData['files'] ?? rawData['objects'] ?? const []) as List;

                    List<File> fileList = rawFiles
                        .whereType<Map>()
                        .map((file) => File.fromMap(file.cast<String, dynamic>()))
                        .toList();

                    List<File> picList = fileList.where((file) {
                      if (file.type == Constants.fileType["dir"]) return false;
                      final suffix = file.name.split(".").last.toLowerCase();
                      return Constants.canPrePicSet.contains(suffix);
                    }).toList();

                    return Expanded(
                      child: FileGridView(
                        fileList: fileList,
                        onDoubleTap: (File file) {
                          if (file.type == Constants.fileType["dir"]) {
                            setState(() {
                              goPath(file.name);
                            });
                          } else if (Constants.canPrePicSet
                              .contains(file.name.split(".").last.toLowerCase())) {
                            int index = picList.indexOf(file);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PreviewPicPage(
                                  list: picList,
                                  currentIndex: index,
                                ),
                              ),
                            );
                          } else if (Constants.canPreVideoSet
                              .contains(file.name.split(".").last.toLowerCase())) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PreviewVideoPage(file: file),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }

                  return Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).highlightColor,
                        value: null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
