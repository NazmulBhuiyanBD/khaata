import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/Screens/Home/components/grid_items.dart';
import 'package:mobile_pos/Screens/Profile%20Screen/profile_details.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/go_to_subscription-package_page_popup_widget.dart';
import '../../Provider/profile_provider.dart';
import '../../constant.dart';
import '../../model/business_info_model.dart' as business;
import '../Customers/Provider/customer_provider.dart';
import '../Home/Model/banner_model.dart' as b;
import '../subscription/package_screen.dart';
import 'Provider/banner_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController pageController = PageController(initialPage: 0);

  bool _isRefreshing = false;

  Future<void> refreshAllProviders({required WidgetRef ref}) async {
    if (_isRefreshing) return; // Prevent multiple refresh calls

    _isRefreshing = true;
    try {
      ref.refresh(summaryInfoProvider);
      ref.refresh(bannerProvider);
      ref.refresh(businessInfoProvider);
      ref.refresh(businessSettingProvider);
      ref.refresh(partiesProvider);
      ref.refresh(getExpireDateProvider(ref));
      await Future.delayed(const Duration(seconds: 3));
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (_, ref, __) {
      final businessInfo = ref.watch(businessInfoProvider);
      final summaryInfo = ref.watch(summaryInfoProvider);
      final banner = ref.watch(bannerProvider);
      return businessInfo.when(data: (details) {
        return Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              backgroundColor: kWhite,
              titleSpacing: 5,
              surfaceTintColor: kWhite,
              actions: [IconButton(onPressed: () async => refreshAllProviders(ref: ref), icon: const Icon(Icons.refresh))],
              leading: Padding(
                padding: const EdgeInsets.all(10),
                child: GestureDetector(
                  onTap: () {
                    const ProfileDetails().launch(context);
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: details.pictureUrl == null
                        ? BoxDecoration(
                            image: const DecorationImage(image: AssetImage('images/no_shop_image.png'), fit: BoxFit.cover),
                            borderRadius: BorderRadius.circular(50),
                          )
                        : BoxDecoration(
                            image: DecorationImage(image: NetworkImage('${APIConfig.domain}${details.pictureUrl}'), fit: BoxFit.cover),
                            borderRadius: BorderRadius.circular(50),
                          ),
                  ),
                ),
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.user?.role == 'staff' ? '${details.companyName ?? ''} [${details.user?.name ?? ''}]' : details.companyName ?? '',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            resizeToAvoidBottomInset: true,
            body: RefreshIndicator.adaptive(
              onRefresh: () async => refreshAllProviders(ref: ref),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: details.user?.visibility?.dashboardPermission ?? true,
                        child: summaryInfo.when(data: (summary) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kMainColor),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        lang.S.of(context).todaySummary,
                                        //'Today’s Summary',
                                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: kWhite, fontSize: 18),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Spacer(),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                                          },
                                          child: Text(
                                            lang.S.of(context).sellAll,

                                            //'Sell All >',
                                            style: const TextStyle(color: kWhite, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                          )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.S.of(context).sales,
                                          //'Sales',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          '$currency${summary.data?.sales?.toStringAsFixed(2) ?? 0.00}',
                                          style: theme.textTheme.titleSmall?.copyWith(color: kWhite),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          summary.data!.income! >= 0 ? 'Profit' : 'Loss',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          '$currency${summary.data?.income?.abs().toStringAsFixed(2) ?? 0.00}',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.S.of(context).purchased,
                                          // 'Purchased',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          '$currency${summary.data?.purchase?.toStringAsFixed(2) ?? 0.00}',
                                          style: theme.textTheme.titleSmall?.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          //'Expense',
                                          lang.S.of(context).expense,
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          '$currency${summary.data?.expense?.toStringAsFixed(2) ?? 0.00}',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }, error: (e, stack) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kMainColor),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang.S.of(context).todaySummary,
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: kWhite, fontSize: 18),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                        onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                                        },
                                        child: Text(
                                          lang.S.of(context).sellAll,
                                          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w500),
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.S.of(context).sales,
                                          //'Sales',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).notFound,
                                          // 'Not Found',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          lang.S.of(context).income,
                                          // 'Income',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).notFound,
                                          //'Not Found',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.S.of(context).purchased,
                                          // 'Purchased',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).notFound,
                                          //'Not Found',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          lang.S.of(context).expense,
                                          //'Expense',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).notFound,
                                          //'Not Found',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }, loading: () {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kMainColor),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang.S.of(context).todaySummary,
                                      // 'Today’s Summary',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: kWhite, fontSize: 18),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                        onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                                        },
                                        child: Text(
                                          lang.S.of(context).sellAll,
                                          //'Sell All >',
                                          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w500),
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.S.of(context).sales,
                                          // 'Sales',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).loading,
                                          // 'Loading',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          lang.S.of(context).income,
                                          //'Income',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).loading,
                                          //'Loading',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.S.of(context).purchased,
                                          //'Purchased',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).loading,
                                          //'Loading',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          lang.S.of(context).expense,
                                          //'Expense',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite),
                                        ),
                                        Text(
                                          lang.S.of(context).loading,
                                          //'Loading',
                                          style: theme.textTheme.bodyMedium?.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return goToPackagePagePopup(context: context, enrolledPlan: details.enrolledPlan);
                              });
                        },
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: kWhite, boxShadow: [BoxShadow(color: const Color(0xffC52127).withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 10))]),
                          child: ListTile(
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            horizontalTitleGap: 20,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            leading: SvgPicture.asset(
                              'assets/plan.svg',
                              height: 38,
                              width: 38,
                            ),
                            title: RichText(
                              text: TextSpan(
                                text: '${details.enrolledPlan?.plan?.subscriptionName ?? 'No Active'} ${lang.S.of(context).package} ',
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            subtitle: Text(getDayLeftInExpiring(expireDate: details.willExpire, shortMSG: false)),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: kGreyTextColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        childAspectRatio: 3.0,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        crossAxisCount: 2,
                        children: List.generate(
                          getFreeIcons(context: context).length,
                          (index) => HomeGridCards(
                            gridItems: getFreeIcons(context: context)[index],
                            visibility: businessInfo.value?.user?.visibility,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),

                      ///________________Banner_______________________________________
                      banner.when(data: (imageData) {
                        List<b.Banner> images = [];
                        if (imageData.isNotEmpty) {
                          images.addAll(imageData.where(
                            (element) => element.status == 1,
                          ));
                        }

                        if (images.isNotEmpty) {
                          return SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  lang.S.of(context).whatNew,
                                  textAlign: TextAlign.start,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    GestureDetector(
                                      child: const Icon(Icons.keyboard_arrow_left),
                                      onTap: () {
                                        pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.linear);
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      height: 150,
                                      width: MediaQuery.of(context).size.width - 80,
                                      child: PageView.builder(
                                        pageSnapping: true,
                                        itemCount: images.length,
                                        controller: pageController,
                                        itemBuilder: (_, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              const PackageScreen().launch(context);
                                            },
                                            child: Image(
                                              image: NetworkImage(
                                                "${APIConfig.domain}${images[index].imageUrl}",
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      child: const Icon(Icons.keyboard_arrow_right),
                                      onTap: () {
                                        pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.linear);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          );
                        } else {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              height: 150,
                              width: 320,
                              decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/banner1.png'))),
                            ),
                          );
                        }
                      }, error: (e, stack) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            height: 150,
                            width: 320,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text(
                                lang.S.of(context).noDataFound,
                                //'No Data Found'
                              ),
                            ),
                          ),
                        );
                      }, loading: () {
                        return const CircularProgressIndicator();
                      }),
                    ],
                  ),
                ),
              ),
            ));
      }, error: (e, stack) {
        return Text(e.toString());
      }, loading: () {
        return const Center(child: CircularProgressIndicator());
      });
    });
  }
}

