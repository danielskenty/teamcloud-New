import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/branch_repository.dart';
import '../models/branch.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});

final branchesProvider = FutureProvider.autoDispose
    .family<List<Branch>, String>((ref, tenantId) async {
      final repository = ref.watch(branchRepositoryProvider);
      final snapshot = await repository.getBranches(tenantId);
      return snapshot.docs
          .map((doc) => Branch.fromMap(doc.id, doc.data()))
          .toList();
    });
