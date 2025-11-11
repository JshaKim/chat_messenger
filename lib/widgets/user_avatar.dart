import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final bool isOnline;
  final double radius;
  final bool showOnlineIndicator;

  const UserAvatar({
    super.key,
    this.photoURL,
    this.isOnline = false,
    this.radius = 24,
    this.showOnlineIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 프로필 사진
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          backgroundImage: photoURL != null && photoURL!.isNotEmpty
              ? CachedNetworkImageProvider(photoURL!)
              : null,
          child: photoURL == null || photoURL!.isEmpty
              ? Icon(
                  Icons.person,
                  size: radius * 1.2,
                  color: Colors.grey[600],
                )
              : null,
        ),

        // 온라인 상태 표시
        if (showOnlineIndicator && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
