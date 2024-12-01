import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/business_card.dart';
import 'dart:io';
import 'dart:async';

class CardEditorScreen extends StatefulWidget {
  final BusinessCard? card;

  const CardEditorScreen({super.key, this.card});

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  String? _profileImagePath;
  String? _logoPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?.name);
    _jobTitleController = TextEditingController(text: widget.card?.jobTitle);
    _companyController = TextEditingController(text: widget.card?.company);
    _emailController = TextEditingController(text: widget.card?.email);
    _phoneController = TextEditingController(text: widget.card?.phone);
    _websiteController = TextEditingController(text: widget.card?.website);
    _profileImagePath = widget.card?.profileImagePath;
    _logoPath = widget.card?.logoPath;
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Library'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    _processPickedImage(image, isProfile);
                  } catch (e) {
                    debugPrint('Gallery pick error: $e');
                    _showErrorMessage('Could not access photo library');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Picture'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.rear,
                    );
                    _processPickedImage(image, isProfile);
                  } catch (e) {
                    debugPrint('Camera pick error: $e');
                    _showErrorMessage('Could not access camera');
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Modal sheet error: $e');
      _showErrorMessage('An error occurred');
    }
  }

  void _processPickedImage(XFile? image, bool isProfile) {
    if (image != null && mounted) {
      setState(() {
        if (isProfile) {
          _profileImagePath = image.path;
          debugPrint('Set profile image: $_profileImagePath');
        } else {
          _logoPath = image.path;
          debugPrint('Set logo image: $_logoPath');
        }
      });
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(true),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : null,
                child: _profileImagePath == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            TextButton(
              onPressed: () => _pickImage(true),
              child: const Text('Add Photo'),
            ),
          ],
        ),
        Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(false),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: _logoPath != null
                    ? FileImage(File(_logoPath!))
                    : null,
                child: _logoPath == null
                    ? const Icon(Icons.business, size: 40)
                    : null,
              ),
            ),
            TextButton(
              onPressed: () => _pickImage(false),
              child: const Text('Add Logo'),
            ),
          ],
        ),
      ],
    );
  }

  void _saveCard() {
    if (_formKey.currentState?.validate() ?? false) {
      final card = BusinessCard(
        id: widget.card?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        company: _companyController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        socialLinks: widget.card?.socialLinks ?? [],
        profileImagePath: _profileImagePath,
        logoPath: _logoPath,
        design: widget.card?.design ?? CardDesign(
          template: 'default',
          primaryColor: Colors.black,
          secondaryColor: Colors.white,
          fontFamily: 'Roboto',
        ),
      );
      Navigator.pop(context, card);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Create Card' : 'Edit Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              _buildTextFields(),
              const SizedBox(height: 16),
              _buildDesignSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            icon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _jobTitleController,
          decoration: const InputDecoration(
            labelText: 'Job Title',
            icon: Icon(Icons.work_outline),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your job title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyController,
          decoration: const InputDecoration(
            labelText: 'Company',
            icon: Icon(Icons.business_outlined),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your company';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            icon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            icon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website (Optional)',
            icon: Icon(Icons.web_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildDesignSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card Design',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add design customization options
          ],
        ),
      ),
    );
  }
} 