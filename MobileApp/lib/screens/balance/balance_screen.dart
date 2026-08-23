import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/beneficiary_model.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final Map<String, TextEditingController> _sendAmountControllers = {};
  final Set<String> _sendingTo = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlockchainProvider>(context, listen: false).load();
    });
  }

  @override
  void dispose() {
    for (final c in _sendAmountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String beneficiaryId) {
    return _sendAmountControllers.putIfAbsent(beneficiaryId, () => TextEditingController());
  }

  void _copy(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendToBeneficiary(BeneficiaryModel beneficiary) async {
    final controller = _controllerFor(beneficiary.beneficiaryId);
    final amount = double.tryParse(controller.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez un montant valide'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _sendingTo.add(beneficiary.beneficiaryId));
    final provider = Provider.of<BlockchainProvider>(context, listen: false);
    final error = await provider.sendTransaction(toAddress: beneficiary.address, amount: amount);
    if (!mounted) return;
    setState(() => _sendingTo.remove(beneficiary.beneficiaryId));

    if (error == null) {
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${amount.toStringAsFixed(2)} CCT envoyés à ${beneficiary.label}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeBeneficiary(BeneficiaryModel beneficiary) async {
    final provider = Provider.of<BlockchainProvider>(context, listen: false);
    await provider.removeBeneficiary(beneficiary.beneficiaryId);
  }

  void _showAddBeneficiaryDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ajouter un bénéficiaire'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du bénéficiaire',
                    hintText: 'Ex : Marie Dupont',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse blockchain',
                    hintText: '0x...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Adresse requise';
                    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(v.trim())) {
                      return 'Adresse invalide (format 0x...)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      final provider = Provider.of<BlockchainProvider>(context, listen: false);
                      final success = await provider.addBeneficiary(
                        labelController.text.trim(),
                        addressController.text.trim(),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.error ?? 'Échec de l\'ajout'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final referralCode = Provider.of<AuthProvider>(context).currentUser?.referralCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<BlockchainProvider>(context, listen: false).load(),
          ),
        ],
      ),
      body: Consumer<BlockchainProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.wallet == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => provider.load(), child: const Text('Réessayer')),
                ],
              ),
            );
          }

          final wallet = provider.wallet!;

          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Carte solde
                Card(
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '${wallet.balance.toStringAsFixed(4)} CCT',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        if (wallet.blockchainAddress != null) ...[
                          const SizedBox(height: 16),
                          const Text('Adresse blockchain', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  wallet.blockchainAddress!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                                onPressed: () => _copy(wallet.blockchainAddress!, 'Adresse copiée'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Carte code de parrainage
                if (referralCode != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mon code de parrainage',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Partagez ce code : il permet à un(e) étudiant(e) de créer son compte.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    referralCode,
                                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _copy(referralCode, 'Code copié !'),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copier'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Étudiants aidés', value: '${wallet.stats.helpedCount}')),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(label: 'CCT gagnés', value: wallet.stats.totalEarned.toStringAsFixed(0))),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(label: 'Requêtes créées', value: '${wallet.stats.requestsCreated}')),
                  ],
                ),
                const SizedBox(height: 24),

                // Bénéficiaires
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bénéficiaires',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showAddBeneficiaryDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.beneficiaries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aucun bénéficiaire enregistré pour le moment.'),
                  )
                else
                  ...provider.beneficiaries.map((b) {
                    final controller = _controllerFor(b.beneficiaryId);
                    final sending = _sendingTo.contains(b.beneficiaryId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(b.shortAddress,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeBeneficiary(b),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: 'Montant CCT',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: sending ? null : () => _sendToBeneficiary(b),
                                  child: sending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Envoyer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Historique des transactions
                Text('Historique des transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (wallet.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aucune transaction pour le moment'),
                  )
                else
                  ...wallet.transactions.map((t) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(t.description),
                          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(t.date.toLocal())),
                          trailing: Text(
                            '${t.isPositive ? '+' : ''}${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: t.isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
