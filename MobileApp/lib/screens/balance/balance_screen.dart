import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../providers/auth_provider.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);
      blockchainProvider.loadAccounts();
    });
  }

  void _showSendDialog() {
    final _toAddressController = TextEditingController();
    final _amountController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer CCT'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _toAddressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse destinataire',
                  hintText: '0x...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adresse requise';
                  }
                  if (!value.startsWith('0x')) {
                    return 'Adresse invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant (CCT)',
                  hintText: '0.0',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Montant requis';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                
                final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);
                final success = await blockchainProvider.sendTransaction(
                  toAddress: _toAddressController.text.trim(),
                  amount: double.parse(_amountController.text),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Transaction envoyée avec succès!'
                        : 'Erreur lors de l\'envoi'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);
              blockchainProvider.refreshBalance();
            },
          ),
        ],
      ),
      body: Consumer<BlockchainProvider>(
        builder: (context, blockchainProvider, child) {
          if (blockchainProvider.isLoading && blockchainProvider.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (blockchainProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${blockchainProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => blockchainProvider.loadAccounts(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final selectedAccount = blockchainProvider.selectedAccount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Card(
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${selectedAccount?.balance.toStringAsFixed(4) ?? '0.0000'} CCT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Adresse',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedAccount?.address ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                              onPressed: () {
                                if (selectedAccount != null) {
                                  Clipboard.setData(ClipboardData(text: selectedAccount.address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Adresse copiée')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showSendDialog,
                        icon: const Icon(Icons.send),
                        label: const Text('Envoyer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Mes bénéficiaires',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Account List
                if (blockchainProvider.accounts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Aucun compte disponible'),
                    ),
                  )
                else
                  ...blockchainProvider.accounts.map((account) {
                    final isSelected = selectedAccount?.address == account.address;
                    return Card(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                        ),
                        title: Text(
                          account.shortAddress,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text('${account.balance.toStringAsFixed(4)} CCT'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () {
                          blockchainProvider.selectAccount(account);
                        },
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
