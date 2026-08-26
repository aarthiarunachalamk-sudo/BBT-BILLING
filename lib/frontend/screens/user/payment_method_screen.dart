part of 'user_screens.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen(this.state, {super.key});
  final UserState state;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final cash = TextEditingController();
  final upi = TextEditingController();
  final card = TextEditingController();
  late final Razorpay _razorpay;
  String method = 'razorpay';
  String? _orderId;
  String? _orderToken;
  bool _startingPayment = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    cash.dispose();
    upi.dispose();
    card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UserShell(
    state: widget.state,
    title: 'Payment Method',
    showBack: true,
    backPage: UserPage.billing,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UserCard(
          child: Column(
            children: [
              const Text('Amount Payable'),
              Text(
                money(widget.state.grandTotal),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: userNavy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        RadioGroup<String>(
          groupValue: method,
          onChanged: (value) {
            if (value != null) {
              setState(() => method = value);
            }
          },
          child: Column(
            children: [
              for (final item in [
                ('razorpay', 'Razorpay Online', Icons.account_balance_wallet),
                ('upi', 'Counter UPI', Icons.qr_code),
                ('cash', 'Cash', Icons.payments_outlined),
                ('card', 'Card Terminal', Icons.credit_card),
                ('split', 'Split Payment', Icons.call_split),
              ])
                UserCard(
                  onTap: () => setState(() => method = item.$1),
                  child: Row(
                    children: [
                      Radio<String>(value: item.$1),
                      Icon(item.$3, color: userBlue),
                      const SizedBox(width: 10),
                      Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (method == 'split') ...[
          const SizedBox(height: 10),
          TextField(
            controller: cash,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cash amount'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: upi,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'UPI amount'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: card,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Card amount'),
          ),
        ],
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: widget.state.loading || _startingPayment ? null : _pay,
          child: Text(
            _startingPayment
                ? 'Starting Razorpay…'
                : 'Pay ${money(widget.state.grandTotal)}',
          ),
        ),
      ],
    ),
  );

  Future<void> _pay() async {
    if (method == 'razorpay') {
      await _startRazorpay();
      return;
    }
    late List<Map<String, dynamic>> payments;
    if (method == 'split') {
      payments = [('cash', cash.text), ('upi', upi.text), ('card', card.text)]
          .where((entry) => (double.tryParse(entry.$2) ?? 0) > 0)
          .map(
            (entry) => {'method': entry.$1, 'amount': double.parse(entry.$2)},
          )
          .toList();
      final total = payments.fold<double>(
        0,
        (sum, payment) => sum + (payment['amount'] as double),
      );
      if ((total - widget.state.grandTotal).abs() > .01) {
        _notice(
          context,
          'Split payment must exactly equal ${money(widget.state.grandTotal)}.',
        );
        return;
      }
    } else {
      payments = [
        {
          'method': method,
          'amount': widget.state.grandTotal.toStringAsFixed(2),
        },
      ];
    }
    await widget.state.checkout(payments);
  }

  Future<void> _startRazorpay() async {
    setState(() => _startingPayment = true);
    try {
      final order = await widget.state.api.post('billing/razorpay/order', {
        'amount': widget.state.grandTotal.toStringAsFixed(2),
      });
      _orderId = order['order_id']?.toString();
      _orderToken = order['order_token']?.toString();
      if (_orderId == null || _orderToken == null) {
        throw const UserApiException(
          'The server returned an invalid Razorpay order.',
        );
      }
      _razorpay.open({
        'key': order['key_id'],
        'order_id': _orderId,
        'amount': order['amount'],
        'currency': order['currency'] ?? 'INR',
        'name': 'BBT Supermarket',
        'description': 'Billing payment',
        'timeout': 300,
        'retry': {'enabled': true, 'max_count': 3},
        'prefill': {
          'contact': widget.state.user['phone']?.toString() ?? '',
          'email': widget.state.user['email']?.toString() ?? '',
        },
      });
    } on UserApiException catch (error) {
      if (mounted) _notice(context, error.message);
    } catch (_) {
      if (mounted) _notice(context, 'Could not open Razorpay. Please retry.');
    } finally {
      if (mounted) setState(() => _startingPayment = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId;
    final signature = response.signature;
    final responseOrderId = response.orderId;
    if (paymentId == null ||
        signature == null ||
        responseOrderId == null ||
        _orderToken == null ||
        responseOrderId != _orderId) {
      if (mounted) {
        _notice(
          context,
          'Razorpay confirmation was incomplete. Contact the admin.',
        );
      }
      return;
    }
    final completed = await widget.state.checkout([
      {
        'method': 'razorpay',
        'amount': widget.state.grandTotal.toStringAsFixed(2),
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': responseOrderId,
        'razorpay_signature': signature,
        'razorpay_order_token': _orderToken,
      },
    ]);
    if (!completed && mounted) {
      _notice(
        context,
        widget.state.error ??
            'Payment succeeded but invoice confirmation failed. Contact the admin.',
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      _notice(
        context,
        response.message ?? 'Razorpay payment was cancelled or failed.',
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      _notice(
        context,
        'Continue in ${response.walletName ?? 'the selected wallet'}.',
      );
    }
  }
}
