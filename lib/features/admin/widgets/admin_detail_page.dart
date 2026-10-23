import 'package:flutter/material.dart';

class AdminDetailTab {
  final String label;
  final Widget child;
  const AdminDetailTab(this.label, this.child);
}

class AdminDetailAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const AdminDetailAction(this.label, this.icon, this.onTap);
}

/// Shared, spacious detail layout for both pushed routes and the admin shell.
class AdminDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String pageLabel;
  final IconData icon;
  final Widget? leadingAvatar;
  final List<AdminDetailTab> tabs;
  final List<AdminDetailAction> actions;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;

  const AdminDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageLabel,
    required this.icon,
    this.leadingAvatar,
    required this.tabs,
    this.actions = const [],
    this.onBack,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: tabs.length,
    child: Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          pageLabel.replaceFirst(RegExp(r'^Detail '), ''),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (actions.isNotEmpty)
            PopupMenuButton<int>(
              tooltip: 'Tindakan lainnya',
              onSelected: (index) => actions[index].onTap(),
              itemBuilder: (_) => [
                for (var index = 0; index < actions.length; index++)
                  PopupMenuItem(
                    value: index,
                    child: ListTile(
                      dense: true,
                      leading: Icon(actions[index].icon),
                      title: Text(actions[index].label),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leadingAvatar ??
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFF6D28D9),
                              size: 26,
                            ),
                          ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  tabs: [for (final tab in tabs) Tab(text: tab.label)],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final tab in tabs)
                        SingleChildScrollView(
                          key: PageStorageKey(tab.label),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                          child: tab.child,
                        ),
                    ],
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

class AdminDetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const AdminDetailSection({
    super.key,
    required this.title,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          ...children,
        ],
      ),
    ),
  );
}

class AdminDetailFields extends StatelessWidget {
  final Map<String, String> fields;
  const AdminDetailFields(this.fields, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns =
          constraints.maxWidth >=
          640 * MediaQuery.textScalerOf(context).scale(1);
      return Wrap(
        spacing: 32,
        runSpacing: 28,
        children: [
          for (final entry in fields.entries)
            SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 32) / 2
                  : constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    entry.value.isEmpty ? 'Belum diisi' : entry.value,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
