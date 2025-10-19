import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/contact_service.dart';

class ContactPickerWidget extends StatefulWidget {
  final Function(Contact) onContactSelected;
  final String? title;
  final String? hintText;
  final bool showSearch;

  const ContactPickerWidget({
    super.key,
    required this.onContactSelected,
    this.title,
    this.hintText,
    this.showSearch = true,
  });

  @override
  State<ContactPickerWidget> createState() => _ContactPickerWidgetState();
}

class _ContactPickerWidgetState extends State<ContactPickerWidget> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeContacts() async {
    setState(() => _isLoading = true);

    try {
      // Check permission
      final hasPermission = await ContactService.hasPermission();
      print('Contact permission status: $hasPermission');

      if (!hasPermission) {
        print('Requesting contact permission...');
        final granted = await ContactService.requestPermission();
        print('Permission granted: $granted');

        if (!granted) {
          // Check if permission is permanently denied
          final isPermanentlyDenied =
              await ContactService.isPermissionPermanentlyDenied();
          print('Permission permanently denied: $isPermanentlyDenied');

          setState(() {
            _isLoading = false;
            _hasPermission = false;
          });
          return;
        }
      }

      // Get contacts with phone numbers
      print('Fetching contacts with phone numbers...');
      final contacts = await ContactService.getContactsWithPhones();
      print('Retrieved ${contacts.length} contacts with phone numbers');

      // Get diagnostic information
      final diagnostics = await ContactService.getContactDiagnostics();
      print('Contact diagnostics: $diagnostics');

      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
        _hasPermission = true;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final displayName = ContactService.getContactDisplayName(contact);
          final phoneNumber = ContactService.getPrimaryPhoneNumber(contact);

          return displayName.toLowerCase().contains(query.toLowerCase()) ||
              (phoneNumber?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permission Required',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Contact permission has been permanently denied. Please enable it in your device settings to access your contacts.',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ContactService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          maxWidth: 420.w,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              _buildModernHeader(),

              // Content area
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(28.w, 24.h, 20.w, 28.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF1D4ED8),
            const Color(0xFF1E40AF),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top row with icon and close button
          Row(
            children: [
              // Icon with modern styling
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.contacts_rounded,
                  color: Colors.white,
                  size: 28.w,
                ),
              ),
              SizedBox(width: 16.w),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? 'Select Contact',
                      style: GoogleFonts.poppins(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Choose a contact to get their phone number',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Close button with modern styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20.w,
                  ),
                  padding: EdgeInsets.all(8.w),
                  constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
                ),
              ),
            ],
          ),

          // Contact count indicator
          if (_contacts.isNotEmpty && !_isLoading) ...[
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 16.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${_filteredContacts.length} contact${_filteredContacts.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasPermission) {
      return _buildPermissionDenied();
    }

    if (_isLoading) {
      return _buildLoading();
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Search bar
        if (widget.showSearch) _buildSearchBar(),

        // Contacts list
        Expanded(child: _buildContactsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterContacts,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Search contacts...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: EdgeInsets.all(12.w),
              child: Icon(
                Icons.search_rounded,
                color: const Color(0xFF64748B),
                size: 20.w,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? Container(
                    margin: EdgeInsets.only(right: 8.w),
                    child: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterContacts('');
                      },
                      icon: Icon(
                        Icons.clear_rounded,
                        color: const Color(0xFF64748B),
                        size: 18.w,
                      ),
                      padding: EdgeInsets.all(8.w),
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.w,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: const Color(0xFF3B82F6),
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 18.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactItem(contact);
      },
    );
  }

  Widget _buildContactItem(Contact contact) {
    final displayName = ContactService.getContactDisplayName(contact);
    final phoneNumber = ContactService.getPrimaryPhoneNumber(contact);
    final formattedPhone = ContactService.formatPhoneNumber(phoneNumber);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onContactSelected(contact);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: const Color(0xFF3B82F6).withOpacity(0.1),
          highlightColor: const Color(0xFF3B82F6).withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // Modern avatar with gradient
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF1D4ED8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // Contact info with better typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14.w,
                            color: const Color(0xFF64748B),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              formattedPhone,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Modern arrow with animation
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16.w,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern loading animation
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(40.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Loading contacts...',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please wait while we fetch your contacts',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern empty state icon
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                ),
                borderRadius: BorderRadius.circular(50.r),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: Icon(
                Icons.contacts_outlined,
                size: 50.w,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Contacts Found',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'No contacts with phone numbers were found on your device',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // Modern info card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: const Color(0xFF0EA5E9),
                      size: 24.w,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Troubleshooting Tips',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '• Make sure you have contacts saved on your device\n• Ensure contacts have phone numbers\n• Check if contact permissions are granted\n• Try refreshing the contact list',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: const Color(0xFF0369A1),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Modern action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3B82F6),
                          const Color(0xFF1D4ED8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _initializeContacts();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Refresh',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern permission icon
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(50.r),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 50.w,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Permission Required',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'We need access to your contacts to help you select phone numbers easily.',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // Modern info card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 24.w,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Why do we need this?',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Contact access allows you to quickly select phone numbers from your saved contacts instead of typing them manually.',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: const Color(0xFF92400E),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Modern action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3B82F6),
                          const Color(0xFF1D4ED8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final granted =
                            await ContactService.requestPermission();
                        if (granted) {
                          _initializeContacts();
                        } else {
                          // Check if permission is permanently denied
                          final isPermanentlyDenied =
                              await ContactService.isPermissionPermanentlyDenied();
                          if (isPermanentlyDenied) {
                            // Show dialog to open app settings
                            _showSettingsDialog();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Grant Permission',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
