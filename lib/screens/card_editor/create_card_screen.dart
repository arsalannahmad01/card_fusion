import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../../services/supabase_service.dart';
import '../../config/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/error_display.dart';
import '../../utils/app_error.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateCardScreen extends StatefulWidget {
  final DigitalCard? card;
  const CreateCardScreen({super.key, this.card});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardService = CardService();
  final _authService = SupabaseService();
  bool _isLoading = false;
  CardType _selectedType = CardType.individual;
  String? _profileImagePath;
  String? _profileImageUrl;

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _yearFoundedController;
  late final TextEditingController _employeeCountController;
  late final TextEditingController _headquartersController;
  late final TextEditingController _registrationController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _twitterController;
  late final TextEditingController _facebookController;
  late final TextEditingController _instagramController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.card != null) {
      _populateFields();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _jobTitleController = TextEditingController();
    _companyNameController = TextEditingController();
    _businessTypeController = TextEditingController();
    _yearFoundedController = TextEditingController();
    _employeeCountController = TextEditingController();
    _headquartersController = TextEditingController();
    _registrationController = TextEditingController();
    _linkedinController = TextEditingController();
    _twitterController = TextEditingController();
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
  }

  void _populateFields() {
    final card = widget.card!;
    _selectedType = card.type;
    _nameController.text = card.name;
    _emailController.text = card.email;
    _phoneController.text = card.phone ?? '';
    _websiteController.text = card.website ?? '';
    _jobTitleController.text = card.jobTitle ?? '';
    _companyNameController.text = card.companyName ?? '';
    _businessTypeController.text = card.businessType ?? '';
    _yearFoundedController.text = card.yearFounded?.toString() ?? '';
    _employeeCountController.text = card.employeeCount?.toString() ?? '';
    _headquartersController.text = card.headquarters ?? '';
    _registrationController.text = card.registrationNumber ?? '';
    _linkedinController.text = card.socialLinks?['linkedin'] ?? '';
    _twitterController.text = card.socialLinks?['twitter'] ?? '';
    _facebookController.text = card.socialLinks?['facebook'] ?? '';
    _instagramController.text = card.socialLinks?['instagram'] ?? '';
    _profileImageUrl = card.user_image_url;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _yearFoundedController.dispose();
    _employeeCountController.dispose();
    _headquartersController.dispose();
    _registrationController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    try {
      if (!_formKey.currentState!.validate()) {
        throw AppError(
          message: 'Please fill in all required fields',
          type: ErrorType.validation,
        );
      }

      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      if (user == null) throw 'User not authenticated';

      final now = DateTime.now();
      final card = DigitalCard(
        id: widget.card?.id ?? const Uuid().v4(),
        userId: user.id,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
        type: _selectedType,
        user_image_url: _profileImageUrl,
        jobTitle: _jobTitleController.text.isEmpty ? null : _jobTitleController.text,
        companyName: _companyNameController.text.isEmpty ? null : _companyNameController.text,
        businessType: _businessTypeController.text.isEmpty ? null : _businessTypeController.text,
        yearFounded: _yearFoundedController.text.isEmpty ? null : int.parse(_yearFoundedController.text),
        employeeCount: _employeeCountController.text.isEmpty ? null : int.parse(_employeeCountController.text),
        headquarters: _headquartersController.text.isEmpty ? null : _headquartersController.text,
        registrationNumber: _registrationController.text.isEmpty ? null : _registrationController.text,
        socialLinks: {
          if (_linkedinController.text.isNotEmpty) 'linkedin': _linkedinController.text,
          if (_twitterController.text.isNotEmpty) 'twitter': _twitterController.text,
          if (_facebookController.text.isNotEmpty) 'facebook': _facebookController.text,
          if (_instagramController.text.isNotEmpty) 'instagram': _instagramController.text,
        },
        createdAt: widget.card?.createdAt ?? now,
        updatedAt: now,
        is_public: true,
        share_count: 0,
      );

      debugPrint('Creating card with data: ${card.toJson()}');

      if (widget.card == null) {
        await _cardService.createCard(card);
      } else {
        await _cardService.updateCard(card);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('Error creating card: $e');
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

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;
      
      final bytes = await pickedFile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      
      final imageUrl = await _cardService.uploadImage(fileName, bytes);
      
      setState(() {
        _profileImagePath = pickedFile.path;
        _profileImageUrl = imageUrl;
      });
    } catch (e, stackTrace) {
      final error = AppError.handleError(e, stackTrace);
      if (mounted) {
        ErrorDisplay.showError(context, error);
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
        flexibleSpace: Container(
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
        ),
        title: Text(
          widget.card == null ? 'Create Card' : 'Edit Card',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Card Type Selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Card Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: CardType.values.map((type) {
                      final isSelected = type == _selectedType;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type == CardType.individual
                                      ? Icons.person
                                      : Icons.business,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type.name.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Form Fields
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSection(
                    'Basic Information',
                    [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _profileImagePath != null 
                                ? FileImage(File(_profileImagePath!))
                                : (_profileImageUrl != null 
                                  ? NetworkImage(_profileImageUrl!) as ImageProvider
                                  : null),
                              child: _profileImagePath == null && _profileImageUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                  onPressed: _pickProfileImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        required: true,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        required: true,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        required: true,
                      ),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        icon: Icons.language_outlined,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Professional Details',
                    [
                      _buildTextField(
                        controller: _jobTitleController,
                        label: 'Job Title',
                        icon: Icons.work_outline,
                        required: _selectedType == CardType.individual,
                      ),
                      _buildTextField(
                        controller: _companyNameController,
                        label: 'Company Name',
                        icon: Icons.business_outlined,
                        required: _selectedType != CardType.individual,
                      ),
                      if (_selectedType != CardType.individual) ...[
                        _buildTextField(
                          controller: _businessTypeController,
                          label: 'Business Type',
                          icon: Icons.category_outlined,
                          required: true,
                        ),
                        _buildTextField(
                          controller: _yearFoundedController,
                          label: 'Year Founded',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          required: true,
                        ),
                        _buildTextField(
                          controller: _employeeCountController,
                          label: 'Employee Count',
                          icon: Icons.groups_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          controller: _headquartersController,
                          label: 'Headquarters',
                          icon: Icons.location_on_outlined,
                          required: _selectedType == CardType.business,
                        ),
                        _buildTextField(
                          controller: _registrationController,
                          label: 'Registration Number',
                          icon: Icons.numbers_outlined,
                          required: _selectedType == CardType.business,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Social Media Links',
                    [
                      _buildTextField(
                        controller: _linkedinController,
                        label: 'LinkedIn Profile',
                        icon: FontAwesomeIcons.linkedin,
                        keyboardType: TextInputType.url,
                      ),
                      _buildTextField(
                        controller: _twitterController,
                        label: 'Twitter/X Profile',
                        icon: FontAwesomeIcons.twitter,
                        keyboardType: TextInputType.url,
                      ),
                      _buildTextField(
                        controller: _facebookController,
                        label: 'Facebook Profile',
                        icon: FontAwesomeIcons.facebook,
                        keyboardType: TextInputType.url,
                      ),
                      _buildTextField(
                        controller: _instagramController,
                        label: 'Instagram Profile',
                        icon: FontAwesomeIcons.instagram,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Card',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
