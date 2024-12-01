import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../../services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardService = CardService();
  bool _isLoading = false;
  CardType _selectedType = CardType.individual;

  // Common Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  // Individual-specific Controllers
  final _ageController = TextEditingController();
  final _jobTitleController = TextEditingController();

  // Business & Company Controllers
  final _companyNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _yearFoundedController = TextEditingController();

  // Company-specific Controllers
  final _employeeCountController = TextEditingController();
  final _headquartersController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _userImageUrl;
  String? _logoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _ageController.dispose();
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _yearFoundedController.dispose();
    _employeeCountController.dispose();
    _headquartersController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService().currentUser!.id;
      final card = DigitalCard(
        id: const Uuid().v4(),
        userId: userId,
        name: _nameController.text,
        type: _selectedType,
        email: _emailController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        userImageUrl: _userImageUrl,
        logoUrl: _selectedType != CardType.individual ? _logoUrl : null,
        age: _selectedType == CardType.individual && _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
        jobTitle: _selectedType == CardType.individual
            ? _jobTitleController.text
            : null,
        companyName: _selectedType != CardType.individual
            ? _companyNameController.text
            : null,
        businessType: _selectedType != CardType.individual
            ? _businessTypeController.text
            : null,
        yearFounded: _selectedType != CardType.individual &&
                _yearFoundedController.text.isNotEmpty
            ? int.tryParse(_yearFoundedController.text)
            : null,
        employeeCount: _selectedType == CardType.company &&
                _employeeCountController.text.isNotEmpty
            ? int.tryParse(_employeeCountController.text)
            : null,
        headquarters: _selectedType == CardType.company
            ? _headquartersController.text
            : null,
        registrationNumber: _selectedType == CardType.company
            ? _registrationNumberController.text
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _cardService.createCard(card);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(bool isUserImage) async {
    try {
      // Show loading indicator
      setState(() => _isLoading = true);

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Read image bytes
      final bytes = await image.readAsBytes();
      
      // Generate a unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      
      // Upload image and get URL
      final url = await _cardService.uploadImage(fileName, bytes);

      if (mounted) {
        setState(() {
          if (isUserImage) {
            _userImageUrl = url;
          } else {
            _logoUrl = url;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Digital Card'),
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCard,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePickers(),
              const SizedBox(height: 24),
              _buildCardTypeSelector(),
              const SizedBox(height: 16),
              _buildCommonFields(),
              const SizedBox(height: 16),
              if (_selectedType == CardType.individual)
                _buildIndividualFields()
              else if (_selectedType == CardType.business)
                _buildBusinessFields()
              else
                _buildCompanyFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickers() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      image: _userImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_userImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _userImageUrl == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            if (_selectedType != CardType.individual) ...[
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: _logoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_logoUrl!),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: _logoUrl == null
                          ? const Icon(Icons.add_photo_alternate, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Logo',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeSelector() {
    return SegmentedButton<CardType>(
      segments: CardType.values
          .map((type) => ButtonSegment(
                value: type,
                label: Text(type.name.toUpperCase()),
              ))
          .toList(),
      selected: {_selectedType},
      onSelectionChanged: (Set<CardType> selection) {
        setState(() => _selectedType = selection.first);
      },
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name *',
            icon: Icon(Icons.person),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email *',
            icon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Email is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            icon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            icon: Icon(Icons.web),
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildIndividualFields() {
    return Column(
      children: [
        TextFormField(
          controller: _ageController,
          decoration: const InputDecoration(
            labelText: 'Age',
            icon: Icon(Icons.cake),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _jobTitleController,
          decoration: const InputDecoration(
            labelText: 'Job Title',
            icon: Icon(Icons.work),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessFields() {
    return Column(
      children: [
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Company Name *',
            icon: Icon(Icons.business),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Company name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _businessTypeController,
          decoration: const InputDecoration(
            labelText: 'Type of Business *',
            icon: Icon(Icons.category),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Business type is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _yearFoundedController,
          decoration: const InputDecoration(
            labelText: 'Year Founded *',
            icon: Icon(Icons.calendar_today),
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Year founded is required' : null,
        ),
      ],
    );
  }

  Widget _buildCompanyFields() {
    return Column(
      children: [
        _buildBusinessFields(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _employeeCountController,
          decoration: const InputDecoration(
            labelText: 'Number of Employees',
            icon: Icon(Icons.people),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _headquartersController,
          decoration: const InputDecoration(
            labelText: 'Headquarters Location',
            icon: Icon(Icons.location_city),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _registrationNumberController,
          decoration: const InputDecoration(
            labelText: 'Registration Number',
            icon: Icon(Icons.numbers),
          ),
        ),
      ],
    );
  }
} 