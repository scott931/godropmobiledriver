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
    // Get image URL from attachmentUrl - only use content if it's a valid URL
    String? url = message.attachmentUrl ?? message.voiceUrl;

    // Only use content as URL if attachmentUrl is null/empty AND content looks like a URL
    if ((url == null || url.isEmpty) && message.content.isNotEmpty) {
      // Check if content is a valid URL (starts with http:// or https://)
      if (message.content.startsWith('http://') || message.content.startsWith('https://')) {
        url = message.content;
      } else {
        // Content is not a URL, don't use it
        print('⚠️ Image message has no valid URL');
        return '';
      }
    }

    if (url == null || url.isEmpty) {
      print('⚠️ Image URL is null or empty');
      return '';
    }

    // If URL is already absolute, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If URL is relative, prepend base URL
    final baseUrl = AppConfig.baseUrl.trim();
    // Remove trailing slash from baseUrl if present
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final finalUrl = url.startsWith('/') ? '$cleanBaseUrl$url' : '$cleanBaseUrl/$url';
    print('🖼️ Final image URL: $finalUrl');
    print('   Original URL: $url');
    print('   Base URL: $cleanBaseUrl');
    print('   Message ID: ${message.id}');
    print('   Message Type: ${message.type}');
    print('   Timestamp: ${message.timestamp}');

    // Verify URL format
    if (finalUrl.contains('scaled_') && !finalUrl.contains('http')) {
      print('⚠️ WARNING: URL might be malformed');
    }

    return finalUrl;
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
                        // Cache settings for better performance
                        maxWidthDiskCache: 1000,
                        maxHeightDiskCache: 1000,
                        memCacheWidth: 1000,
                        memCacheHeight: 1000,
                        // Retry on error
                        fadeInDuration: Duration(milliseconds: 300),
                        fadeOutDuration: Duration(milliseconds: 100),
                        // Use cache key to force refresh if needed
                        cacheKey: imageUrl,
                        errorWidget: (context, url, error) {
                          print('❌ Image load error for URL: $url');
                          print('   Error: $error');
                          print('   Error type: ${error.runtimeType}');
                          print('   Error toString: ${error.toString()}');
                          print('   Message attachmentUrl: ${message.attachmentUrl}');
                          print('   Message content: ${message.content}');
                          print('   Message ID: ${message.id}');
                          print('   Auth headers: ${_getAuthHeaders()}');

                          // Check for different error types
                          final errorStr = error.toString().toLowerCase();
                          final is404 = errorStr.contains('404') || errorStr.contains('notfound');
                          final is401 = errorStr.contains('401') || errorStr.contains('unauthorized');
                          final is403 = errorStr.contains('403') || errorStr.contains('forbidden');
                          final isNetwork = errorStr.contains('network') ||
                                           errorStr.contains('connection') ||
                                           errorStr.contains('socket') ||
                                           errorStr.contains('timeout');

                          String errorMessage;
                          IconData errorIcon;

                          if (is401 || is403) {
                            errorMessage = 'Authentication failed. Please check your login.';
                            errorIcon = Icons.lock_outline;
                          } else if (is404) {
                            errorMessage = 'Image not found (404)';
                            errorIcon = Icons.image_not_supported;
                          } else if (isNetwork) {
                            errorMessage = 'Network error. Please check your connection.';
                            errorIcon = Icons.wifi_off;
                          } else {
                            errorMessage = 'Failed to load image';
                            errorIcon = Icons.broken_image;
                          }

                          return Container(
                            height: 200.h,
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  errorIcon,
                                  size: 48.w,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(height: 8.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    errorMessage,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (is404) ...[
                                  SizedBox(height: 4.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Text(
                                      'The image may still be processing. Please wait and refresh.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
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
