import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/star_rating.dart';
import '../../widgets/common/loading_overlay.dart';

class RateRideScreen extends StatefulWidget {
  final String rideId;
  final String reviewedUid;
  final String reviewedName;
  final String reviewedAvatar;
  final bool isRiderRating;

  const RateRideScreen({
    super.key,
    required this.rideId,
    required this.reviewedUid,
    required this.reviewedName,
    required this.reviewedAvatar,
    required this.isRiderRating,
  });

  @override
  State<RateRideScreen> createState() => _RateRideScreenState();
}

class _RateRideScreenState extends State<RateRideScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  final Set<String> _selectedTags = {};

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _driverTags = [
    'Safe Driver',
    'On Time',
    'Friendly',
    'Clean Car',
    'Great Music',
    'Smooth Ride',
  ];

  static const _riderTags = [
    'Friendly',
    'On Time',
    'Respectful',
    'Great Rider',
    'Easy Pickup',
    'Good Vibes',
  ];

  List<String> get _tags => widget.isRiderRating ? _driverTags : _riderTags;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      SnackbarHelper.showWarning(context, 'Please select a rating');
      return;
    }
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Append selected tags to comment
      String? comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();
      if (_selectedTags.isNotEmpty) {
        final tagStr = _selectedTags.join(', ');
        comment = comment != null ? '$comment\nTags: $tagStr' : 'Tags: $tagStr';
      }

      await ReviewService().submitReview(
        reviewedUid: widget.reviewedUid,
        reviewerUid: user.uid,
        reviewerName: user.fullName,
        reviewerAvatar: user.avatar,
        rideId: widget.rideId,
        stars: _rating,
        comment: comment,
        isRiderRating: widget.isRiderRating,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Rating submitted!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to submit rating');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Rate Ride',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar
                  AvatarWidget(
                    avatarId: widget.reviewedAvatar,
                    size: AvatarSize.xlarge,
                    showRing: true,
                    isDriver: !widget.isRiderRating,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'How was your ride with',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.subtitleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.reviewedName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Animated emoji face
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Text(
                      _ratingEmoji(),
                      key: ValueKey(_rating),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Star rating in card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 28, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        StarRating(
                          rating: _rating.toDouble(),
                          size: 48,
                          interactive: true,
                          onRatingChanged: (r) {
                            setState(() => _rating = r);
                          },
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _ratingLabel(),
                            key: ValueKey(_rating),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _rating > 0
                                  ? AppColors.rowanBrown
                                  : AppColors.lightText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick-tag chips
                  if (_rating > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Tags',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to add tags to your review',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.subtitleText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTags.remove(tag);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF6B1420),
                                              AppColors.rowanBrown,
                                            ],
                                          )
                                        : null,
                                    color:
                                        isSelected ? null : AppColors.cream,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: AppColors.rowanBrown
                                                .withAlpha(30)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.rowanBrown,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Comment card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Leave a comment (optional)',
                        hintStyle: TextStyle(color: AppColors.lightText),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.rowanBrown, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.rowanGold, Color(0xFFFFD54F)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rowanGold.withAlpha(90),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: const Icon(Icons.star_rounded),
                        label: const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppColors.darkText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _ratingEmoji() {
    switch (_rating) {
      case 1:
        return '\u{1F641}';
      case 2:
        return '\u{1F615}';
      case 3:
        return '\u{1F642}';
      case 4:
        return '\u{1F60A}';
      case 5:
        return '\u{1F929}';
      default:
        return '\u{1F914}';
    }
  }

  String _ratingLabel() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap to rate';
    }
  }
}
