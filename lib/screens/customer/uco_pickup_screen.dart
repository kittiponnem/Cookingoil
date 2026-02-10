import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// UCO (Used Cooking Oil) Pickup Request screen
class UCOPickupScreen extends StatefulWidget {
  const UCOPickupScreen({super.key});

  @override
  State<UCOPickupScreen> createState() => _UCOPickupScreenState();
}

class _UCOPickupScreenState extends State<UCOPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _estimatedQtyController = TextEditingController();
  String? _selectedSlot;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _estimatedQtyController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup slot')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderData = {
        'customerId': 'demo_customer',
        'orderNumber':
            'UCO-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'status': 'requested',
        'pickupAddress': _addressController.text,
        'pickupSlot': _selectedSlot,
        'estimatedQty': double.parse(_estimatedQtyController.text),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('uco_orders')
          .add(orderData);

      if (mounted) {
        setState(() => _isSubmitting = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Request Submitted!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your UCO pickup request has been submitted.'),
                const SizedBox(height: 16),
                Text(
                  'Request ID: ${docRef.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('We\'ll contact you to confirm the pickup schedule.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request UCO Pickup'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.recycling, size: 48, color: Colors.green[700]),
                    const SizedBox(height: 12),
                    Text(
                      'Sell Your Used Cooking Oil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We pay competitive rates for quality UCO',
                      style: TextStyle(color: Colors.green[800]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Pickup Address *',
                hintText: 'Enter your address',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pickup address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedQtyController,
              decoration: const InputDecoration(
                labelText: 'Estimated Quantity (kg) *',
                hintText: 'Approximate amount',
                prefixIcon: Icon(Icons.scale),
                suffixText: 'kg',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter estimated quantity';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Preferred Pickup Slot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...['Morning (9AM - 12PM)', 'Afternoon (12PM - 3PM)', 'Evening (3PM - 6PM)']
                .map((slot) => RadioListTile<String>(
                      title: Text(slot),
                      value: slot,
                      groupValue: _selectedSlot,
                      onChanged: (value) => setState(() => _selectedSlot = value),
                    )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Request',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
