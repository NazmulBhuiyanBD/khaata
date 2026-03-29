import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/Screens/Due%20Calculation/due_collection_screen.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart' as DAppColors;
import '../../constant.dart';
import '../../currency.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../Customers/Provider/customer_provider.dart';

class DueCalculationContactScreen extends StatefulWidget {
  const DueCalculationContactScreen({super.key});

  @override
  State<DueCalculationContactScreen> createState() => _DueCalculationContactScreenState();
}

class _DueCalculationContactScreenState extends State<DueCalculationContactScreen> {
  late Color color;
  // 1. Add Search Controller
  TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(lang.S.of(context).dueList),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0.0,
        ),
        body: Consumer(builder: (context, ref, __) {
          // 2. Watch the filtered provider and search string
          final providerData = ref.watch(filteredPartiesProvider);
          final searchString = ref.watch(partySearchProvider);
          final businessInfo = ref.watch(businessInfoProvider);

          return Column(
            children: [
              /// --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      // Update Riverpod search state
                      ref.read(partySearchProvider.notifier).state = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchString.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                searchController.clear();
                                ref.read(partySearchProvider.notifier).state = '';
                              },
                              child: const Icon(Icons.cancel, color: kMainColor),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              /// --- DUE LIST ---
              Expanded(
                child: providerData.when(
                  data: (parties) {
                    // 3. Filter only those who have a due amount > 0
                    final dueCustomerList = parties.where((party) => (party.due ?? 0) > 0).toList();

                    if (dueCustomerList.isEmpty) {
                      return Center(
                        child: Text(
                          searchString.isEmpty ? lang.S.of(context).noDataAvailabe : "No results found",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.0),
                        ),
                      );
                    }

                    return businessInfo.when(
                      data: (details) {
                        return ListView.builder(
                          itemCount: dueCustomerList.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (_, index) {
                            final party = dueCustomerList[index];

                            // Color Logic based on type
                            if (party.type == 'Retailer') color = const Color(0xFF56da87);
                            else if (party.type == 'Wholesaler') color = const Color(0xFF25a9e0);
                            else if (party.type == 'Dealer') color = const Color(0xFFff5f00);
                            else if (party.type == 'Supplier') color = const Color(0xFFA569BD);
                            else color = Colors.grey;

                            return ListTile(
                              visualDensity: const VisualDensity(vertical: -2),
                              contentPadding: EdgeInsets.zero,
                              onTap: () async {
                                DueCollectionScreen(customerModel: party).launch(context);
                              },
                              leading: party.image != null
                                  ? Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: DAppColors.kBorder, width: 0.3),
                                        image: DecorationImage(
                                          image: NetworkImage('${APIConfig.domain}${party.image}'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : CircleAvatarWidget(name: party.name ?? 'n/a'),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      party.name ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _theme.textTheme.bodyMedium?.copyWith(color: Colors.black, fontSize: 16.0),
                                    ),
                                  ),
                                  Text(
                                    '$currency ${party.due}',
                                    style: _theme.textTheme.bodyMedium?.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    party.type ?? '',
                                    style: _theme.textTheme.bodyMedium?.copyWith(color: color, fontSize: 14.0),
                                  ),
                                  Text(
                                    lang.S.of(context).due,
                                    style: const TextStyle(color: Color(0xFFff5f00), fontSize: 14.0),
                                  ),
                                ],
                              ),
                              trailing: const Icon(IconlyLight.arrow_right_2, size: 18),
                            );
                          },
                        );
                      },
                      error: (e, stack) => Text(e.toString()),
                      loading: () => const Center(child: CircularProgressIndicator()),
                    );
                  },
                  error: (e, stack) => Text(e.toString()),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}