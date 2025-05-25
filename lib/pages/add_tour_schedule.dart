import 'package:flutter/material.dart';
import 'package:travel_app/services/api_service.dart';

class AddTourSchedule extends StatefulWidget {
  final Map<String, dynamic> user;

  const AddTourSchedule({super.key, required this.user});

  @override
  State<AddTourSchedule> createState() => _AddTourScheduleState();
}

class _AddTourScheduleState extends State<AddTourSchedule> {
  final _formKey = GlobalKey<FormState>();
  final _agencyIdController = TextEditingController();
  final _placeIdController = TextEditingController();
  final _tourDateController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _tourDateController.text = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitTourSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService().addTourSchedule(
        int.parse(_agencyIdController.text),
        int.parse(_placeIdController.text),
        _tourDateController.text,
        double.parse(_priceController.text),
        _descriptionController.text.trim(),
        widget.user['id'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tour schedule added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding tour schedule: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Tour Schedule',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF273671),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _agencyIdController,
                  decoration: InputDecoration(
                    labelText: 'Agency ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.trim().isEmpty ? 'Enter agency ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _placeIdController,
                  decoration: InputDecoration(
                    labelText: 'Place ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.trim().isEmpty ? 'Enter place ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tourDateController,
                  decoration: InputDecoration(
                    labelText: 'Tour Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                  ),
                  readOnly: true,
                  validator: (value) => value!.trim().isEmpty ? 'Select a tour date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (USD)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Enter price';
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTourSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF273671),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Add Tour Schedule',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}