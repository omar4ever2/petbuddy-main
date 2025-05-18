import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';

// Custom input formatter for credit card numbers
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 16 digits (most card numbers)
    if (value.length > 16) {
      value = value.substring(0, 16);
    }

    // Format with spaces after every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(value[i]);
    }

    final String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Custom input formatter for expiry date
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 4 digits (MMYY)
    if (value.length > 4) {
      value = value.substring(0, 4);
    }

    // Format as MM/YY
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i == 2 && i < value.length) {
        buffer.write('/');
      }
      buffer.write(value[i]);
    }

    final String formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  String _paymentMethod = 'Credit Card';
  String _cardType = '';

  final List<String> _paymentMethods = [
    'Credit Card',
    'Cash on Delivery',
    'Apple Pay',
    'Google Pay',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  // Credit card type detection
  void _updateCardType(String cardNumber) {
    setState(() {
      if (cardNumber.startsWith('4')) {
        _cardType = 'Visa';
      } else if (cardNumber.startsWith('5')) {
        _cardType = 'MasterCard';
      } else if (cardNumber.startsWith('3')) {
        _cardType = 'Amex';
      } else if (cardNumber.startsWith('6')) {
        _cardType = 'Discover';
      } else {
        _cardType = '';
      }
    });
  }

  // Format card number with spaces
  String _formatCardNumber(String text) {
    if (text.isEmpty) return '';

    // Remove all non-digits
    text = text.replaceAll(RegExp(r'\D'), '');

    // Insert a space after every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  // Validate card number using Luhn algorithm
  bool _validateCardNumber(String cardNumber) {
    // Remove spaces and non-digits
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cardNumber.isEmpty) return false;

    // Check length (13-19 digits for most cards)
    if (cardNumber.length < 13 || cardNumber.length > 19) return false;

    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  // Validate expiry date
  bool _validateExpiryDate(String expiry) {
    if (expiry.length != 5) return false;

    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    try {
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');

      final now = DateTime.now();
      final cardDate = DateTime(year, month + 1, 0);

      return month >= 1 && month <= 12 && cardDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // Format expiry date
  String _formatExpiryDate(String text) {
    text = text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 2) {
      return '${text.substring(0, 2)}/${text.substring(2, min(4, text.length))}';
    }
    return text;
  }

  // Helper function for min
  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Calculate cart totals
    final subtotal = cartProvider.totalAmount;
    const shipping = 15.0;
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      ),
      body: cartProvider.itemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to checkout',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 40, 108, 100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Back to Cart'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal (${cartProvider.itemCount} items)',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                'LE ${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shipping',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                'LE ${shipping.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'LE ${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 40, 108, 100),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Shipping information
                    Text(
                      'Shipping Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.home_outlined),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : null,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Payment method
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.payment),
                        filled: isDarkMode,
                        fillColor: isDarkMode ? Colors.grey[800] : null,
                      ),
                      dropdownColor:
                          isDarkMode ? Colors.grey[800] : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      items: _paymentMethods.map((method) {
                        IconData icon;
                        switch (method) {
                          case 'Credit Card':
                            icon = Icons.credit_card;
                            break;
                          case 'Cash on Delivery':
                            icon = Icons.money;
                            break;
                          case 'Apple Pay':
                            icon = Icons.apple;
                            break;
                          case 'Google Pay':
                            icon = Icons.g_mobiledata;
                            break;
                          default:
                            icon = Icons.payment;
                        }

                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 20,
                                  color: isDarkMode ? Colors.grey[300] : null),
                              const SizedBox(width: 8),
                              Text(method),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_paymentMethod == 'Credit Card')
                      Column(
                        children: [
                          TextFormField(
                            controller: _cardNumberController,
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.credit_card),
                              hintText: '•••• •••• •••• ••••',
                              filled: isDarkMode,
                              fillColor: isDarkMode ? Colors.grey[800] : null,
                              labelStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[300] : null,
                              ),
                              hintStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[500] : null,
                              ),
                              suffixIcon: _cardType.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(_cardType,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                          )),
                                    )
                                  : null,
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                              _CardNumberInputFormatter(),
                            ],
                            validator: (value) {
                              if (_paymentMethod == 'Credit Card') {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your card number';
                                }
                                if (!_validateCardNumber(value)) {
                                  return 'Please enter a valid card number';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateCardType(value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We accept Visa, MasterCard, Amex, and Discover',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cardExpiryController,
                                  decoration: InputDecoration(
                                    labelText: 'Expiry Date',
                                    border: const OutlineInputBorder(),
                                    hintText: 'MM/YY',
                                    filled: isDarkMode,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : null,
                                    labelStyle: TextStyle(
                                      color:
                                          isDarkMode ? Colors.grey[300] : null,
                                    ),
                                    hintStyle: TextStyle(
                                      color:
                                          isDarkMode ? Colors.grey[500] : null,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryDateInputFormatter(),
                                  ],
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (_paymentMethod == 'Credit Card') {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (!_validateExpiryDate(value)) {
                                        return 'Invalid date';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _cardCvvController,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    border: const OutlineInputBorder(),
                                    hintText: '•••',
                                    filled: isDarkMode,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : null,
                                    labelStyle: TextStyle(
                                      color:
                                          isDarkMode ? Colors.grey[300] : null,
                                    ),
                                    hintStyle: TextStyle(
                                      color:
                                          isDarkMode ? Colors.grey[500] : null,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (value) {
                                    if (_paymentMethod == 'Credit Card') {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      // CVV is typically 3 digits, 4 for Amex
                                      if (value.length < 3 ||
                                          (_cardType != 'Amex' &&
                                              value.length > 3) ||
                                          (value.length > 4)) {
                                        return 'Invalid CVV';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CVV is the 3-digit security code on the back of your card (4 digits for Amex)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.security,
                                      size: 16,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Secure Payment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your payment information is secured with industry-standard encryption.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Checkout button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 40, 108, 100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'PLACE ORDER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for credit card
    if (_paymentMethod == 'Credit Card') {
      // Remove formatting from card number
      final cardNumber =
          _cardNumberController.text.replaceAll(RegExp(r'\D'), '');

      // Check card validity using Luhn algorithm
      if (!_validateCardNumber(cardNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credit card number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check expiry date
      if (!_validateExpiryDate(_cardExpiryController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid expiry date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check CVV
      final cvv = _cardCvvController.text;
      if (cvv.length < 3 ||
          (_cardType != 'Amex' && cvv.length > 3) ||
          cvv.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid CVV'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get cart provider and supabase service
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      // Check if cart is not empty
      if (cartProvider.items.isEmpty) {
        throw Exception('Your cart is empty');
      }

      // Prepare shipping address data
      final shippingAddress = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
      };

      // Calculate totals
      final subtotal = cartProvider.totalAmount;
      const shipping = 15.0;
      final total = subtotal + shipping;

      // Add payment information if using credit card
      Map<String, dynamic> paymentInfo = {};

      if (_paymentMethod == 'Credit Card') {
        // Never store the full credit card number, just the last 4 digits for reference
        final last4 = _cardNumberController.text
            .replaceAll(RegExp(r'\D'), '')
            .substring(_cardNumberController.text.length - 4);

        paymentInfo = {
          'card_type': _cardType,
          'card_last4': last4,
          'card_expiry': _cardExpiryController.text,
        };
      }

      // Prepare order items
      final orderItems = cartProvider.items.entries.map((entry) {
        return {
          'product_id': entry.key,
          'name': entry.value.name,
          'price': entry.value.price,
          'quantity': entry.value.quantity,
          'image_url': entry.value.imageUrl,
        };
      }).toList();

      // Create order data
      final orderData = {
        'total_amount': total,
        'shipping_amount': shipping,
        'payment_method': _paymentMethod,
        'payment_info': paymentInfo,
        'shipping_address': shippingAddress,
        'status': 'pending',
        'items': orderItems,
      };

      print('Submitting order with ${orderItems.length} items');

      // Send to Supabase
      final order = await supabaseService.createOrder(orderData);

      print('Order created successfully with ID: ${order['id']}');

      // Clear the cart after successful order
      cartProvider.clear();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Placed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color.fromARGB(255, 40, 108, 100),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your order has been placed successfully.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${order['id'].toString().substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 40, 108, 100),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Navigate back to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error submitting order: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
