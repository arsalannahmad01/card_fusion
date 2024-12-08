import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../config/theme.dart';
import '../../widgets/template_renderer_widget.dart';
import '../templates/card_templates_screen.dart';
import '../analytics/analytics_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' show pi;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../utils/error_handler.dart';
import '../../services/template_service.dart';

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
  final _analyticsService = AnalyticsService();
  final GlobalKey _cardKey = GlobalKey();

  late DigitalCard _selectedCard;

  // Pre-build both sides
  Widget? _frontSide;
  Widget? _backSide;

  final _templateService = TemplateService();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.card;
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

    // Initialize card sides
    _loadTemplate();
    _trackCardView();
  }

  Future<void> _loadTemplate() async {
    if (_selectedCard.template_id != null) {
      final template = await _templateService.getTemplateById(_selectedCard.template_id!);
      if (template != null && mounted) {
        _buildSides(template);
      }
    } else {
      _buildSides(_getDefaultTemplate());
    }
  }

  CardTemplate _getDefaultTemplate() {
    return CardTemplate(
      id: 'default',
      name: 'Default',
      type: 'modern',
      frontMarkup: '',
      backMarkup: '',
      styles: {
        'primaryColor': '#1E3D59',
        'secondaryColor': '#17B794',
      },
      supportedCardTypes: [_selectedCard.type.name],
    );
  }

  void _buildSides(CardTemplate template) {
    setState(() {
      _frontSide = TemplateRendererWidget(
        key: const ValueKey('front'),
        card: _selectedCard,
        template: template,
        showFront: true,
      );

      _backSide = TemplateRendererWidget(
        key: const ValueKey('back'),
        card: _selectedCard,
        template: template,
        showFront: false,
      );
      _isInitialized = true;
    });
  }

  Future<void> _trackCardView() async {
    final currentUser = _authService.currentUser;
    // Only track view if viewing someone else's card
    if (currentUser?.id != widget.card.userId) {
      try {
        await _analyticsService.trackEvent(
          cardId: widget.card.id,
          eventType: CardAnalyticEvent.view,
          scannerId: currentUser?.id,
          metadata: {
            'device_type': 'mobile',
            'platform': 'flutter',
            'source': widget.isSavedCard ? 'saved_cards' : 'scan',
            'viewer_email': currentUser?.email,
          },
        );
      } catch (e) {
        debugPrint('Error tracking card view: $e');
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_flipController.isAnimating) return;

    if (_isFrontVisible) {
      _flipController.forward().then((_) {
        if (mounted) {
          setState(() => _isFrontVisible = false);
        }
      });
    } else {
      _flipController.reverse().then((_) {
        if (mounted) {
          setState(() => _isFrontVisible = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
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
                decoration: const BoxDecoration(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardPreview(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            sliver: SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContactInfo(),
                if (widget.card.socialLinks?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 24),
                  _buildSocialLinks(),
                ],
                const SizedBox(height: 24),
                _buildAdditionalInfo(),
                const SizedBox(height: 24), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    if (_frontSide == null || _backSide == null) {
      _loadTemplate();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 32;
    final cardHeight = cardWidth / 1.75;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: GestureDetector(
              onTap: _toggleCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;

                  return Stack(
                    children: [
                      // Front side
                      Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: _flipAnimation.value <= 0.5
                            ? _frontSide!
                            : const SizedBox.shrink(),
                      ),
                      // Back side
                      Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateY(angle - pi),
                        alignment: Alignment.center,
                        child: _flipAnimation.value > 0.5
                            ? _backSide!
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 16,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 8),
            Text(
              'Tap card to flip',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isOwner = _authService.currentUser?.id == widget.card.userId;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 56) /
        (isOwner ? 3 : 1); // 56 = total horizontal padding and spacing

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (isOwner) ...[
                SizedBox(
                  width: buttonWidth,
                  child: _buildActionButton(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AnalyticsScreen(initialCard: widget.card),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: _buildActionButton(
                    icon: Icons.style,
                    label: 'Templates',
                    onTap: () async {
                      final updatedCard = await Navigator.push<DigitalCard>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardTemplatesScreen(
                            card: _selectedCard ?? widget.card,
                          ),
                        ),
                      );

                      if (updatedCard != null && mounted) {
                        _updateCard(updatedCard);
                      }
                    },
                  ),
                ),
              ],
              SizedBox(
                width: buttonWidth,
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _shareCard,
                ),
              ),
            ],
          );
        },
      ),
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
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
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
            child: const Row(
              children: [
                Icon(
                  Icons.contact_mail,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
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
            child: const Row(
              children: [
                Icon(
                  Icons.share,
                  color: AppColors.secondary,
                  size: 24,
                ),
                SizedBox(width: 12),
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
            child: const Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
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
            child: const Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppColors.secondary,
                  size: 24,
                ),
                SizedBox(width: 12),
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
      // Capture front card
      final frontBytes = await _captureCard(_cardKey);
      if (frontBytes == null) {
        throw AppError(
          message: 'Failed to capture front side of card. Please try again.',
          type: ErrorType.capture,
        );
      }
      final frontFile = await _saveImageToTemp(frontBytes, 'front_card.png');

      // Flip card and wait for animation
      _toggleCard();
      await Future.delayed(const Duration(milliseconds: 1000));

      // Capture back card
      final backBytes = await _captureCard(_cardKey);
      if (backBytes == null) {
        throw AppError(
          message: 'Failed to capture back side of card. Please try again.',
          type: ErrorType.capture,
        );
      }
      final backFile = await _saveImageToTemp(backBytes, 'back_card.png');

      // For Android, we need to ensure proper file paths and MIME types
      final List<String> filePaths = [frontFile.path, backFile.path];

      final shareText = '''${widget.card.name}'s Digital Card
      
${widget.card.type.name.toUpperCase()}
${widget.card.email}
${widget.card.phone ?? ''}
${widget.card.website ?? ''}''';

      try {
        if (Platform.isAndroid) {
          await Share.shareXFiles(
            filePaths.map((path) => XFile(path)).toList(),
            text: shareText,
          );
        } else {
          await Share.shareFiles(
            filePaths,
            text: shareText,
          );
        }
      } catch (e) {
        throw AppError(
          message: 'Failed to share card. Please try again.',
          type: ErrorType.sharing,
          originalError: e,
        );
      }

      // Flip card back if needed
      if (!_isFrontVisible) {
        _toggleCard();
      }
    } catch (e, stackTrace) {
      final error = AppError.handleError(e, stackTrace);
      if (mounted) {
        ErrorDisplay.showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List?> _captureCard(GlobalKey key) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw AppError(
          message: 'Failed to find card boundary. Please try again.',
          type: ErrorType.capture,
        );
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw AppError(
          message: 'Failed to process card image. Please try again.',
          type: ErrorType.capture,
        );
      }

      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to capture card image. Please try again.',
        type: ErrorType.capture,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<File> _saveImageToTemp(Uint8List bytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e, stackTrace) {
      throw AppError(
        message: 'Failed to save card image. Please check storage permissions.',
        type: ErrorType.storage,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      Uri? uri;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        uri = Uri.parse(url);
      } else if (url.startsWith('tel:')) {
        uri = Uri.parse(url);
      } else if (url.startsWith('mailto:')) {
        uri = Uri.parse(url);
      } else if (url.contains('@')) {
        uri = Uri.parse('mailto:$url');
      } else if (url.startsWith(RegExp(r'[\d+]'))) {
        uri = Uri.parse('tel:$url');
      } else {
        uri = Uri.parse('https://$url');
      }

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      )) {
        if (mounted) {
          ErrorDisplay.showError(
            context,
            AppError(
              message: 'Could not launch: $url',
              type: ErrorType.unknown,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        final error = AppError.handleError(e, stackTrace);
        ErrorDisplay.showError(context, error);
      }
    }
  }

  void _updateCard(DigitalCard updatedCard) {
    setState(() {
      _selectedCard = updatedCard;
      _loadTemplate();
    });
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
