part of '../admin_screens.dart';

class WhatsAppScreen extends StatelessWidget {
  const WhatsAppScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'WhatsApp Invoice Control',
    back: 14,
    bottom: false,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Invoice History',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Expanded(
          child: state.whatsappMessages.isEmpty
              ? const _EmptyState(
                  'No WhatsApp invoice messages found.',
                  icon: Icons.chat_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: state.whatsappMessages.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final message = state.whatsappMessages[index];
                    final status = message['status']?.toString() ?? '';
                    final color = status == 'failed'
                        ? red
                        : status == 'queued'
                        ? Colors.orange
                        : green;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: navy,
                      ),
                      title: Text(
                        message['invoice_number']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        message['recipient']?.toString() ?? '',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _statusText(status),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _dateText(
                              message['sent_at'] ?? message['created_at'],
                            ),
                            style: const TextStyle(fontSize: 9, color: muted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: PrimaryAction(
            'Send Latest Invoice',
            outlined: true,
            onPressed: () async {
              try {
                await state.resendInvoice();
                if (context.mounted) {
                  showNotice(context, 'Invoice queued for WhatsApp');
                }
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            state.storeSettings['whatsapp_enabled'] == true
                ? 'WhatsApp messaging is enabled.'
                : 'Enable WhatsApp messaging in store settings.',
            style: const TextStyle(fontSize: 9, color: muted),
          ),
        ),
      ],
    ),
  );
}
