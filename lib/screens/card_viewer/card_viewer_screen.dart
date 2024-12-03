import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/card_model.dart';
import '../../services/supabase_service.dart';
import '../../config/theme.dart';
import '../../widgets/card_template_widget.dart';
import '../templates/card_templates_screen.dart';
import '../analytics/analytics_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' show pi;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CardViewerScreen extends StatefulWidget {
  final DigitalCard card;
  final bool isSavedCard;

  const CardViewerScreen({
    super.key,
    required this.card,
    this.isSavedCard = false,
  });

  @override
  State<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends State<CardViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFrontVisible = true;
  bool _isLoading = false;
  final _authService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );

    _flipAnimation.addListener(() {
      setState(() {
        if (_flipAnimation.value >= 0.5 && _isFrontVisible) {
          _isFrontVisible = false;
        } else if (_flipAnimation.value < 0.5 && !_isFrontVisible) {
          _isFrontVisible = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFrontVisible) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.id;
    final isOwner = widget.card.userId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                widget.card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardPreview(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildContactInfo(),
                  if (widget.card.socialLinks?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 24),
                    _buildSocialLinks(),
                  ],
                  const SizedBox(height: 24),
                  _buildAdditionalInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * pi;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: CardTemplateWidget(
                  key: ValueKey(_isFrontVisible),
                  card: widget.card,
                  styles: widget.card.template?.styles ??
                      {
                        'primaryColor': '#000000',
                        'secondaryColor': '#FFFFFF',
                        'fontFamily': 'Roboto',
                      },
                  showFront: _isFrontVisible,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Tap card to flip',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isOwner = _authService.currentUser?.id == widget.card.userId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (isOwner) ...[
          _buildActionButton(
            icon: Icons.analytics,
            label: 'Analytics',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsScreen(initialCard: widget.card),
              ),
            ),
          ),
          _buildActionButton(
            icon: Icons.style,
            label: 'Templates',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardTemplatesScreen(card: widget.card),
              ),
            ),
          ),
        ],
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onTap: _shareCard,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.contact_mail,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildContactTile(
                  icon: Icons.email,
                  title: 'Email',
                  value: widget.card.email,
                  onTap: () => _launchUrl('mailto:${widget.card.email}'),
                ),
                if (widget.card.phone != null) ...[
                  const SizedBox(height: 16),
                  _buildContactTile(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: widget.card.phone!,
                    onTap: () => _launchUrl('tel:${widget.card.phone}'),
                  ),
                ],
                if (widget.card.website != null) ...[
                  const SizedBox(height: 16),
                  _buildContactTile(
                    icon: Icons.language,
                    title: 'Website',
                    value: widget.card.website!,
                    onTap: () => _launchUrl(widget.card.website!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  color: AppColors.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Social Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.card.socialLinks!.entries.map((entry) {
                IconData getIcon() {
                  switch (entry.key.toLowerCase()) {
                    case 'linkedin':
                      return FontAwesomeIcons.linkedin;
                    case 'twitter':
                      return FontAwesomeIcons.twitter;
                    case 'facebook':
                      return FontAwesomeIcons.facebook;
                    case 'instagram':
                      return FontAwesomeIcons.instagram;
                    case 'github':
                      return FontAwesomeIcons.github;
                    default:
                      return FontAwesomeIcons.link;
                  }
                }

                Color getPlatformColor() {
                  switch (entry.key.toLowerCase()) {
                    case 'linkedin':
                      return const Color(0xFF0077B5);
                    case 'twitter':
                      return const Color(0xFF1DA1F2);
                    case 'facebook':
                      return const Color(0xFF1877F2);
                    case 'instagram':
                      return const Color(0xFFE4405F);
                    case 'github':
                      return const Color(0xFF333333);
                    default:
                      return AppColors.primary;
                  }
                }

                final platformColor = getPlatformColor();

                return InkWell(
                  onTap: () => _launchUrl(entry.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: platformColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: platformColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          getIcon(),
                          size: 20,
                          color: platformColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.key.capitalize(),
                          style: TextStyle(
                            color: platformColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    if (widget.card.type == CardType.individual) {
      return _buildIndividualInfo();
    } else {
      return _buildBusinessInfo();
    }
  }

  Widget _buildIndividualInfo() {
    if (widget.card.jobTitle == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildContactTile(
              icon: Icons.work,
              title: 'Job Title',
              value: widget.card.jobTitle!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
    if (widget.card.companyName == null &&
        widget.card.businessType == null &&
        widget.card.yearFounded == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppColors.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (widget.card.companyName != null)
                  _buildContactTile(
                    icon: Icons.business,
                    title: 'Company',
                    value: widget.card.companyName!,
                  ),
                if (widget.card.businessType != null) ...[
                  const SizedBox(height: 16),
                  _buildContactTile(
                    icon: Icons.category,
                    title: 'Business Type',
                    value: widget.card.businessType!,
                  ),
                ],
                if (widget.card.yearFounded != null) ...[
                  const SizedBox(height: 16),
                  _buildContactTile(
                    icon: Icons.calendar_today,
                    title: 'Year Founded',
                    value: widget.card.yearFounded.toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCard() async {
    setState(() => _isLoading = true);
    try {
      await Share.share(
        '''${widget.card.name}'s Digital Card

${widget.card.type.name.toUpperCase()}
${widget.card.email}
${widget.card.phone ?? ''}
${widget.card.website ?? ''}

Scan the QR code to save this contact.''',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
