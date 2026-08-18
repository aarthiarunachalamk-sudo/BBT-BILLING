part of '../admin_screens.dart';

class WhatsAppScreen extends StatelessWidget {
  const WhatsAppScreen(this.state, {super.key});
  final AdminState state;
  static const invoices = [
    ['BILL-2025-0145', '+91 98765 43210', '14 May, 11:20 AM', 'Sent'],
    ['BILL-2025-0144', '+91 97654 32109', '14 May, 11:05 AM', 'Delivered'],
    ['BILL-2025-0143', '+91 96543 21098', '14 May, 10:55 AM', 'Read'],
    ['BILL-2025-0142', '+91 95432 10987', '14 May, 10:45 AM', 'Pending'],
  ];
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
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: invoices.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final x = invoices[i];
              final color = x[3] == 'Pending' ? Colors.orange : green;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: navy),
                title: Text(
                  x[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(x[1], style: const TextStyle(fontSize: 10)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      x[3],
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      x[2],
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
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Resend Invoice',
                  outlined: true,
                  onPressed: () async {
                    try {
                      await state.resendInvoice();
                      if (context.mounted) {
                        showNotice(context, 'Invoice queued for WhatsApp');
                      }
                    } catch (error) {
                      if (context.mounted) {
                        showNotice(context, error.toString());
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryAction(
                  'Download PDF',
                  outlined: true,
                  onPressed: () => showNotice(context, 'PDF downloaded'),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: Text(
            'WhatsApp consent must be enabled.',
            style: TextStyle(fontSize: 9, color: muted),
          ),
        ),
      ],
    ),
  );
}
