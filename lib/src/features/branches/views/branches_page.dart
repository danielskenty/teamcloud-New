import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tenant_context_provider.dart';
import '../models/branch.dart';
import '../providers/branch_providers.dart';

class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantContextAsync = ref.watch(tenantContextProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: tenantContextAsync.when(
        data: (tenantContext) {
          final tenantId = tenantContext?.tenantId;
          if (tenantId == null) {
            return const Center(
              child: Text('Your account is not assigned to a tenant.'),
            );
          }

          final branchList = ref.watch(branchesProvider(tenantId));
          return branchList.when(
            data: (branches) => _buildBranchList(branches),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Failed to load branches: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Unable to load tenant context: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBranchList(List<Branch> branches) {
    if (branches.isEmpty) {
      return const Center(child: Text('No branches available.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: branches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final branch = branches[index];
        return Card(
          child: ListTile(
            title: Text(branch.name),
            subtitle: Text(branch.address),
            trailing: Icon(
              branch.active ? Icons.check_circle : Icons.pause_circle,
            ),
          ),
        );
      },
    );
  }
}
