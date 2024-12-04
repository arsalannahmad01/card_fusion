import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../../services/analytics_service.dart';
import 'card_analytics_screen.dart';
import '../../config/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  final DigitalCard? initialCard;

  const AnalyticsScreen({
    super.key,
    this.initialCard,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _cardService = CardService();
  final _analyticsService = AnalyticsService();
  bool _isLoading = true;
  List<DigitalCard> _myCards = [];
  Map<String, CardAnalytics?> _analytics = {};
  DigitalCard? _selectedCard;

  @override
  void initState() {
    super.initState();
    if (widget.initialCard != null) {
      _selectedCard = widget.initialCard;
      _loadDataWithInitialCard();
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load cards
      final cards = await _cardService.getCards();
      _myCards = cards;
      
      if (cards.isNotEmpty) {
        _selectedCard = cards.first;
        // Load analytics for first card
        final analytics = await _analyticsService.getCardAnalytics(cards.first.id);
        _analytics[cards.first.id] = analytics;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadDataWithInitialCard() async {
    try {
      setState(() => _isLoading = true);
      
      // Load all cards
      final cards = await _cardService.getCards();
      _myCards = cards;
      
      // Load analytics for initial card
      final analytics = await _analyticsService.getCardAnalytics(widget.initialCard!.id);
      _analytics[widget.initialCard!.id] = analytics;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _onCardSelected(DigitalCard card) async {
    setState(() {
      _selectedCard = card;
      _isLoading = true;  // Show loading while fetching analytics
    });

    try {
      final analytics = await _analyticsService.getCardAnalytics(card.id);
      if (mounted) {
        setState(() {
          _analytics[card.id] = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading card analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: AppColors.secondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No cards available',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildCardSelector(),
                    Expanded(
                      child: _selectedCard == null
                          ? Center(
                              child: Text(
                                'Select a card to view analytics',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : CardAnalyticsScreen(card: _selectedCard!),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCardSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedCard?.id,
            hint: const Text(
              'Select a card',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: AppColors.primary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            items: _myCards.map((card) {
              return DropdownMenuItem(
                value: card.id,
                child: Text(
                  '${card.name} (${card.type.name})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (cardId) {
              if (cardId != null) {
                final selectedCard = _myCards.firstWhere((card) => card.id == cardId);
                _onCardSelected(selectedCard);
              }
            },
          ),
        ),
      ),
    );
  }
} 