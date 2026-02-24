// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloudreve_view/common/util.dart';
import 'package:cloudreve_view/controller.dart';
import 'package:cloudreve_view/entity/user.dart';
import 'package:flutter/material.dart';
import 'package:cloudreve_view/l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'user_cart.dart';

class MainDrawser extends StatefulWidget {
  final User user;

  const MainDrawser({super.key, required this.user});
  
  @override
  State<StatefulWidget> createState() {
    return _MainDrawserState();
  }
}

class _MainDrawserState extends State<MainDrawser>{
  @override
  Widget build(BuildContext context) {
    return Drawer(
      surfaceTintColor: Colors.white,
      child: Container(
        color: Theme.of(context).primaryColor,
        child: SafeArea(
          child: Column(
            children: [UserCart(user: widget.user), const Expanded(child: DrawerList())],
          ),
        ),
      ),
    );
  }
}

class DrawerList extends StatelessWidget {
  const DrawerList({super.key});

  String _trAny(Controller controller, List<String> keys, String fallback) {
    return controller.trCloudreveAny(keys, fallback: fallback);
  }

  @override
  Widget build(BuildContext context) {
    Controller controller = Get.find<Controller>();
    return Obx(() {
      controller.cloudreveI18n.length;
      final l10n = AppLocalizations.of(context)!;
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          children: [
            ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.folder_shared),
              childrenPadding: const EdgeInsets.fromLTRB(60, 0, 0, 0),
              title: Text(_trAny(controller, const ['navbar.myFiles'], l10n.myFiles)),
              children: [
                ListTile(
                  leading: const Icon(Icons.video_collection),
                  title: Text(_trAny(controller, const ['navbar.videos'], l10n.fileTypeVideo)),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_filter),
                  title: Text(_trAny(controller, const ['fileManager.imageViewer'], l10n.fileTypePicture)),
                ),
                ListTile(
                  leading: const Icon(Icons.music_video),
                  title: Text(_trAny(controller, const ['fileManager.musicPlayer'], l10n.fileTypeMusic)),
                ),
                ListTile(
                  leading: const Icon(Icons.document_scanner),
                  title: Text(_trAny(controller, const ['fileManager.file', 'fileManager.files'], l10n.fileTypeDocument)),
                )
              ],
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.share),
              title: Text(_trAny(controller, const ['navbar.myShare'], l10n.myShares)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.cloud_download),
              title: Text(_trAny(controller, const ['fileManager.newRemoteDownloads', 'setting.sendTask'], l10n.offlineDownload)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.computer),
              title: Text(_trAny(controller, const ['setting.connectionInfo'], l10n.connections)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.inventory),
              title: Text(_trAny(controller, const ['setting.queueing', 'taskQueue.queue'], l10n.processQueue)),
            ),
            Divider(
              color: Theme.of(context).dividerColor,
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.settings),
              title: Text(_trAny(controller, const ['navbar.setting', 'setting.settings'], l10n.settings)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              leading: const Icon(Icons.logout),
              title: Text(_trAny(controller, const ['login.logout'], l10n.logout)),
              onTap: (){
                controller.logout();
                Util.showSnackbar(
                  context: context,
                  message: _trAny(controller, const ['login.loggedOut'], l10n.logoutSuccess),
                );
              },
            )
          ],
        ),
      );
    });
  }
}
