import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';

/// 3-step checkout flow: Cart Review → Address → Slot Selection → Payment → Confirmation
class CheckoutFlowScreen extends StatefulWidget {
  const CheckoutFlowScreen({super.key});

  @override
  State<CheckoutFlowScreen> createState() => _CheckoutFlowScreenState();
}

class _CheckoutFlowScreenState extends State<CheckoutFlowScreen> {
  int _currentStep = 0;
  String? _selectedSlot;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    
    try {
      final cart = context.read<CartProvider>();
      
      // Create sales order in Firestore
      final orderData = {
        'customerId': 'demo_customer',
        'orderNumber': 'SO-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'status': 'pending',
        'items': cart.items.values.map((item) => {
          'productId': item.productId,
          'productName': item.title,
          'quantity': item.quantity,
          'unitPrice': item.price,
          'total': item.price * item.quantity,
        }).toList(),
        'deliveryAddress': _addressController.text,
        'deliverySlot': _selectedSlot,
        'paymentMethod': _selectedPaymentMethod,
        'subtotal': cart.totalAmount,
        'total': cart.totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await FirebaseFirestore.instance
          .collection('sales_orders')
          .add(orderData);
      
      // Clear cart
      cart.clear();
      
      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Order Placed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your order has been placed successfully.'),
                const SizedBox(height: 16),
                Text(
                  'Order ID: ${docRef.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('We\'ll notify you once your order is confirmed.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to shop
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.itemCount == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Your cart is empty'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          // Stepper header
          _buildStepIndicator(),
          
          const Divider(height: 1),
          
          // Step content
          Expanded(
            child: _buildStepContent(cart),
          ),
          
          // Bottom navigation
          _buildBottomNavigation(cart),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStepCircle(0, 'Cart', Icons.shopping_cart),
          _buildStepLine(0),
          _buildStepCircle(1, 'Address', Icons.location_on),
          _buildStepLine(1),
          _buildStepCircle(2, 'Payment', Icons.payment),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
      ),
    );
  }

  Widget _buildStepContent(CartProvider cart) {
    switch (_currentStep) {
      case 0:
        return _buildCartReview(cart);
      case 1:
        return _buildAddressStep();
      case 2:
        return _buildPaymentStep(cart);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCartReview(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Review Your Order',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        ...cart.items.values.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item.title),
            subtitle: Text('\$${item.price.toStringAsFixed(2)} × ${item.quantity}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => cart.removeSingleItem(item.productId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item.quantity}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => cart.addItem(item.productId, item.title, item.price),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('\$${cart.totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery'),
                    Text('FREE'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
            hintText: 'Enter your delivery address',
            prefixIcon: Icon(Icons.home),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City *',
            hintText: 'Enter city',
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _postalCodeController,
          decoration: const InputDecoration(
            labelText: 'Postal Code *',
            hintText: 'Enter postal code',
            prefixIcon: Icon(Icons.local_post_office),
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Delivery Slot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        ...['Morning (9AM - 12PM)', 'Afternoon (12PM - 3PM)', 'Evening (3PM - 6PM)']
            .map((slot) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    title: Text(slot),
                    value: slot,
                    groupValue: _selectedSlot,
                    onChanged: (value) => setState(() => _selectedSlot = value),
                  ),
                )),
      ],
    );
  }

  Widget _buildPaymentStep(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: const Text('Cash on Delivery'),
            subtitle: const Text('Pay when you receive your order'),
            value: 'COD',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            secondary: const Icon(Icons.money),
          ),
        ),
        
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: const Text('Bank Transfer'),
            subtitle: const Text('Transfer to our bank account'),
            value: 'BANK_TRANSFER',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            secondary: const Icon(Icons.account_balance),
          ),
        ),
        
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            title: const Text('Credit/Debit Card'),
            subtitle: const Text('Pay securely with your card'),
            value: 'CARD',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            secondary: const Icon(Icons.credit_card),
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items: ${cart.itemCount}'),
                const SizedBox(height: 8),
                Text('Delivery: ${_selectedSlot ?? 'Not selected'}'),
                const SizedBox(height: 8),
                Text('Payment: ${_selectedPaymentMethod ?? 'Not selected'}'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () {
                  if (_currentStep == 0) {
                    setState(() => _currentStep++);
                  } else if (_currentStep == 1) {
                    if (_addressController.text.isEmpty ||
                        _cityController.text.isEmpty ||
                        _postalCodeController.text.isEmpty ||
                        _selectedSlot == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete all fields'),
                        ),
                      );
                      return;
                    }
                    setState(() => _currentStep++);
                  } else if (_currentStep == 2) {
                    if (_selectedPaymentMethod == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a payment method'),
                        ),
                      );
                      return;
                    }
                    _placeOrder();
                  }
                },
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
