import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isUrdu = languageProvider.isUrdu;
    final provider = context.watch<NotificationProvider>();
    final auth = AuthService();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'نوٹیفیکیشنز' : 'Notifications'),
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: provider.markAllRead,
              child: Text(
                isUrdu ? 'سب پڑھیں' : 'Mark all read',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: Column(
          children: [
            // Admin pending requests banner
            if (isAdmin && provider.pendingRequestCount > 0)
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.orange.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isUrdu
                              ? '${provider.pendingRequestCount} ایڈمن درخواستیں زیر التواء ہیں — دیکھنے کے لیے ٹیپ کریں'
                              : '${provider.pendingRequestCount} admin request(s) pending — tap to review',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.orange),
                    ],
                  ),
                ),
              ),

            // Notifications list
            Expanded(
              child: provider.inAppNotifications.isEmpty
                  ? ListView(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(Icons.notifications_none,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  isUrdu
                                      ? 'کوئی نوٹیفیکیشن نہیں'
                                      : 'No notifications yet',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: provider.inAppNotifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final n = provider.inAppNotifications[idx];
                        final isRead = n['read'] == true || n['is_read'] == true;
                        final title = n['title'] ?? n['message'] ?? '';
                        final body = n['body'] ?? '';
                        final created = n['created_at'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey[200]
                                : const Color(0xFF1976D2).withOpacity(0.15),
                            child: Icon(
                              Icons.notifications,
                              color: isRead
                                  ? Colors.grey
                                  : const Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (body.isNotEmpty)
                                Text(body,
                                    style: const TextStyle(fontSize: 12)),
                              Text(
                                created.toString().length > 16
                                    ? created.toString().substring(0, 16)
                                    : created.toString(),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          isThreeLine: body.isNotEmpty,
                          tileColor: isRead ? null : Colors.blue.shade50,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
