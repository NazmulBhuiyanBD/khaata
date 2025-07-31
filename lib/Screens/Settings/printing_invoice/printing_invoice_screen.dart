import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../../GlobalComponents/glonal_popup.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Repository/API/business_info_update_repo.dart';
import '../../../constant.dart';

class PrintingInvoiceScreen extends ConsumerStatefulWidget {
  const PrintingInvoiceScreen({super.key});

  @override
  ConsumerState<PrintingInvoiceScreen> createState() => _PrintingInvoiceScreenState();
}

class _PrintingInvoiceScreenState extends ConsumerState<PrintingInvoiceScreen> {
  TextEditingController addressController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(isPrintEnable);
    printing = isPrintEnable;
    ref.read(businessInfoProvider).when(
          data: (data) {
            nameController.text = data.companyName ?? '';
            phoneController.text = data.phoneNumber ?? '';
            addressController.text = data.address ?? '';
          },
          error: (error, stackTrace) {},
          loading: () {},
        );
  }

  bool printing = false;

  final ImagePicker _picker = ImagePicker();
  XFile? pickedImage;
  File imageFile = File('No File');

  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _lang = lang.S.of(context);
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            _lang.printingInvoice,
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.0,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton.icon(
            icon: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
            label: Text(lang.S.of(context).continueButton),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final businessRepository = BusinessUpdateRepository();
                final isProfileUpdated = await businessRepository.updateProfile(
                  id: ref.watch(businessInfoProvider).value?.id.toString() ?? '',
                  name: nameController.text,
                  categoryId: ref.watch(businessInfoProvider).value?.category?.id.toString() ?? '',
                  address: addressController.text,
                  invoiceLogo: pickedImage != null ? File(pickedImage!.path) : null,
                  phone: phoneController.text,
                  ref: ref,
                  context: context,
                  fromInvoiceLogo: true,
                );

                if (isProfileUpdated) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isPrintEnable', printing);
                  isPrintEnable = printing;
                  ref.refresh(businessInfoProvider);
                  ref.refresh(businessSettingProvider);
                  Navigator.pop(context);
                }
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            spacing: 10,
            children: [
              Row(
                children: [
                  Text(
                    _lang.invoiceLogo,
                    style: theme.textTheme.bodyLarge?.copyWith(),
                  ),
                ],
              ),

              ///__________Image_section________________________________________
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

                                      setState(() {
                                        imageFile = File(pickedImage!.path);
                                      });

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
                                        Text(
                                          lang.S.of(context).gallery,
                                          // 'Gallery',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: kGreyTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 40.0,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      pickedImage = await _picker.pickImage(source: ImageSource.camera);
                                      setState(() {
                                        imageFile = File(pickedImage!.path);
                                      });
                                      Future.delayed(const Duration(milliseconds: 100), () {
                                        Navigator.pop(context);
                                      });
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
                                          // 'Camera',
                                          style: theme.textTheme.titleMedium?.copyWith(
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
                            ? ref.watch(businessInfoProvider).value?.invoiceLogo == null
                                ? const DecorationImage(
                                    image: AssetImage(logo),
                                    fit: BoxFit.cover,
                                  )
                                : DecorationImage(
                                    image: NetworkImage(APIConfig.domain + ref.watch(businessInfoProvider).value!.invoiceLogo.toString()),
                                    fit: BoxFit.cover,
                                  )
                            : DecorationImage(
                                image: FileImage(imageFile),
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
              const SizedBox(height: 20.0),
              Form(
                key: _formKey,
                child: Column(
                  spacing: 25,
                  children: [
                    AppTextField(
                      controller: nameController, // Optional
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          //return 'Please enter a valid business name';
                          return lang.S.of(context).pleaseEnterAValidBusinessName;
                        }
                        return null;
                      },
                      textFieldType: TextFieldType.NAME,
                      decoration: kInputDecoration.copyWith(
                        labelText: lang.S.of(context).businessName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    AppTextField(
                      controller: phoneController,
                      validator: (value) {
                        return null;
                      },
                      textFieldType: TextFieldType.PHONE,
                      decoration: kInputDecoration.copyWith(
                        labelText: lang.S.of(context).phone,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    AppTextField(
                      controller: addressController,
                      validator: (value) {
                        return null;
                      },
                      textFieldType: TextFieldType.NAME,
                      decoration: kInputDecoration.copyWith(
                        labelText: lang.S.of(context).address,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _lang.printingOption,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Switch.adaptive(
                    activeTrackColor: kMainColor,
                    value: printing,
                    onChanged: (bool value) async {
                      setState(() => printing = value);
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
