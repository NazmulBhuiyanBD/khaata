import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_pos/Screens/DashBoard/dashboard.dart';
import 'package:mobile_pos/Screens/Home/home_screen.dart';
import 'package:mobile_pos/Screens/Report/reports.dart';
import 'package:mobile_pos/Screens/Settings/settings_screen.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isDeviceConnected = false;
  bool isAlertSet = false;
  bool isNoInternet = false;
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  set tabIndex(int v) {
    _tabIndex = v;
    setState(() {});
  }

  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              lang.S.of(context).areYouSure,
              //'Are you sure?'
            ),
            content: Text(
              lang.S.of(context).doYouWantToExitTheApp,
              //'Do you want to exit the app?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  lang.S.of(context).no,
                  //'No'
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  lang.S.of(context).yes,
                  //  'Yes'
                ),
              ),
            ],
          ),
        );
        return shouldPop ?? false; // Allow default back button behavior if dialog is dismissed
      },
      child: Consumer(builder: (context, ref, __) {
        final profile = ref.watch(businessInfoProvider);
        ref.watch(getExpireDateProvider(ref));
        return GlobalPopup(
          child: Scaffold(
            body: PageView(
              controller: pageController,
              onPageChanged: (v) {
                tabIndex = v;
              },
              children: (profile.value?.user?.visibility?.dashboardPermission ?? true)
                  ? const [HomeScreen(), DashboardScreen(), Reports(), SettingScreen()]
                  : const [HomeScreen(), Reports(), SettingScreen()],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _tabIndex,
              backgroundColor: Colors.white,
              onTap: (index) {
                setState(() {
                  _tabIndex = index;
                  pageController.jumpToPage(index);
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: _tabIndex == 0
                      ? SvgPicture.asset(
                          'assets/cHome.svg',
                          fit: BoxFit.scaleDown,
                          height: 28,
                          width: 28,
                        )
                      : SvgPicture.asset(
                          'assets/home.svg',
                          colorFilter: const ColorFilter.mode(kGreyTextColor, BlendMode.srcIn),
                          height: 24,
                          width: 24,
                        ),
                  label: lang.S.of(context).home,
                ),
                BottomNavigationBarItem(
                  icon: _tabIndex == 1
                      ? SvgPicture.asset(
                          'assets/dashbord1.svg',
                          height: 28,
                          width: 28,
                          fit: BoxFit.scaleDown,
                        )
                      : SvgPicture.asset(
                          'assets/dashbord.svg',
                          height: 24,
                          colorFilter: const ColorFilter.mode(kGreyTextColor, BlendMode.srcIn),
                          width: 24,
                        ),
                  label: lang.S.of(context).dashboard,
                ),
                BottomNavigationBarItem(
                  icon: _tabIndex == 2
                      ? SvgPicture.asset(
                          'assets/cFile.svg',
                          height: 28,
                          width: 28,
                          fit: BoxFit.scaleDown,
                        )
                      : SvgPicture.asset(
                          'assets/file.svg',
                          colorFilter: const ColorFilter.mode(kGreyTextColor, BlendMode.srcIn),
                          height: 24,
                          width: 24,
                        ),
                  label: lang.S.of(context).reports,
                ),
                BottomNavigationBarItem(
                  icon: _tabIndex == 3
                      ? SvgPicture.asset(
                          'assets/cSetting.svg',
                          height: 28,
                          width: 28,
                          fit: BoxFit.scaleDown,
                        )
                      : SvgPicture.asset(
                          'assets/setting.svg',
                          colorFilter: const ColorFilter.mode(kGreyTextColor, BlendMode.srcIn),
                          height: 24,
                          width: 24,
                          color: kGreyTextColor,
                        ),
                  label: lang.S.of(context).setting,
                ),
              ],
              type: BottomNavigationBarType.fixed,
              selectedItemColor: kMainColor,
              unselectedItemColor: kGreyTextColor,
              selectedLabelStyle: const TextStyle(fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
            ),
            // bottomNavigationBar: (profile.value?.user?.visibility?.dashboardPermission ?? true)
            //     ? Directionality(
            //         textDirection: TextDirection.ltr,
            //         child: CircleNavBar(
            //           activeIcons: [
            //             SvgPicture.asset(
            //               'assets/cHome.svg',
            //               fit: BoxFit.scaleDown,
            //               height: 28,
            //               width: 28,
            //             ),
            //             SvgPicture.asset(
            //               'assets/dashbord1.svg',
            //               height: 28,
            //               width: 28,
            //               fit: BoxFit.scaleDown,
            //             ),
            //             SvgPicture.asset(
            //               'assets/cFile.svg',
            //               height: 28,
            //               width: 28,
            //               fit: BoxFit.scaleDown,
            //             ),
            //             SvgPicture.asset(
            //               'assets/cSetting.svg',
            //               height: 28,
            //               width: 28,
            //               fit: BoxFit.scaleDown,
            //             ),
            //           ],
            //           inactiveIcons: [
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/home.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).home,
            //                   //  "Home",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/dashbord.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).dashboard,
            //                   //"Dashboard",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/file.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).reports,
            //                   // "Reports",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/setting.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).setting,
            //                   //"Setting",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //           ],
            //           color: Colors.white,
            //           height: 65,
            //           circleWidth: 60,
            //           activeIndex: tabIndex,
            //           onTap: (index) {
            //             tabIndex = index;
            //             pageController.jumpToPage(tabIndex);
            //           },
            //           padding: EdgeInsets.zero,
            //           cornerRadius: const BorderRadius.only(
            //             topLeft: Radius.circular(8),
            //             topRight: Radius.circular(8),
            //           ),
            //           shadowColor: kBorderColorTextField,
            //           elevation: 2,
            //         ),
            //       )
            //     : Directionality(
            //         textDirection: TextDirection.ltr,
            //         child: CircleNavBar(
            //           activeIcons: [
            //             SvgPicture.asset(
            //               'assets/cHome.svg',
            //               fit: BoxFit.scaleDown,
            //               height: 28,
            //               width: 28,
            //             ),
            //             SvgPicture.asset(
            //               'assets/cFile.svg',
            //               height: 28,
            //               width: 28,
            //               fit: BoxFit.scaleDown,
            //             ),
            //             SvgPicture.asset(
            //               'assets/cSetting.svg',
            //               height: 28,
            //               width: 28,
            //               fit: BoxFit.scaleDown,
            //             ),
            //           ],
            //           inactiveIcons: [
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/home.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).home,
            //                   //  "Home",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/file.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).reports,
            //                   // "Reports",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //             Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/setting.svg',
            //                   height: 24,
            //                   width: 24,
            //                   color: kGreyTextColor,
            //                 ),
            //                 Text(
            //                   lang.S.of(context).setting,
            //                   //"Setting",
            //                   style: const TextStyle(color: kGreyTextColor),
            //                 ),
            //               ],
            //             ),
            //           ],
            //           color: Colors.white,
            //           height: 65,
            //           circleWidth: 60,
            //           activeIndex: tabIndex,
            //           onTap: (index) {
            //             tabIndex = index;
            //             pageController.jumpToPage(tabIndex);
            //           },
            //           padding: EdgeInsets.zero,
            //           cornerRadius: const BorderRadius.only(
            //             topLeft: Radius.circular(8),
            //             topRight: Radius.circular(8),
            //           ),
            //           shadowColor: kBorderColorTextField,
            //           elevation: 2,
            //         ),
            //       ),
          ),
        );
      }),
    );
  }
}