class HomeGridCards extends StatefulWidget {
  const HomeGridCards({
    super.key,
    required this.gridItems,
    this.visibility,
  });

  final GridItems gridItems;
  final business.Visibility? visibility;

  @override
  State<HomeGridCards> createState() => _HomeGridCardsState();
}

class _HomeGridCardsState extends State<HomeGridCards> {
  bool checkPermission({required String item}) {
    if (item == 'Sales' && (widget.visibility?.salePermission ?? true)) {
      return true;
    } else if (item == 'Parties' && (widget.visibility?.partiesPermission ?? true)) {
      return true;
    } else if (item == 'Purchase' && (widget.visibility?.purchasePermission ?? true)) {
      return true;
    } else if (item == 'Products' && (widget.visibility?.productPermission ?? true)) {
      return true;
    } else if (item == 'Due List' && (widget.visibility?.dueListPermission ?? true)) {
      return true;
    } else if (item == 'Stock' && (widget.visibility?.stockPermission ?? true)) {
      return true;
    } else if (item == 'Reports' && (widget.visibility?.reportsPermission ?? true)) {
      return true;
    } else if (item == 'Sales List' && (widget.visibility?.salesListPermission ?? true)) {
      return true;
    } else if (item == 'Purchase List' && (widget.visibility?.purchaseListPermission ?? true)) {
      return true;
    } else if (item == 'Loss/Profit' && (widget.visibility?.lossProfitPermission ?? true)) {
      return true;
    } else if (item == 'Expense' && (widget.visibility?.addExpensePermission ?? true)) {
      return true;
    } else if (item == 'Income' && (widget.visibility?.addIncomePermission ?? true)) {
      return true;
    } else if (item == 'tax') {
      return true;
    } else if (item == 'customPrint') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      return GestureDetector(
        onTap: () async {
          if (checkPermission(item: widget.gridItems.route)) {
            Navigator.of(context).pushNamed('/${widget.gridItems.route}');
          } else {
            EasyLoading.showError(
              lang.S.of(context).permissionNotGranted,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: kWhite, boxShadow: [BoxShadow(color: const Color(0xff171717).withOpacity(0.07), offset: const Offset(0, 3), blurRadius: 50, spreadRadius: -4)]),
          child: Row(
            children: [
              SvgPicture.asset(
                widget.gridItems.icon.toString(),
                height: 40,
                width: 40,
              ),
              const SizedBox(
                width: 8,
              ),
              Flexible(
                  child: Text(
                widget.gridItems.title.toString(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: DAppColors.kNeutral700),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ))
            ],
          ),
        ),
      );
    });
  }
}

String getDayLeftInExpiring({required String? expireDate, required bool shortMSG}) {
  if (expireDate == null) {
    return shortMSG ? 'N/A' : 'Subscribe Now';
  }
  DateTime expiringDay = DateTime.parse(expireDate).add(const Duration(days: 1));
  if (expiringDay.isBefore(DateTime.now())) {
    return 'Expired';
  }
  if (expiringDay.difference(DateTime.now()).inDays < 1) {
    return shortMSG ? '${expiringDay.difference(DateTime.now()).inHours}\nHours Left' : '${expiringDay.difference(DateTime.now()).inHours} Hours Left';
  } else {
    return shortMSG ? '${expiringDay.difference(DateTime.now()).inDays}\nDays Left' : '${expiringDay.difference(DateTime.now()).inDays} Days Left';
  }
}
