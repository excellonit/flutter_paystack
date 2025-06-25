import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/src/models/checkout_response.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  bool isProcessing = false;
  String confirmationMessage = 'Do you want to cancel payment?';
  bool alwaysPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(getPopReturnValue());
        }
      },
      child: buildChild(context),
    );
  }

  Widget buildChild(BuildContext context);

  Future<bool> _onWillPop() async {
    if (isProcessing) {
      return false;
    }

    var returnValue = getPopReturnValue();
    if (alwaysPop ||
        (returnValue != null && (returnValue is CheckoutResponse && returnValue.status == true))) {
      return true; // Allow pop
    }

    var text = Text(confirmationMessage);
    var dialog = Platform.isIOS
        ? CupertinoAlertDialog(
            content: text,
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('Yes'),
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              CupertinoDialogAction(
                child: const Text('No'),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          )
        : AlertDialog(
            content: text,
            actions: <Widget>[
              TextButton(
                child: const Text('NO'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('YES'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );

    bool exit =
        await showDialog<bool>(context: context, builder: (BuildContext context) => dialog) ??
        false;
    return exit;
  }

  void onCancelPress() async {
    bool close = await _onWillPop();
    if (close) {
      Navigator.of(context).pop(getPopReturnValue());
    }
  }

  getPopReturnValue() {
    return null;
  }
}
