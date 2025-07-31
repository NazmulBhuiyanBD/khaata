import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../GlobalComponents/glonal_popup.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({
    Key? key,
  }) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          backgroundColor: kWhite,
          surfaceTintColor: kWhite,
          title: Text(
            lang.S.of(context).productDetails,
            //'Product Details',
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context)=>UpdateProduct()));
                  },
                  icon: Row(
                    children: [
                      const Icon(
                        IconlyBold.edit,
                        color: kMainColor,
                        size: 18,
                      ),
                      Text(
                        lang.S.of(context).edit,
                        // 'Edit',
                        style: theme.textTheme.bodyMedium?.copyWith(color: kMainColor),
                      )
                    ],
                  )),
            )
          ],
          centerTitle: true,
          // iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0.0,
        ),
        body: Container(
          alignment: Alignment.topCenter,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 20,),
                  Container(
                    height: 290,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: const Color(0xffFEF0F1), image: const DecorationImage(fit: BoxFit.cover, image: NetworkImage('https://tinyurl.com/3tme92c2'))),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.S.of(context).smartWatch,
                            //'Smart watch',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            lang.S.of(context).appleWatch,
                            //'Apple Watch',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: kGreyTextColor,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '$currency 175.0',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    lang.S.of(context).details,
                    // 'Details',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    lang.S.of(context).loremIpsumDolor,
                    //'Lorem ipsum dolor sit amet, consectetur adi piscing elit. Accumsan vulputate tellus scele risque odio con sectetur tincidunt semper.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: kGreyTextColor),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xffFEF0F1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.S.of(context).salePrice,
                                //'Sale Price',
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                '$currency ${180}',
                                style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                lang.S.of(context).wholeSalePrice,
                                //  'Wholesale price',
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                '$currency ${170}',
                                style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                              )
                            ],
                          ),
                          RotatedBox(
                            quarterTurns: 1,
                            child: Container(
                              height: 1,
                              width: 100,
                              color: kBorderColorTextField,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.S.of(context).stock,
                                //'Stock',
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                '250',
                                style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                lang.S.of(context).dealerPrice,
                                //'Dealer price',
                                style: theme.textTheme.bodyLarge?.copyWith(color: kTitleColor, fontSize: 16),
                              ),
                              Text(
                                '$currency ${175}',
                                style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
