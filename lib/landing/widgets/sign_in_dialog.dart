import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/account/data/account_model.dart';
import 'package:success_academy/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SignInDialog extends StatelessWidget {
  const SignInDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    if (account.authStatus != AuthStatus.signedOut) {
      Navigator.of(context).pop();
    }

    return AlertDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 400,
          minHeight: 400,
          maxWidth: 500,
          maxHeight: 550,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SignInScreen(
                showAuthActionSwitch: false,
                providers: [
                  EmailAuthProvider(),
                  GoogleProvider(
                    clientId: constants.googleAuthProviderConfigurationClientId,
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://success-academy-japanese-school-eta.vercel.app/login'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('新規会員登録はこちら →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
