import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/avatar_data.dart';
import '../../constants/avatar_list.dart';
import '../../constants/vehicle_data.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/validators.dart';
import '../../widgets/common/avatar_picker.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/profile/vehicle_type_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _carColorController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String _selectedAvatar = AvatarList.defaultAvatar;
  String _selectedCarType = VehicleCollection.defaultVehicleType;
  bool _isDriver = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _carModelController.dispose();
    _carPlateController.dispose();
    _carColorController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final firebaseUser = auth.firebaseUser;
    if (firebaseUser == null) return;

    setState(() => _isLoading = true);

    try {
      final user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatar: AvatarCollection.normalizeAvatarId(_selectedAvatar),
        isDriver: _isDriver,
        carType: _isDriver ? _selectedCarType : null,
        carModel: _isDriver ? _carModelController.text.trim() : null,
        carPlate: _isDriver ? _carPlateController.text.trim() : null,
        carColor: _isDriver ? _carColorController.text.trim() : null,
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        isOnboarded: false,
      );

      await UserService().createUser(user);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Profile created!');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Profile creation error: $e');
        SnackbarHelper.showError(
          context,
          'Failed to create profile: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Setup Profile',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          'Let\'s get to know you',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Set up your campus profile',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitleText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Avatar section
                      _sectionCard(
                        children: [
                          const Text(
                            'Choose Your Avatar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AvatarPicker(
                            selectedAvatar: _selectedAvatar,
                            isDriver: _isDriver,
                            onAvatarSelected: (a) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedAvatar = a);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Personal info
                      _sectionCard(
                        children: [
                          _sectionHeader(Icons.person_rounded, 'Personal Info'),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Full name'),
                            decoration: _inputDecoration(
                              'Full Name',
                              Icons.person_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                            decoration: _inputDecoration(
                              'Phone (optional)',
                              Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Driver toggle
                      _sectionCard(
                        children: [
                          _sectionHeader(
                            Icons.directions_car_rounded,
                            'Driver Registration',
                          ),
                          const SizedBox(height: 16),
                          _buildDriverToggle(),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isDriver
                                ? Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      VehicleTypePicker(
                                        selectedType: _selectedCarType,
                                        onSelected: (type) {
                                          HapticFeedback.selectionClick();
                                          setState(
                                            () => _selectedCarType = type,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _carModelController,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        validator: _isDriver
                                            ? (v) =>
                                                  Validators.validateRequired(
                                                    v,
                                                    'Car model',
                                                  )
                                            : null,
                                        decoration: _inputDecoration(
                                          'Car Model',
                                          Icons.directions_car_outlined,
                                          hint: 'e.g. 2022 Honda Civic',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _carColorController,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        decoration: _inputDecoration(
                                          'Car Color',
                                          Icons.palette_outlined,
                                          hint: 'e.g. Silver',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _carPlateController,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        validator: _isDriver
                                            ? (v) =>
                                                  Validators.validateRequired(
                                                    v,
                                                    'License plate',
                                                  )
                                            : null,
                                        decoration: _inputDecoration(
                                          'License Plate',
                                          Icons.badge_outlined,
                                          hint: 'e.g. ABC-1234',
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Emergency contact
                      _sectionCard(
                        children: [
                          _sectionHeader(
                            Icons.emergency_rounded,
                            'Emergency Contact',
                            subtitle: 'Optional but recommended',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emergencyNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              'Contact Name',
                              Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emergencyPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              'Contact Phone',
                              Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit
                      SizedBox(
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B1420), AppColors.rowanBrown],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.rowanBrown.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Complete Setup',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, {String? subtitle}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.rowanBrown.withValues(alpha: 0.1),
                AppColors.rowanGold.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.rowanBrown),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtitleText,
                ),
              ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.rowanBrown.withValues(alpha: 0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.rowanBrown, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildDriverToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isDriver = !_isDriver);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _isDriver
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.rowanBrown.withValues(alpha: 0.08),
                    AppColors.rowanGold.withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: _isDriver ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDriver
                ? AppColors.rowanBrown.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: _isDriver ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isDriver
                    ? AppColors.rowanBrown.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: _isDriver ? AppColors.rowanBrown : AppColors.lightText,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'I have a car and can drive',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Help fellow students get around campus',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitleText,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isDriver,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _isDriver = v);
              },
              activeTrackColor: AppColors.rowanBrown.withValues(alpha: 0.5),
              activeThumbColor: AppColors.rowanBrown,
            ),
          ],
        ),
      ),
    );
  }
}
