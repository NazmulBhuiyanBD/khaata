import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import '../Repo/parties_repo.dart';

PartyRepository partiesRepo = PartyRepository();

final partiesProvider = FutureProvider<List<Party>>((ref) => partiesRepo.fetchAllParties());

final partySearchProvider = StateProvider<String>((ref) => "");
final filteredPartiesProvider = Provider<AsyncValue<List<Party>>>((ref) {
  final partiesAsync = ref.watch(partiesProvider);
  final searchString = ref.watch(partySearchProvider).toLowerCase();

  return partiesAsync.whenData((list) {
    if (searchString.isEmpty) return list;
    
    return list.where((party) {
      final name = party.name?.toLowerCase() ?? '';
      final phone = party.phone?.toLowerCase() ?? '';
      final email = party.email?.toLowerCase() ?? '';

      return name.contains(searchString) || 
             phone.contains(searchString) || 
             email.contains(searchString);
    }).toList();
  });
});