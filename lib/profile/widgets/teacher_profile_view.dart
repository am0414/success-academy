import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../account/data/account_model.dart';
import '../../calendar/widgets/calendar_view.dart';
import '../../generated/l10n.dart';

class TeacherProfileView extends StatefulWidget {
  const TeacherProfileView({super.key});

  @override
  State<TeacherProfileView> createState() => _TeacherProfileViewState();
}

class _TeacherProfileViewState extends State<TeacherProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.person),
              text: S.of(context).profile,
            ),
            Tab(
              icon: const Icon(Icons.calendar_month),
              text: 'カレンダー', // Calendar
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProfileTab(),
              CalendarView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(
                  account.teacherProfile!.lastName[0],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${account.teacherProfile!.lastName}, ${account.teacherProfile!.firstName}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                S.of(context).teacher,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Divider(),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${S.of(context).myCode} - ',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: account.myUser?.referralCode,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: account.myUser!.referralCode,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.of(context).copied),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
