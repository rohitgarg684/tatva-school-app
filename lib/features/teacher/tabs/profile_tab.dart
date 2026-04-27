import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';

class TeacherProfileTab extends StatefulWidget {
  final UserModel? user;
  final int classCount;
  final VoidCallback onLogout;
  final ValueChanged<String> onPhotoUpdated;

  const TeacherProfileTab({
    super.key,
    required this.user,
    required this.classCount,
    required this.onLogout,
    required this.onPhotoUpdated,
  });

  @override
  State<TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<TeacherProfileTab> {
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
                          heroTag: 'teacher_avatar',
                          initial: widget.user?.initial ?? '?',
                          radius: 46,
                          bgColor: TatvaColors.primary.withOpacity(0.1),
                          textColor: TatvaColors.primary,
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
                              color: TatvaColors.primary,
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
                      color: TatvaColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Teacher',
                      style: TextStyle(
                          fontSize: 12,
                          color: TatvaColors.accent,
                          fontWeight: FontWeight.w700)))),
          const SizedBox(height: 28),
          ...List.generate(4, (i) {
            final items = [
              [Icons.school_outlined, 'School', 'Tatva Academy'],
              [Icons.book_outlined, 'Subject', 'Mathematics'],
              [Icons.class_outlined, 'Classes', '${widget.classCount} Active'],
              [Icons.verified_outlined, 'Status', 'Verified'],
            ];
            return StaggeredItem(
                index: i,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: RippleTap(
                      rippleColor: TatvaColors.primary,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: TatvaColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100)),
                        child: Row(children: [
                          Icon(items[i][0] as IconData,
                              color: TatvaColors.primary, size: 18),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Text(items[i][1] as String,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: TatvaColors.neutral400))),
                          Text(items[i][2] as String,
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
                        border: Border.all(
                            color: TatvaColors.error.withOpacity(0.15))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: TatvaColors.error, size: 18),
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
              style: TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
          const SizedBox(height: 24),
        ]));
  }
}
