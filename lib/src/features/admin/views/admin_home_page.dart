import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/providers/tenant_context_provider.dart';
import '../models/admin_user_claims.dart';
import '../models/nomba_config.dart';
import '../services/admin_user_claims_service.dart';
import '../services/nomba_config_service.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  static const _platformRoles = [
    'super_admin',
    'support_admin',
    'billing_admin',
  ];
  static const _tenantRoles = [
    'business_owner',
    'branch_manager',
    'inventory_officer',
    'cashier',
    'sales_staff',
    'accountant',
  ];
  static const _allRoles = [..._platformRoles, ..._tenantRoles];

  final _nombaService = NombaConfigService();
  final _claimsService = AdminUserClaimsService();
  final _testPublicKeyController = TextEditingController();
  final _testSecretKeyController = TextEditingController();
  final _testWebhookSecretController = TextEditingController();
  final _livePublicKeyController = TextEditingController();
  final _liveSecretKeyController = TextEditingController();
  final _liveWebhookSecretController = TextEditingController();
  final _userLookupController = TextEditingController();
  final _tenantIdController = TextEditingController();

  Future<NombaConfig>? _configFuture;
  NombaConfig _config = NombaConfig.empty();
  AdminUserClaims? _selectedUser;
  String _mode = 'test';
  String _selectedRole = 'cashier';
  bool _saving = false;
  bool _loadingUser = false;
  bool _savingClaims = false;

  @override
  void dispose() {
    _testPublicKeyController.dispose();
    _testSecretKeyController.dispose();
    _testWebhookSecretController.dispose();
    _livePublicKeyController.dispose();
    _liveSecretKeyController.dispose();
    _liveWebhookSecretController.dispose();
    _userLookupController.dispose();
    _tenantIdController.dispose();
    super.dispose();
  }

  void _loadConfig() {
    _configFuture = _nombaService.getConfig();
  }

  void _applyConfig(NombaConfig config) {
    _config = config;
    _mode = config.mode;
    _testPublicKeyController.text = config.test.publicKey;
    _livePublicKeyController.text = config.live.publicKey;
    _testSecretKeyController.clear();
    _testWebhookSecretController.clear();
    _liveSecretKeyController.clear();
    _liveWebhookSecretController.clear();
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    try {
      final config = await _nombaService.saveConfig(
        mode: _mode,
        test: NombaKeyPayload(
          publicKey: _testPublicKeyController.text,
          secretKey: _testSecretKeyController.text,
          webhookSecret: _testWebhookSecretController.text,
        ),
        live: NombaKeyPayload(
          publicKey: _livePublicKeyController.text,
          secretKey: _liveSecretKeyController.text,
          webhookSecret: _liveWebhookSecretController.text,
        ),
      );

      if (!mounted) return;
      setState(() {
        _applyConfig(config);
        _configFuture = Future.value(config);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nomba keys saved')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save Nomba keys: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _lookupUser() async {
    final lookup = _userLookupController.text.trim();
    if (lookup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a user email or UID')),
      );
      return;
    }

    setState(() => _loadingUser = true);
    try {
      final user = await _claimsService.lookup(
        email: lookup.contains('@') ? lookup : '',
        uid: lookup.contains('@') ? '' : lookup,
      );
      if (!mounted) return;
      setState(() {
        _selectedUser = user;
        _selectedRole = _allRoles.contains(user.role) ? user.role : 'cashier';
        _tenantIdController.text = user.tenantId;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load user: $error')));
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  Future<void> _saveUserClaims() async {
    final user = _selectedUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Load a user first')));
      return;
    }

    final tenantId = _tenantIdController.text.trim();
    if (_tenantRoles.contains(_selectedRole) && tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant roles require a tenant ID')),
      );
      return;
    }
    if (_platformRoles.contains(_selectedRole) && tenantId.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Platform roles cannot use a tenant ID')),
      );
      return;
    }

    setState(() => _savingClaims = true);
    try {
      final updated = await _claimsService.save(
        uid: user.uid,
        email: user.email,
        role: _selectedRole,
        tenantId: tenantId,
      );
      if (!mounted) return;
      setState(() {
        _selectedUser = updated;
        _selectedRole = _allRoles.contains(updated.role)
            ? updated.role
            : _selectedRole;
        _tenantIdController.text = updated.tenantId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User claims saved. User must sign in again or refresh token.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save claims: $error')));
    } finally {
      if (mounted) {
        setState(() => _savingClaims = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantContextAsync = ref.watch(tenantContextProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminTitle)),
      body: tenantContextAsync.when(
        data: (tenantContext) {
          if (tenantContext == null || !tenantContext.isPlatformAdmin) {
            return const Center(
              child: Text('You do not have permission to access this portal.'),
            );
          }

          if (tenantContext.role != 'super_admin') {
            return const Center(
              child: Text('Only Super Admins can manage payment keys.'),
            );
          }

          _configFuture ??= _nombaService.getConfig();
          return FutureBuilder<NombaConfig>(
            future: _configFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Unable to load Nomba keys: ${snapshot.error}',
                  onRetry: () {
                    setState(_loadConfig);
                  },
                );
              }
              if (snapshot.hasData && snapshot.data != _config) {
                _applyConfig(snapshot.data!);
              }
              return _buildPaymentKeys(context);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load account permissions: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentKeys(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildUserClaims(context),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Nomba payment keys',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Manage test and live credentials. Secret fields stay blank after loading; enter a value only when replacing the stored secret.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'test', label: Text('Test')),
            ButtonSegment(value: 'live', label: Text('Live')),
          ],
          selected: {_mode},
          onSelectionChanged: _saving
              ? null
              : (selection) {
                  setState(() => _mode = selection.first);
                },
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _NombaKeySection(
              title: 'Test keys',
              publicKeyController: _testPublicKeyController,
              secretKeyController: _testSecretKeyController,
              webhookSecretController: _testWebhookSecretController,
              current: _config.test,
            ),
            _NombaKeySection(
              title: 'Live keys',
              publicKeyController: _livePublicKeyController,
              secretKeyController: _liveSecretKeyController,
              webhookSecretController: _liveWebhookSecretController,
              current: _config.live,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveConfig,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving' : 'Save Nomba keys'),
          ),
        ),
      ],
    );
  }

  Widget _buildUserClaims(BuildContext context) {
    final selectedUser = _selectedUser;
    final isTenantRole = _tenantRoles.contains(_selectedRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User access', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Look up a Firebase Auth user and manage the role and tenant_id custom claims used by routing and security rules.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userLookupController,
                  enabled: !_loadingUser && !_savingClaims,
                  decoration: const InputDecoration(labelText: 'Email or UID'),
                  onSubmitted: (_) => _lookupUser(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loadingUser ? null : _lookupUser,
                icon: _loadingUser
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_loadingUser ? 'Loading' : 'Lookup'),
              ),
            ],
          ),
        ),
        if (selectedUser != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 720,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedUser.email.isNotEmpty
                          ? selectedUser.email
                          : selectedUser.uid,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('UID: ${selectedUser.uid}'),
                    if (selectedUser.displayName.isNotEmpty)
                      Text('Name: ${selectedUser.displayName}'),
                    if (selectedUser.disabled)
                      Text(
                        'Account disabled',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: _allRoles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                      onChanged: _savingClaims
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedRole = value;
                                if (_platformRoles.contains(value)) {
                                  _tenantIdController.clear();
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tenantIdController,
                      enabled: !_savingClaims && isTenantRole,
                      decoration: InputDecoration(
                        labelText: 'Tenant ID',
                        helperText: isTenantRole
                            ? 'Required for tenant roles'
                            : 'Disabled for platform admin roles',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _savingClaims ? null : _saveUserClaims,
                      icon: _savingClaims
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.admin_panel_settings),
                      label: Text(
                        _savingClaims ? 'Saving' : 'Save user claims',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NombaKeySection extends StatelessWidget {
  const _NombaKeySection({
    required this.title,
    required this.publicKeyController,
    required this.secretKeyController,
    required this.webhookSecretController,
    required this.current,
  });

  final String title;
  final TextEditingController publicKeyController;
  final TextEditingController secretKeyController;
  final TextEditingController webhookSecretController;
  final NombaKeySet current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: publicKeyController,
                decoration: const InputDecoration(labelText: 'Public key'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: secretKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Secret key',
                  helperText: current.secretKeyConfigured
                      ? 'Current: ${current.secretKeyMasked}'
                      : 'No secret key saved',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: webhookSecretController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Webhook secret',
                  helperText: current.webhookSecretConfigured
                      ? 'Current: ${current.webhookSecretMasked}'
                      : 'No webhook secret saved',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
