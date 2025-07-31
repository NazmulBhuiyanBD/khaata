// ignore: import_of_legacy_library_into_null_safe
// ignore_for_file: unused_result
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import 'Provider/customer_provider.dart';
import 'Repo/parties_repo.dart';

// ignore: must_be_immutable
class EditCustomer extends StatefulWidget {
  EditCustomer({super.key, required this.customerModel});

  Party customerModel;

  @override
  // ignore: library_private_types_in_public_api
  _EditCustomerState createState() => _EditCustomerState();
}

class _EditCustomerState extends State<EditCustomer> {
  String groupValue = '';
  bool expanded = false;
  final ImagePicker _picker = ImagePicker();
  bool showProgress = false;
  XFile? pickedImage;

  @override
  void initState() {
    phoneController.text = widget.customerModel.phone ?? '';
    nameController.text = widget.customerModel.name ?? '';
    emailController.text = widget.customerModel.email ?? '';
    dueController.text = (widget.customerModel.due ?? 0).toString();
    addressController.text = widget.customerModel.address ?? '';
    groupValue = widget.customerModel.type ?? '';
    super.initState();
  }

  final GlobalKey<FormState> _formKay = GlobalKey();

  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dueController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(builder: (context, cRef, __) {
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              lang.S.of(context).updateContact,
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0.0,
          ),
          body: Consumer(builder: (context, ref, __) {
            // ignore: unused_local_variable
            final customerData = ref.watch(partiesProvider);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Form(
                      key: _formKay,
                      child: Column(
                        children: [
                          ///_________Phone_______________________
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: phoneController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  // return 'Please enter a valid phone number';
                                  return lang.S.of(context).pleaseEnterAValidPhoneNumber;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).phone,
                                hintText: lang.S.of(context).enterYourPhoneNumber,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),

                          ///_________Name_______________________
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  // return 'Please enter a valid Name';
                                  return lang.S.of(context).pleaseEnterAValidName;
                                }
                                // You can add more validation logic as needed
                                return null;
                              },
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: lang.S.of(context).name,
                                hintText: lang.S.of(context).enterYourName,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            contentPadding: EdgeInsets.zero,
                            groupValue: groupValue,
                            title: Text(
                              lang.S.of(context).retailer,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall,
                            ),
                            value: 'Retailer',
                            onChanged: (value) {
                              if (widget.customerModel.type != 'Supplier') {
                                setState(() {
                                  groupValue = value.toString();
                                });
                              }
                            },
                            // Change the color to indicate it's not selectable
                            activeColor: widget.customerModel.type == 'Supplier' ? Colors.grey : kMainColor,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            contentPadding: EdgeInsets.zero,
                            groupValue: groupValue,
                            title: Text(
                              lang.S.of(context).dealer,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall,
                            ),
                            value: 'Dealer',
                            onChanged: (value) {
                              if (widget.customerModel.type != 'Supplier') {
                                setState(() {
                                  groupValue = value.toString();
                                });
                              }
                            },
                            activeColor: widget.customerModel.type == 'Supplier' ? Colors.grey : kMainColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: kMainColor,
                            groupValue: groupValue,
                            title: Text(
                              lang.S.of(context).wholesaler,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall,
                            ),
                            value: 'Wholesaler',
                            onChanged: (value) {
                              if (widget.customerModel.type != 'Supplier') {
                                setState(() {
                                  groupValue = value.toString();
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: kMainColor,
                            groupValue: groupValue,
                            title: Text(
                              lang.S.of(context).supplier,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall,
                            ),
                            value: 'Supplier',
                            onChanged: (value) {
                              if (widget.customerModel.type != 'Retailer' && widget.customerModel.type != 'Dealer' && widget.customerModel.type != 'Wholesaler') {
                                setState(() {
                                  groupValue = value.toString();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: showProgress,
                      child: const CircularProgressIndicator(
                        color: kMainColor,
                        strokeWidth: 5.0,
                      ),
                    ),
                    ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {},
                      animationDuration: const Duration(seconds: 1),
                      elevation: 0,
                      dividerColor: Colors.white,
                      children: [
                        ExpansionPanel(
                          backgroundColor: kWhite,
                          headerBuilder: (BuildContext context, bool isExpanded) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  child: Text(
                                    lang.S.of(context).moreInfo,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: kMainColor,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      expanded == false ? expanded = true : expanded = false;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                          body: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          // ignore: sized_box_for_whitespace
                                          child: Container(
                                            height: 200.0,
                                            width: MediaQuery.of(context).size.width - 80,
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () async {
                                                      pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                                                      setState(() {});
                                                      Navigator.pop(context);
                                                    },
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(
                                                          Icons.photo_library_rounded,
                                                          size: 60.0,
                                                          color: kMainColor,
                                                        ),
                                                        Text(lang.S.of(context).gallery, style: theme.textTheme.titleLarge?.copyWith(color: kMainColor)),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 40.0,
                                                  ),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      pickedImage = await _picker.pickImage(source: ImageSource.camera);
                                                      setState(() {});
                                                      Navigator.pop(context);
                                                    },
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(
                                                          Icons.camera,
                                                          size: 60.0,
                                                          color: kGreyTextColor,
                                                        ),
                                                        Text(
                                                          lang.S.of(context).camera,
                                                          style: theme.textTheme.titleLarge?.copyWith(
                                                            color: kGreyTextColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 120,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black54, width: 1),
                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        image: pickedImage == null
                                            ? widget.customerModel.image.isEmptyOrNull
                                                ? const DecorationImage(
                                                    image: AssetImage('images/no_shop_image.png'),
                                                    fit: BoxFit.cover,
                                                  )
                                                : DecorationImage(
                                                    image: NetworkImage('${APIConfig.domain}${widget.customerModel.image!}'),
                                                    fit: BoxFit.cover,
                                                  )
                                            : DecorationImage(
                                                image: FileImage(File(pickedImage!.path)),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white, width: 2),
                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                          color: kMainColor,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    labelText: lang.S.of(context).email,
                                    // hintText: 'Enter your email',
                                    hintText: lang.S.of(context).hintEmail,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: addressController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    labelText: lang.S.of(context).address,
                                    //hintText: 'Enter your address'
                                    hintText: lang.S.of(context).hintEmail,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  readOnly: true,
                                  controller: dueController,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    labelText: lang.S.of(context).previousDue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isExpanded: expanded,
                        ),
                      ],
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          if (_formKay.currentState!.validate()) {
                            try {
                              EasyLoading.show(
                                status: lang.S.of(context).updating,
                                // 'Updating...'
                              );
                              final party = PartyRepository();
                              await party.updateParty(
                                id: widget.customerModel.id.toString(),
                                // Assuming id is a property in customerModel
                                ref: ref,
                                context: context,
                                name: nameController.text,
                                phone: phoneController.text,
                                type: groupValue,
                                image: pickedImage != null ? File(pickedImage!.path) : null,
                                email: emailController.text,
                                address: addressController.text,
                                due: dueController.text,
                              );
                              EasyLoading.dismiss();
                            } catch (e) {
                              EasyLoading.dismiss();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                        child: Text(lang.S.of(context).update)),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
