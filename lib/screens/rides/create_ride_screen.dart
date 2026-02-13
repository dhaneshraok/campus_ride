import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/validators.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/ride/location_chip_row.dart';

class CreateRideScreen extends StatefulWidget {
  final String? initialPickup;
  final String? initialDestination;

  const CreateRideScreen({
    super.key,
    this.initialPickup,
    this.initialDestination,
  });

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _pickupDateTime = DateTime.now().add(const Duration(minutes: 15));
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPickup != null) {
      _pickupController.text = widget.initialPickup!;
    }
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillLocation(String location) {
    if (_pickupController.text.trim().isEmpty) {
      _pickupController.text = location;
    } else if (_destinationController.text.trim().isEmpty) {
      _destinationController.text = location;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate =
        _pickupDateTime.isBefore(firstDate) ? firstDate : _pickupDateTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.rowanBrown,
                ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _pickupDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _pickupDateTime.hour,
          _pickupDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.rowanBrown,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _pickupDateTime = DateTime(
          _pickupDateTime.year,
          _pickupDateTime.month,
          _pickupDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDateTime.isBefore(DateTime.now())) {
      SnackbarHelper.showError(context, 'Pickup date and time must be in the future');
      return;
    }

    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final ride = Ride(
      id: '',
      riderUid: user.uid,
      riderName: user.fullName,
      riderAvatar: user.avatar,
      destination: _destinationController.text.trim(),
      pickupArea: _pickupController.text.trim(),
      pickupAddress: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      pickupTime: DateFormat('MM/dd/yyyy hh:mm a').format(_pickupDateTime),
      pickupDatetime: _pickupDateTime,
      isUrgent: _isUrgent,
    );

    final rideId = await rideProvider.createRide(ride);

    if (mounted) {
      setState(() => _isLoading = false);
      if (rideId != null) {
        SnackbarHelper.showSuccess(context, 'Ride request posted!');
        Navigator.pop(context);
      } else {
        SnackbarHelper.showError(context, 'Failed to create ride');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request a Ride')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Route line
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppColors.rowanBrown,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: AppColors.rowanBrown.withValues(alpha: 0.3),
                                  ),
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: AppColors.rowanGold,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Fields
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _pickupController,
                                    validator: (v) => Validators.validateRequired(v, 'Pickup'),
                                    decoration: const InputDecoration(
                                      hintText: 'Pickup location',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Divider(color: Colors.grey[200]),
                                  TextFormField(
                                    controller: _destinationController,
                                    validator: (v) => Validators.validateRequired(v, 'Destination'),
                                    decoration: const InputDecoration(
                                      hintText: 'Destination',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick location chips
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Quick Select',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtitleText,
                          ),
                        ),
                      ),
                      LocationChipRow(onLocationSelected: _fillLocation),
                      const SizedBox(height: 24),

                      // Date picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.rowanBrown.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.rowanBrown,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pickup Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subtitleText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('EEE, MMM d, y').format(_pickupDateTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.lightText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time picker
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.rowanBrown.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.rowanBrown,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pickup Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subtitleText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('h:mm a').format(_pickupDateTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.lightText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Urgency toggle
                      GestureDetector(
                        onTap: () => setState(() => _isUrgent = !_isUrgent),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _isUrgent
                                ? AppColors.error.withValues(alpha: 0.06)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isUrgent
                                  ? AppColors.error.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.priority_high_rounded,
                                color: _isUrgent ? AppColors.error : AppColors.lightText,
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Mark as Urgent',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isUrgent,
                                onChanged: (v) => setState(() => _isUrgent = v),
                                activeTrackColor: AppColors.error.withValues(alpha: 0.5),
                                activeThumbColor: AppColors.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Additional notes (optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Submit button
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Post Ride Request'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
