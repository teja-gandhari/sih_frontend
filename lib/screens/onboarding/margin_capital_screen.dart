import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import '../../app/router.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class MarginCapitalScreen extends StatefulWidget {
  const MarginCapitalScreen({super.key});

  @override
  State<MarginCapitalScreen> createState() => _MarginCapitalScreenState();
}

class _MarginCapitalScreenState extends State<MarginCapitalScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    final appState = context.read<AppStateProvider>();
    if (appState.marginCapital != null) {
      _amountController.text = appState.marginCapital!.toInt().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords;
              // Basic hacky parse for 'one lakh', etc could go here.
              // We will just let them edit or confirm the raw text.
              _amountController.text = _recognizedText.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.get('margin_capital_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.get('how_much_contribute'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _amountController,
                        labelText: loc.get('amount'),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final num = double.tryParse(val.replaceAll(',', ''));
                          if (num == null) return 'Invalid number';
                          if (num <= 0) return 'Must be greater than 0';
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                      ),
                      onPressed: _listen,
                    ),
                  ],
                ),
                if (_amountController.text.isNotEmpty &&
                    double.tryParse(_amountController.text) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Formatted: ${_currencyFormat.format(double.parse(_amountController.text))}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                const Spacer(),
                AppButton(
                  text: loc.get('next'),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final amount = double.parse(
                        _amountController.text.replaceAll(',', ''),
                      );
                      context.read<AppStateProvider>().setMarginCapital(amount);
                      Navigator.of(
                        context,
                      ).pushNamed(AppRouter.businessCategory);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
