import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../../services/supabase_service.dart';
import '../card_editor/create_card_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../card_viewer/card_viewer_screen.dart';
import '../analytics/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cardService = CardService();
  List<DigitalCard> _myCards = [];
  List<DigitalCard> _savedCards = [];
  bool _isLoading = true;
  CardType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final myCards = await _cardService.getCards();
      final savedCards = await _cardService.getSavedCards();
      if (mounted) {
        setState(() {
          _myCards = myCards;
          _savedCards = savedCards;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cards: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  List<DigitalCard> _getFilteredCards(List<DigitalCard> cards) {
    if (_selectedType == null) return cards;
    return cards.where((card) => card.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildDrawer(context),
        appBar: AppBar(
          title: const Text('Card Fusion'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'MY CARDS'),
              Tab(text: 'SAVED CARDS'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCardsList(_getFilteredCards(_myCards), isMyCards: true),
                        _buildCardsList(_getFilteredCards(_savedCards), isMyCards: false),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createCard,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedType == null,
            onSelected: (selected) {
              setState(() => _selectedType = null);
            },
          ),
          const SizedBox(width: 8),
          ...CardType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.name.toUpperCase()),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? type : null);
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCardsList(List<DigitalCard> cards, {required bool isMyCards}) {
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyCards ? Icons.credit_card : Icons.bookmark,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isMyCards
                  ? 'Create your first card'
                  : 'No saved cards yet\nScan QR codes to save cards',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  card.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(card.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.type.name.toUpperCase()),
                  if (card.jobTitle != null) Text(card.jobTitle!),
                  if (card.companyName != null) Text(card.companyName!),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  if (isMyCards) ...[
                    PopupMenuItem(
                      child: const Text('Share'),
                      onTap: () => _shareCard(card),
                    ),
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => _editCard(card),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete'),
                      onTap: () => _deleteCard(card),
                    ),
                  ] else
                    PopupMenuItem(
                      child: const Text('Remove'),
                      onTap: () => _removeSavedCard(card),
                    ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardViewerScreen(
                    card: card,
                    isSavedCard: !isMyCards,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCardScreen()),
    );

    if (result == true) {
      await _loadCards();
    }
  }

  Future<void> _editCard(DigitalCard card) async {
    // TODO: Implement edit functionality
  }

  Future<void> _deleteCard(DigitalCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _cardService.deleteCard(card.id);
        await _loadCards();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting card: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareCard(DigitalCard card) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardViewerScreen(card: card),
      ),
    );
  }

  Future<void> _removeSavedCard(DigitalCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Saved Card'),
        content: const Text('Are you sure you want to remove this saved card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _cardService.removeSavedCard(card.id);
        await _loadCards();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing card: $e')),
          );
        }
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final currentUser = SupabaseService().currentUser;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser?.email ?? ''),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (currentUser?.email?[0] ?? '?').toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan QR Code'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_card),
            title: const Text('Create New Card'),
            onTap: () {
              Navigator.pop(context);
              _createCard();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await SupabaseService().signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }
}
