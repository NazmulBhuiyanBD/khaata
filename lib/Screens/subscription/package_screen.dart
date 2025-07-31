import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/subscription/purchase_premium_plan_screen.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../Home/home_screen.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  Duration? remainTime;
  List<String>? initialPackageService;
  List<int>? mainPackageService;
  List<String> imageList = [
    'images/sales_2.png',
    'images/purchase_2.png',
    'images/due_collection_2.png',
    'images/parties_2.png',
    'images/product1.png',
  ];

  @override
  void initState() {
    super.initState();
  }

  bool _isRefreshing = false; // Prevents multiple refresh calls

  Future<void> refreshData(WidgetRef ref) async {
    if (_isRefreshing) return; // Prevent duplicate refresh calls
    _isRefreshing = true;

    ref.refresh(businessInfoProvider);
    ref.refresh(getExpireDateProvider(ref));

    await Future.delayed(const Duration(seconds: 1)); // Optional delay
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    List<String> nameList = [
      lang.S.of(context).sales,
      lang.S.of(context).purchase,
      lang.S.of(context).dueCollection,
      lang.S.of(context).parties,
      lang.S.of(context).products,
    ];
    return Consumer(builder: (context, ref, __) {
      final profileInfo = ref.watch(businessInfoProvider);
      return profileInfo.when(
        data: (info) {
          return Scaffold(
            backgroundColor: kWhite,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                lang.S.of(context).yourPack,
                // style: GoogleFonts.poppins(
                //   color: Colors.black,
                // ),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black),
              elevation: 0.0,
            ),
            bottomNavigationBar: Visibility(
              visible: info.user?.role != 'staff',
              child: SizedBox(
                height: 115,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        lang.S.of(context).unlimitedUsagesOfOurPackage,
                        //'Unlimited Usages of Our Package👇 ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: () {
                          PurchasePremiumPlanScreen(
                            isCameBack: true,
                            enrolledPlan: info.enrolledPlan,
                            willExpire: info.willExpire,
                          ).launch(context);
                        },
                        child: Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            color: kMainColor,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text(
                              lang.S.of(context).updateNow,
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () => refreshData(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(color: kMainColor.withOpacity(0.1), borderRadius: const BorderRadius.all(Radius.circular(10))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info.enrolledPlan != null
                                          ? (info.enrolledPlan?.price ?? 0) > 0
                                              ? lang.S.of(context).premiumPlan
                                              : lang.S.of(context).freePlan
                                          : 'No active plan!',
                                      style: const TextStyle(fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: info.enrolledPlan?.plan != null
                                          ? Text.rich(TextSpan(text: lang.S.of(context).youRUsing, children: [
                                              TextSpan(
                                                  text: '${info.enrolledPlan?.plan?.subscriptionName} Package',
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        color: kMainColor,
                                                        fontWeight: FontWeight.w600,
                                                      ))
                                            ]))
                                          : const Text('You don’t have an active plan.'),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 63,
                                width: 63,
                                decoration: const BoxDecoration(
                                  color: kMainColor,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Center(
                                    child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    getDayLeftInExpiring(expireDate: info.willExpire, shortMSG: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        lang.S.of(context).packFeatures,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                          itemCount: nameList.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: kWhite,
                                    boxShadow: [BoxShadow(color: const Color(0xff0C1A4B).withOpacity(0.24), blurRadius: 1), BoxShadow(color: const Color(0xff473232).withOpacity(0.05), offset: const Offset(0, 3), spreadRadius: -1, blurRadius: 8)],
                                  ),
                                  child: ListTile(
                                    visualDensity: const VisualDensity(vertical: -4),
                                    horizontalTitleGap: 10,
                                    contentPadding: const EdgeInsets.only(left: 6, top: 6, bottom: 6, right: 12),
                                    leading: SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: Image(
                                        image: AssetImage(imageList[i]),
                                      ),
                                    ),
                                    title: Text(
                                      nameList[i],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    trailing: Text(
                                      lang.S.of(context).unlimited,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        error: (error, stackTrace) {
          return Text(error.toString());
        },
        loading: () {
          return const CircularProgressIndicator();
        },
      );
    });
  }
}
