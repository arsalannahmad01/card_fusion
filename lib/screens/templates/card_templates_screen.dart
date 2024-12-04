import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import 'template_preview_screen.dart';
import '../../services/card_service.dart';
import '../../services/template_service.dart';
import '../../config/theme.dart';

class CardTemplatesScreen extends StatefulWidget {
  final DigitalCard card;

  const CardTemplatesScreen({super.key, required this.card});

  @override
  State<CardTemplatesScreen> createState() => _CardTemplatesScreenState();
}

class _CardTemplatesScreenState extends State<CardTemplatesScreen> with SingleTickerProviderStateMixin {
  final _cardService = CardService();
  final _templateService = TemplateService();
  late DigitalCard _selectedCard;
  List<CardTemplate> _templates = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.card;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _loadTemplates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _templateService.getTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
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
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: const Text(
                'Choose Template',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (_templates.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 80,
                      color: AppColors.secondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No templates available',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadTemplates,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final template = _templates[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTemplateCard(context, template),
                    );
                  },
                  childCount: _templates.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, CardTemplate template) {
    final isSupported = template.supportsCardType(_selectedCard.type);

    return Hero(
      tag: 'template_${template.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: isSupported
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TemplatePreviewScreen(
                            card: _selectedCard,
                            template: template,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        await _templateService.applyTemplate(_selectedCard.id, template.id);
                        final updatedCard = await _cardService.getCardById(_selectedCard.id);
                        if (updatedCard != null && mounted) {
                          Navigator.pop(context, updatedCard);
                        }
                      }
                    }
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          template.previewImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.secondary.withOpacity(0.1),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: AppColors.secondary,
                              ),
                            );
                          },
                        ),
                        if (!isSupported)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Not Available',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(template.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              template.type.name.toUpperCase(),
                              style: TextStyle(
                                color: _getTypeColor(template.type),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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

  Color _getTypeColor(TemplateType type) {
    switch (type) {
      case TemplateType.modern:
        return AppColors.primary;
      case TemplateType.classic:
        return Colors.brown;
      case TemplateType.minimal:
        return Colors.blueGrey;
      case TemplateType.bold:
        return Colors.purple;
      case TemplateType.elegant:
        return Colors.indigo;
      case TemplateType.professional:
        return Colors.teal;
    }
  }
} 