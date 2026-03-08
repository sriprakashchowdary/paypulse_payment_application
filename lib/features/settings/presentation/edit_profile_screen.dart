import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_input_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// ══════════════════════════════════════════════════════════════
/// Edit Profile Screen
///
/// Reads user data from `userDocProvider` (Firestore stream), lets
/// the user edit name / phone / photoUrl, then writes back via
/// `authControllerProvider.updateProfile()`.
/// ══════════════════════════════════════════════════════════════

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();

  File? _imageFile;
  final _picker = ImagePicker();

  bool _initialised = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  /// Pre-fill controllers the first time data arrives from Firestore.
  void _init(dynamic user) {
    if (_initialised || user == null) return;
    _initialised = true;
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
    _photoCtrl.text = user.photoUrl ?? '';
  }

  // ── Save ──────────────────────────────────────────────────────

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() => _saving = true);

    final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          uid: uid,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          photoUrl: _photoCtrl.text.trim(),
          imageFile: _imageFile,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _showSnackbar(
        context,
        message: 'Profile updated successfully!',
        isError: false,
      );
    } else {
      final err =
          ref.read(authControllerProvider).error ?? 'Update failed. Try again.';
      _showSnackbar(context, message: err, isError: true);
    }
  }

  void _showSnackbar(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(userDocProvider);
    final authState = ref.watch(authControllerProvider);

    // Pre-fill forms once data is available
    userAsync.whenData(_init);

    final uid = userAsync.value?.uid ?? '';
    final photoUrl = _photoCtrl.text.trim();
    final hasPhoto = photoUrl.isNotEmpty;
    final nameInitial =
        (_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'U').toUpperCase();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          // Save button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: (_saving || authState.isLoading)
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('save'),
                      onPressed: uid.isEmpty ? null : () => _save(uid),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Save'),
                    ),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load profile.',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.textMuted,
            ),
          ),
        ),
        data: (_) =>
            _buildForm(isDark, uid, hasPhoto, nameInitial, photoUrl, theme),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Widget _buildForm(
    bool isDark,
    String uid,
    bool hasPhoto,
    String nameInitial,
    String photoUrl,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────
            Center(
              child: Stack(
                children: [
                  // Photo / initials circle
                  GestureDetector(
                    onTap: _pickImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (hasPhoto || _imageFile != null)
                            ? null
                            : AppColors.primaryGradient,
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : hasPhoto
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  )
                                : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: (hasPhoto || _imageFile != null)
                          ? null
                          : Center(
                              child: Text(
                                nameInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Edit badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap the circle to upload a new photo',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Section label ───────────────────────────
            _SectionLabel('Personal Info', isDark: isDark),
            const SizedBox(height: 12),

            // Name
            AppInputField(
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'Enter your name',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Too short';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email — read-only (Firebase Auth controls email)
            AppInputField(
              controller: _emailCtrl,
              label: 'Email Address',
              hint: 'your@email.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
              suffix: const Tooltip(
                message: 'Email cannot be changed here',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Phone
            AppInputField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: '+91 98765 43210',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) return 'Enter a valid phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 36),

            // ── Save button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_saving || uid.isEmpty) ? null : () => _save(uid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.xl),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Section label
// ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white38 : AppColors.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }
}
