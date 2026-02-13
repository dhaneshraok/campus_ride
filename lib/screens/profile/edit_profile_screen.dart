import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/avatar_data.dart';
import '../../constants/vehicle_data.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/validators.dart';
import '../../widgets/common/avatar_picker.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/profile/vehicle_type_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _carColorController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String _selectedAvatar = 'campus_owl';
  String _selectedCarType = VehicleCollection.defaultVehicleType;
  bool _isDriver = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _loadProfile();
    _animController.forward();
  }

  void _loadProfile() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    _nameController.text = user.fullName;
    _phoneController.text = user.phone;
    _carModelController.text = user.carModel ?? '';
    _carPlateController.text = user.carPlate ?? '';
    _carColorController.text = user.carColor ?? '';
    _emergencyNameController.text = user.emergencyContactName ?? '';
    _emergencyPhoneController.text = user.emergencyContactPhone ?? '';
    _selectedAvatar = AvatarCollection.normalizeAvatarId(user.avatar);
    _selectedCarType = VehicleCollection.normalize(user.carType);
    _isDriver = user.isDriver;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updated = AppUser(
        uid: user.uid,
        email: user.email,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatar: AvatarCollection.normalizeAvatarId(_selectedAvatar),
        isDriver: _isDriver,
        carType: _isDriver ? _selectedCarType : null,
        carModel: _isDriver ? _carModelController.text.trim() : null,
        carPlate: _isDriver ? _carPlateController.text.trim() : null,
        carColor: _isDriver ? _carColorController.text.trim() : null,
        ratingSum: user.ratingSum,
        ratingCount: user.ratingCount,
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        isOnboarded: user.isOnboarded,
        fcmToken: user.fcmToken,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      );

      await UserService().updateUser(updated);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Profile updated!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to update profile');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Center(
                      child: AvatarPicker(
                        selectedAvatar: _selectedAvatar,
                        isDriver: _isDriver,
                        onAvatarSelected: (a) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedAvatar = a);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personal info card
                  _sectionCard(
                    icon: Icons.person_rounded,
                    title: 'Personal Info',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            Validators.validateRequired(v, 'Name'),
                        decoration: _inputDecoration(
                          'Full Name',
                          Icons.person_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          'Phone',
                          Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Driver card
                  _sectionCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Driver Info',
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isDriver = !_isDriver);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: _isDriver
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.rowanBrown.withValues(
                                        alpha: 0.08,
                                      ),
                                      AppColors.rowanGold.withValues(
                                        alpha: 0.04,
                                      ),
                                    ],
                                  )
                                : null,
                            color: _isDriver ? null : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isDriver
                                  ? AppColors.rowanBrown.withValues(alpha: 0.3)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions_car_rounded,
                                size: 20,
                                color: AppColors.rowanBrown,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'I\'m a Driver',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isDriver,
                                onChanged: (v) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isDriver = v);
                                },
                                activeTrackColor: AppColors.rowanBrown
                                    .withValues(alpha: 0.5),
                                activeThumbColor: AppColors.rowanBrown,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _isDriver
                            ? Column(
                                children: [
                                  const SizedBox(height: 14),
                                  VehicleTypePicker(
                                    selectedType: _selectedCarType,
                                    onSelected: (type) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedCarType = type);
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _carModelController,
                                    decoration: _inputDecoration(
                                      'Car Model',
                                      Icons.directions_car_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _carColorController,
                                    decoration: _inputDecoration(
                                      'Car Color',
                                      Icons.palette_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _carPlateController,
                                    decoration: _inputDecoration(
                                      'License Plate',
                                      Icons.badge_outlined,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Emergency contact card
                  _sectionCard(
                    icon: Icons.emergency_rounded,
                    title: 'Emergency Contact',
                    children: [
                      TextFormField(
                        controller: _emergencyNameController,
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

                  // Save button
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
                            color: AppColors.rowanBrown.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
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
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
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
        children: [
          Row(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
