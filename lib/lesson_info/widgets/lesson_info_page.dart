import 'package:editable/editable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:success_academy/lesson_info/services/lesson_info_service.dart'
    as lesson_info_service;
import 'package:url_launcher/url_launcher.dart';

import '../../account/data/account_model.dart';
import '../../generated/l10n.dart';
import '../../profile/data/profile_model.dart';
import '../data/lesson_model.dart';

class LessonInfoPage extends StatefulWidget {
  const LessonInfoPage({super.key});

  @override
  State<LessonInfoPage> createState() => _LessonInfoPageState();
}

class _LessonInfoPageState extends State<LessonInfoPage> {
  bool _zoomInfoLoaded = false;
  List<LessonModel> _zoomInfo = [];

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final account = context.watch<AccountModel>();
    final lessons = await lesson_info_service.getLessons(
      includePreschool: account.userType != UserType.student ||
          account.subscriptionPlan == SubscriptionPlan.minimumPreschool,
    );
    setState(() {
      _zoomInfo = lessons;
      _zoomInfoLoaded = true;
    });
  }

  Widget _getZoomInfoView(
    UserType userType,
    SubscriptionPlan? subscriptionPlan,
  ) {
    if (userType == UserType.admin) {
      return EditableZoomInfo(
        zoomInfo: _zoomInfo,
      );
    }
    if (userType == UserType.teacher ||
        (subscriptionPlan != null &&
            subscriptionPlan != SubscriptionPlan.monthly)) {
      return CleanZoomInfo(
        zoomInfo: _zoomInfo,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            S.of(context).lessonInfo,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CleanActionButton(
                          emoji: '📅',
                          label: S.of(context).freeLessonTimeTable,
                          color: const Color(0xFF5B8DEE),
                          onPressed: () async {
                            if (!await launchUrl(
                              Uri.parse(
                                'https://drive.google.com/embeddedfolderview?id=1z5WUmx_lFVRy3YbmtEUH-tIqrwsaP8au#list',
                              ),
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    content:
                                        Text(S.of(context).openLinkFailure),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CleanActionButton(
                          emoji: '📚',
                          label: S.of(context).freeLessonMaterials,
                          color: const Color(0xFFFF8C42),
                          onPressed: () async {
                            if (!await launchUrl(
                              Uri.parse(
                                'https://drive.google.com/embeddedfolderview?id=1EMhq3GkTEfsk5NiSHpqyZjS4H2N_aSak#list',
                              ),
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    content:
                                        Text(S.of(context).openLinkFailure),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: !_zoomInfoLoaded
                      ? const Center(child: CircularProgressIndicator())
                      : _getZoomInfoView(
                          account.userType,
                          account.subscriptionPlan,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CleanActionButton extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CleanActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_CleanActionButton> createState() => _CleanActionButtonState();
}

class _CleanActionButtonState extends State<_CleanActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        decoration: BoxDecoration(
          color: _isHovered 
              ? widget.color.withOpacity(0.08) 
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? widget.color 
                : widget.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CleanZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;

  const CleanZoomInfo({
    super.key,
    required this.zoomInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Text(
            S.of(context).freeLessonZoomInfo,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ...zoomInfo.map((lesson) => _CleanLessonCard(lesson: lesson)).toList(),
      ],
    );
  }
}

class _CleanLessonCard extends StatefulWidget {
  final LessonModel lesson;

  const _CleanLessonCard({required this.lesson});

  @override
  State<_CleanLessonCard> createState() => _CleanLessonCardState();
}

class _CleanLessonCardState extends State<_CleanLessonCard> {
  bool _isHovered = false;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final locale = context.read<AccountModel>().locale;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✓ ', style: TextStyle(fontSize: 16)),
            Text(locale == 'ja' ? '$labelをコピーしました' : '$label copied'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4CAF50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? const Color(0xFF5B8DEE).withOpacity(0.3) 
                : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B8DEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🎓',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.lesson.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (!await launchUrl(Uri.parse(widget.lesson.zoomLink))) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              content: Text(S.of(context).openLinkFailure),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🎥',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Builder(
                            builder: (context) {
                              final locale = context.select<AccountModel, String>((a) => a.locale);
                              return Text(
                                locale == 'ja' ? 'Zoomに参加する' : 'Join Zoom',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('ℹ️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final locale = context.select<AccountModel, String>((a) => a.locale);
                            return Text(
                              locale == 'ja' ? 'レッスン情報' : 'Lesson Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final locale = context.select<AccountModel, String>((a) => a.locale);
                        return _CleanInfoRow(
                          label: locale == 'ja' ? 'ミーティングID' : 'Meeting ID',
                          value: widget.lesson.zoomId,
                          emoji: '🔢',
                          color: const Color(0xFF7C4DFF),
                          onCopy: () => _copyToClipboard(
                            context,
                            widget.lesson.zoomId,
                            locale == 'ja' ? 'ミーティングID' : 'Meeting ID',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final locale = context.select<AccountModel, String>((a) => a.locale);
                        return _CleanInfoRow(
                          label: locale == 'ja' ? 'パスワード' : 'Password',
                          value: widget.lesson.zoomPassword,
                          emoji: '🔒',
                          color: const Color(0xFFFF8C42),
                          onCopy: () => _copyToClipboard(
                            context,
                            widget.lesson.zoomPassword,
                            locale == 'ja' ? 'パスワード' : 'Password',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CleanInfoRow extends StatefulWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;
  final VoidCallback onCopy;

  const _CleanInfoRow({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
    required this.onCopy,
  });

  @override
  State<_CleanInfoRow> createState() => _CleanInfoRowState();
}

class _CleanInfoRowState extends State<_CleanInfoRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered 
                ? widget.color.withOpacity(0.4) 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: widget.onCopy,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('📋', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;

  const ZoomInfo({
    super.key,
    required this.zoomInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          S.of(context).freeLessonZoomInfo,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(
          width: 1000,
          child: PaginatedDataTable(
            rowsPerPage: 3,
            columns: <DataColumn>[
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).lesson,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).link,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).meetingId,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    S.of(context).password,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
            source: _ZoomInfoDataSource(context: context, data: zoomInfo),
          ),
        )
      ],
    );
  }
}

class _ZoomInfoDataSource extends DataTableSource {
  final BuildContext context;
  final List<LessonModel> data;

  _ZoomInfoDataSource({
    required this.context,
    required this.data,
  });

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int i) {
    return DataRow(
      cells: [
        DataCell(Text(data[i].name)),
        DataCell(
          InkWell(
            child: const Text(
              'Zoom',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.blue,
              ),
            ),
            onTap: () async {
              if (!await launchUrl(Uri.parse(data[i].zoomLink))) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      content: Text(S.of(context).openLinkFailure),
                    ),
                  );
                }
              }
            },
          ),
        ),
        DataCell(Text(data[i].zoomId)),
        DataCell(Text(data[i].zoomPassword)),
      ],
    );
  }
}

class EditableZoomInfo extends StatelessWidget {
  final List<LessonModel> zoomInfo;

  const EditableZoomInfo({
    super.key,
    required this.zoomInfo,
  });

  @override
  Widget build(BuildContext context) {
    final headers = [
      {
        'title': S.of(context).lesson,
        'widthFactor': 0.15,
        'index': 1,
        'key': 'name',
      },
      {
        'title': S.of(context).link,
        'widthFactor': 0.3,
        'index': 2,
        'key': 'zoom_link',
      },
      {
        'title': S.of(context).meetingId,
        'widthFactor': 0.1,
        'index': 3,
        'key': 'zoom_id',
      },
      {
        'title': S.of(context).password,
        'index': 4,
        'key': 'zoom_pw',
      },
    ];

    return Column(
      children: [
        Text(
          S.of(context).freeLessonZoomInfo,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(
          height: 500,
          child: Editable(
            columns: headers,
            rows: zoomInfo.map((lesson) => lesson.toJson()).toList(),
            showSaveIcon: true,
            saveIconColor: Theme.of(context).primaryColor,
            onRowSaved: (value) async {
              if (value == 'no edit') {
                return;
              }

              final i = value['row'];
              value.remove('row');

              value.forEach((k, v) {
                switch (k) {
                  case 'name':
                    zoomInfo[i].name = v;
                    break;
                  case 'zoom_link':
                    zoomInfo[i].zoomLink = v;
                    break;
                  case 'zoom_id':
                    zoomInfo[i].zoomId = v;
                    break;
                  case 'zoom_pw':
                    zoomInfo[i].zoomPassword = v;
                    break;
                }
              });
              try {
                await lesson_info_service.updateLesson(
                  zoomInfo[i].id,
                  zoomInfo[i],
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        S.of(context).lessonInfoUpdated,
                      ),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Failed to update lesson info: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).lessonInfoUpdateFailed),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            onSubmitted: ((value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    S.of(context).promptSave,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
