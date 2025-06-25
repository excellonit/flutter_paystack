import 'package:flutter/material.dart';
import 'package:flutter_paystack/src/common/card_utils.dart';
import 'package:flutter_paystack/src/common/utils.dart';
import 'package:flutter_paystack/src/models/card.dart';
import 'package:flutter_paystack/src/widgets/buttons.dart';
import 'package:flutter_paystack/src/widgets/input/cvc_field.dart';
import 'package:flutter_paystack/src/widgets/input/date_field.dart';
import 'package:flutter_paystack/src/widgets/input/number_field.dart';

class CardInput extends StatefulWidget {
  final String buttonText;
  final PaymentCard? card;
  final ValueChanged<PaymentCard?> onValidated;

  CardInput({Key? key, required this.buttonText, required this.card, required this.onValidated})
    : super(key: key);

  @override
  _CardInputState createState() => _CardInputState(card);
}

class _CardInputState extends State<CardInput> {
  var _formKey = GlobalKey<FormState>();
  final PaymentCard? _card;
  var _autoValidate = AutovalidateMode.disabled;
  late TextEditingController numberController;
  bool _validated = false;

  _CardInputState(this._card);

  @override
  void initState() {
    super.initState();
    numberController = TextEditingController();
    numberController.addListener(_getCardTypeFrmNumber);

    // Safe null check for card number
    final cardNumber = _card?.number;
    if (cardNumber != null) {
      numberController.text = Utils.addSpaces(cardNumber);
    }
  }

  @override
  void dispose() {
    super.dispose();
    numberController.removeListener(_getCardTypeFrmNumber);
    numberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: _autoValidate,
      key: _formKey,
      child: Column(
        children: <Widget>[
          NumberField(
            key: Key("CardNumberKey"),
            controller: numberController,
            card: _card,
            onSaved: (String? value) {
              final card = _card;
              if (card != null) {
                card.number = CardUtils.getCleanedNumber(value);
              }
            },
            suffix: getCardIcon(),
          ),
          SizedBox(height: 15.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: DateField(
                  key: ValueKey("ExpiryKey"),
                  card: _card,
                  onSaved: (value) {
                    final card = _card;
                    if (card != null) {
                      List<int> expiryDate = CardUtils.getExpiryDate(value);
                      card.expiryMonth = expiryDate[0];
                      card.expiryYear = expiryDate[1];
                    }
                  },
                ),
              ),
              SizedBox(width: 15.0),
              Flexible(
                child: CVCField(
                  key: Key("CVVKey"),
                  card: _card,
                  onSaved: (value) {
                    final card = _card;
                    if (card != null) {
                      card.cvc = CardUtils.getCleanedNumber(value);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 20.0),
          AccentButton(
            key: Key("PayButton"),
            onPressed: _validateInputs,
            text: widget.buttonText,
            showProgress: _validated,
          ),
        ],
      ),
    );
  }

  void _getCardTypeFrmNumber() {
    final card = _card;
    if (card != null) {
      String input = CardUtils.getCleanedNumber(numberController.text);
      String cardType = card.getTypeForIIN(input);
      setState(() {
        card.type = cardType;
      });
    }
  }

  void _validateInputs() {
    FocusScope.of(context).requestFocus(FocusNode());
    final FormState? form = _formKey.currentState;

    if (form != null && form.validate()) {
      form.save();
      widget.onValidated(_card);
      if (mounted) {
        setState(() => _validated = true);
      }
    } else {
      setState(() => _autoValidate = AutovalidateMode.always);
    }
  }

  Widget getCardIcon() {
    String img = "";
    var defaultIcon = Icon(
      Icons.credit_card,
      key: Key("DefaultIssuerIcon"),
      size: 15.0,
      color: Colors.grey[600],
    );

    final card = _card;
    if (card != null) {
      switch (card.type) {
        case CardType.masterCard:
          img = 'mastercard.png';
          break;
        case CardType.visa:
          img = 'visa.png';
          break;
        case CardType.verve:
          img = 'verve.png';
          break;
        case CardType.americanExpress:
          img = 'american_express.png';
          break;
        case CardType.discover:
          img = 'discover.png';
          break;
        case CardType.dinersClub:
          img = 'dinners_club.png';
          break;
        case CardType.jcb:
          img = 'jcb.png';
          break;
      }
    }

    Widget widget;
    if (img.isNotEmpty) {
      widget = Image.asset(
        'assets/images/$img',
        key: Key("IssuerIcon"),
        height: 15,
        width: 30,
        package: 'flutter_paystack',
      );
    } else {
      widget = defaultIcon;
    }
    return widget;
  }
}
