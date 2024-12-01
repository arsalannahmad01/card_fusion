import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../../services/analytics_service.dart';
import 'card_analytics_screen.dart';

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
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myCards.isEmpty
              ? const Center(child: Text('No cards available'))
              : Column(
                  children: [
                    _buildCardSelector(),
                    Expanded(
                      child: _selectedCard == null
                          ? const Center(child: Text('Select a card'))
                          : CardAnalyticsScreen(card: _selectedCard!),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCardSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedCard?.id,
            hint: const Text('Select a card'),
            items: _myCards.map((card) {
              return DropdownMenuItem(
                value: card.id,
                child: Text(
                  '${card.name} (${card.type.name})',
                  overflow: TextOverflow.ellipsis,
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