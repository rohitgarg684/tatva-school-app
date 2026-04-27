import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../services/api_service.dart';

class StudentProfileTab extends StatefulWidget {
  final UserModel? user;
  final ClassModel? primaryClass;
  final VoidCallback onLogout;
  final ValueChanged<String> onPhotoUpdated;

  const StudentProfileTab({
    super.key,
    required this.user,
    required this.primaryClass,
    required this.onLogout,
    required this.onPhotoUpdated,
  });

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.name.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final url = await ApiService().uploadProfilePhoto(file.bytes!, file.name);
      if (url != null && mounted) {
        widget.onPhotoUpdated(url);
        TatvaSnackbar.show(context, 'Profile photo updated');
      } else if (mounted) {
        TatvaSnackbar.show(context, 'Upload failed', color: TatvaColors.error);
      }
    } catch (_) {
      if (mounted) {
        TatvaSnackbar.show(context, 'Upload failed', color: TatvaColors.error);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        FadeSlideIn(
            child: GestureDetector(
                onLongPress: _uploading ? null : _pickAndUploadPhoto,
                child: Stack(
                  children: [
                    HeroAvatar(
                        heroTag: 'student_avatar',
                        initial: widget.user?.initial ?? '?',
                        radius: 46,
                        bgColor: TatvaColors.info.withOpacity(0.1),
                        textColor: TatvaColors.info,
                        borderColor: TatvaColors.accent,
                        photoUrl: widget.user?.photoUrl ?? ''),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploading ? null : _pickAndUploadPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: TatvaColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ))),
        const SizedBox(height: 16),
        FadeSlideIn(
            delayMs: 80,
            child: Text(widget.user?.name ?? '',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.5))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 100,
            child: Text(widget.user?.email ?? '',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 10),
        FadeSlideIn(
            delayMs: 120,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                    color: TatvaColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Student',
                    style: TextStyle(
                        fontSize: 12,
                        color: TatvaColors.info,
                        fontWeight: FontWeight.w700)))),
        const SizedBox(height: 28),
        FadeSlideIn(
            delayMs: 130,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: TatvaColors.info.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TatvaColors.info.withOpacity(0.15))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.class_outlined, color: TatvaColors.info, size: 15),
                      const SizedBox(width: 6),
                      const Text('My Class',
                          style: TextStyle(
                              fontSize: 12,
                              color: TatvaColors.info,
                              fontWeight: FontWeight.w700))
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(widget.primaryClass?.name ?? '',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.neutral900)),
                            Text(widget.primaryClass?.subject ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: TatvaColors.accent.withOpacity(0.3))),
                          child: Text(widget.primaryClass?.classCode ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.accent,
                                  letterSpacing: 2))),
                    ]),
                  ]),
            )),
        FadeSlideIn(
            delayMs: 150,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Row(children: [
                CircleAvatar(
                    radius: 22,
                    backgroundColor: TatvaColors.primary.withOpacity(0.1),
                    child: Text((widget.primaryClass?.teacherName ?? '?').isNotEmpty ? widget.primaryClass!.teacherName[0] : '?',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.primary))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.primaryClass?.teacherName ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      Text('Your Teacher · ${widget.primaryClass?.subject ?? ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: TatvaColors.neutral400)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            size: 11, color: TatvaColors.neutral400),
                        const SizedBox(width: 4),
                        Text(widget.primaryClass?.teacherEmail ?? '',
                            style: const TextStyle(
                                fontSize: 10,
                                color: TatvaColors.neutral400)),
                      ]),
                    ])),
              ]),
            )),
        const SizedBox(height: 12),
        ...List.generate(2, (index) {
          final items = [
            [Icons.school_outlined, 'School', 'Tatva Academy'],
            [Icons.verified_outlined, 'Status', 'Verified'],
          ];
          return StaggeredItem(
              index: index,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: RippleTap(
                    rippleColor: TatvaColors.info,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100)),
                      child: Row(children: [
                        Icon(items[index][0] as IconData,
                            color: TatvaColors.info, size: 18),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(items[index][1] as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: TatvaColors.neutral400))),
                        Text(items[index][2] as String,
                            style: const TextStyle(
                                fontSize: 13,
                                color: TatvaColors.neutral900,
                                fontWeight: FontWeight.w600)),
                      ]),
                    )),
              ));
        }),
        const SizedBox(height: 24),
        FadeSlideIn(
            delayMs: 200,
            child: BouncyTap(
                onTap: widget.onLogout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TatvaColors.error.withOpacity(0.15))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: TatvaColors.error, size: 18),
                        const SizedBox(width: 8),
                        const Text('Sign Out',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.error)),
                      ]),
                ))),
        const SizedBox(height: 16),
        const Text('v1.0.0 · Tatva Academy',
            style: TextStyle(
                fontSize: 11, color: TatvaColors.neutral400)),
        const SizedBox(height: 24),
      ]),
    );
  }
}
