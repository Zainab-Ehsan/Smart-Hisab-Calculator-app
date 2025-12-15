import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  // Use a GlobalKey for form validation
  final _formKey = GlobalKey<FormState>();

  // Logic fields remain unchanged
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  // --- LOGIC METHOD (Unchanged) ---
  Future<void> _save() async {
    // Validate the form fields using the form key
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();

    try {
      setState(() => saving = true);

      // Actual data saving logic
      await UserService.addUser(
        UserModel(username: name, email: email),
      );

      if (!mounted) return;
      // Show success message and pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User successfully added!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // ✅ tell UsersScreen to refresh
    } catch (e) {
      if (!mounted) return;
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual introduction/header
              const Text(
                'Register a new member for expense sharing.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Use a Form widget for validation
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username Field
                    TextFormField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        hintText: 'e.g., Jane Doe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      // Added basic validation logic
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        hintText: 'jane.doe@example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              ElevatedButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  saving ? 'Saving...' : 'Save User',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Make button full-width and tall
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Hint for required fields
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text('* Required field', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}