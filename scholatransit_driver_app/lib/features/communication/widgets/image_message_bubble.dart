import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/message_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';
import 'message_bubble.dart';

class ImageMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  String _getImageUrl() {
    // Get image URL from attachmentUrl or fallback to content if it's a URL
    final url = message.attachmentUrl ?? (message.content.isNotEmpty ? message.content : null);
    if (url == null || url.isEmpty) return '';

    // If URL is already absolute, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If URL is relative, prepend base URL
    final baseUrl = AppConfig.baseUrl;
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  Map<String, String> _getAuthHeaders() {
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
      };
    }
    return {};
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
              child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                httpHeaders: _getAuthHeaders(),
                errorWidget: (context, url, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64.w, color: Colors.white),
                        SizedBox(height: 16.h),
                        Text(
                          'Failed to load image',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
                progressIndicatorBuilder: (context, url, downloadProgress) {
                  return Center(
                    child: CircularProgressIndicator(
                      value: downloadProgress.progress,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();

    // Debug logging
    print('🖼️ Image Message Debug:');
    print('  - attachmentUrl: ${message.attachmentUrl}');
    print('  - content: ${message.content}');
    print('  - messageType: ${message.type}');
    print('  - Final imageUrl: $imageUrl');
    print('  - Auth token available: ${StorageService.getAuthToken() != null}');

    if (imageUrl.isEmpty) {
      print('⚠️ No image URL found, falling back to text bubble');
      // Fallback to text bubble if no image URL
      return MessageBubble(message: message, isMe: isMe);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundImage: message.displayAvatar != null
                  ? CachedNetworkImageProvider(
                      message.displayAvatar!,
                      headers: _getAuthHeaders(),
                    )
                  : null,
              child: message.displayAvatar == null
                  ? Text(
                      message.displaySenderName.isNotEmpty
                          ? message.displaySenderName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, imageUrl),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                  maxHeight: 300.h,
                ),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF8B5CF6) : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                    bottomLeft: isMe ? Radius.circular(18.r) : Radius.circular(4.r),
                    bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(18.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                    bottomLeft: isMe ? Radius.circular(18.r) : Radius.circular(4.r),
                    bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(18.r),
                  ),
                  child: Stack(
                    children: [
                      // Image
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        httpHeaders: _getAuthHeaders(),
                        errorWidget: (context, url, error) {
                          return Container(
                            height: 200.h,
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48.w, color: Colors.grey[600]),
                                SizedBox(height: 8.h),
                                Text(
                                  'Failed to load image',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        progressIndicatorBuilder: (context, url, downloadProgress) {
                          return Container(
                            height: 200.h,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: downloadProgress.progress,
                                color: isMe ? Colors.white : const Color(0xFF8B5CF6),
                              ),
                            ),
                          );
                        },
                      ),
                      // Caption overlay (if content exists and is not the URL)
                      if (message.content.isNotEmpty &&
                          message.content != imageUrl &&
                          message.content != message.attachmentUrl)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Text(
                              message.content,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      // Tap indicator
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fullscreen,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: const Color(0xFF8B5CF6),
              child: Text(
                'Y',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
