import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/profile/services/profile_service.dart'
    as profile_service;
import 'package:success_academy/profile/services/purchase_service.dart'
    as stripe_service;

import '../../account/data/account_model.dart';
import '../../constants.dart' as constants;
import '../../generated/l10n.dart';
import '../data/profile_model.dart';
import 'create_subscription_form.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  bool _redirectClicked = false;
  bool _isReferral = false;
  String? _referrer;
  SubscriptionPlan _subscriptionPlan = SubscriptionPlan.minimum;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✓ ', style: TextStyle(fontSize: 16, color: Colors.white)),
            Text('$labelをコピーしました', style: const TextStyle(color: Colors.white)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4CAF50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ヘッダー
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).profile,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B8DEE), Color(0xFF7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B8DEE).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      account.studentProfile = null;
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔄', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            S.of(context).switchProfile,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // プロフィールカード
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // アバターセクション
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5B8DEE), Color(0xFF7C4DFF)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  account.studentProfile!.lastName[0],
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5B8DEE),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${account.studentProfile!.lastName}, ${account.studentProfile!.firstName}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                S.of(context).student,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 情報セクション
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _InfoTile(
                              emoji: '🎂',
                              label: S.of(context).dateOfBirthLabel,
                              value: constants.dateFormatter.format(account.studentProfile!.dateOfBirth),
                              color: const Color(0xFFFF6B6B),
                            ),
                            const SizedBox(height: 12),
                            _InfoTile(
                              emoji: '⭐',
                              label: S.of(context).eventPointsLabel,
                              value: '${account.studentProfile!.numPoints}',
                              color: const Color(0xFFFFD93D),
                            ),
                            const SizedBox(height: 12),
                            _InfoTileWithCopy(
                              emoji: '🎫',
                              label: S.of(context).myCode,
                              value: account.myUser?.referralCode ?? '',
                              color: const Color(0xFF6BCB77),
                              onCopy: () => _copyToClipboard(
                                context,
                                account.myUser!.referralCode,
                                S.of(context).myCode,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoTile(
                              emoji: '👤',
                              label: S.of(context).referrerLabel,
                              value: account.studentProfile!.referrer ?? '-',
                              color: const Color(0xFF4D96FF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // サブスクリプション管理
                account.subscriptionPlan != null
                    ? _ModernManageSubscription(
                        subscriptionPlan: account.subscriptionPlan!,
                      )
                    : CreateSubscriptionForm(
                        subscriptionPlan: _subscriptionPlan,
                        onSubscriptionPlanChange: (subscription) {
                          setState(() {
                            _subscriptionPlan = subscription!;
                          });
                        },
                        redirectClicked: _redirectClicked,
                        setIsReferral: (isReferral) {
                          _isReferral = isReferral;
                        },
                        setReferrer: (name) {
                          _referrer = name;
                        },
                        onStripeSubmitClicked: () async {
                          setState(() {
                            _redirectClicked = true;
                          });
                          final updatedStudentProfile = account.studentProfile!;
                          updatedStudentProfile.referrer = _referrer;
                          try {
                            await profile_service.updateStudentProfile(
                              account.firebaseUser!.uid,
                              updatedStudentProfile,
                            );
                            account.studentProfile = updatedStudentProfile;
                            await stripe_service.startStripeSubscriptionCheckoutSession(
                              userId: account.firebaseUser!.uid,
                              profileId: account.studentProfile!.profileId,
                              subscriptionPlan: _subscriptionPlan,
                              isReferral: _isReferral,
                            );
                          } catch (e) {
                            setState(() {
                              _redirectClicked = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context).stripeRedirectFailure),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            debugPrint('Failed to start Stripe subscription checkout $e');
                          }
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTileWithCopy extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onCopy;

  const _InfoTileWithCopy({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text('📋', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernManageSubscription extends StatefulWidget {
  final SubscriptionPlan subscriptionPlan;

  const _ModernManageSubscription({
    required this.subscriptionPlan,
  });

  @override
  State<_ModernManageSubscription> createState() => _ModernManageSubscriptionState();
}

class _ModernManageSubscriptionState extends State<_ModernManageSubscription> {
  bool _redirectClicked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8F9FA),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8DEE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('💳', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).manageSubscription,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getSubscriptionPlanName(context, widget.subscriptionPlan),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B8DEE), Color(0xFF7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B8DEE).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _redirectClicked
                        ? null
                        : () {
                            setState(() {
                              _redirectClicked = true;
                            });
                            try {
                              stripe_service.redirectToStripePortal();
                            } catch (e) {
                              setState(() {
                                _redirectClicked = false;
                              });
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_redirectClicked)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Text('📝', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            S.of(context).manageSubscription,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
