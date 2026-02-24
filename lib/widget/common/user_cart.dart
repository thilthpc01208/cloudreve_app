import 'package:cloudreve_view/common/api.dart';
import 'package:cloudreve_view/entity/user.dart';
import 'package:cloudreve_view/widget/common/theme_change_btn.dart';
import 'package:flutter/material.dart';

class UserCart extends StatefulWidget {
  final User user;
  final double height;
  const UserCart({super.key, required this.user, this.height = 180});

  @override
  State<StatefulWidget> createState() {
    return _UserCartState();
  }
}

class _UserCartState extends State<UserCart> {
  bool _isValidAvatarUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    // "/file" is Cloudreve directory endpoint, not an image.
    if (uri.path == '/file') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConfig.resolveUrl(widget.user.avatar);
    final hasAvatar = _isValidAvatarUrl(avatarUrl);

    return Container(
      height: widget.height,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 5),
                          blurRadius: 10.0,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white12,
                      child: ClipOval(
                        child: hasAvatar
                            ? Image.network(
                                avatarUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person, size: 40),
                              )
                            : const Icon(Icons.person, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.user.nickname,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    widget.user.group.name,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 214, 214, 214),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const ThemeChangeBtn()
            ],
          )
        ],
      ),
    );
  }
}
