import 'dart:io';

import 'package:excel/excel.dart' as e;
// import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/product_provider.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Products/Repo/unit_repo.dart';
import 'package:mobile_pos/constant.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../GlobalComponents/glonal_popup.dart';
import '../../product_brand/product_brand_provider/product_brand_provider.dart';
import '../../product_category/provider/product_category_provider/product_unit_provider.dart';
import '../../product_category/repo/category_repo.dart';
import '../../product_unit/provider/product_unit_provider.dart';
import '../Model/product_model.dart';

class BulkUploader extends StatefulWidget {
  const BulkUploader({Key? key, required this.previousProductName, required this.previousProductCode}) : super(key: key);

  final List<String> previousProductName;
  final List<String> previousProductCode;

  @override
  State<BulkUploader> createState() => _BulkUploaderState();
}

class _BulkUploaderState extends State<BulkUploader> {
  // List<String> allCategory = [];
  List<String> allNameInThisFile = [];
  List<String> allCodeInThisFile = [];

  // List<String> allBrand = [];
  // List<String> allUnit = [];
  String? filePat;
  File? file;

  String getFileExtension(String fileName) {
    return fileName.split('/').last;
  }

  // Future<bool> requestStoragePermission() async {
  //   await Permission.storage.request();
  //   var status = await Permission.storage.status;
  //   if (status.isGranted) {
  //     return true;
  //   }
  //
  //   // Request permission if not granted
  //   var requestResult = await Permission.storage.request();
  //   if (requestResult == PermissionStatus.granted) {
  //     return true;
  //   }
  //
  //   return false;
  // }

  Future<void> createExcelFile() async {
    if (!await Permission.storage.request().isDenied) {
      EasyLoading.showError('Storage permission is required to create Excel file!');
      return;
    }
    EasyLoading.show();
    final List<e.CellValue> excelData = [
      e.TextCellValue('SL'),
      e.TextCellValue('Product Name*'),
      e.TextCellValue('Product Code*'),
      e.TextCellValue('Product Stock*'),
      e.TextCellValue('Purchase Price*'),
      e.TextCellValue('Sale Price*'),
      e.TextCellValue('Wholesale Price'),
      e.TextCellValue('Dealer Price'),
      e.TextCellValue('Category*'),
      e.TextCellValue('Brand'),
      e.TextCellValue('Units'),
      e.TextCellValue('Manufacturer'),
    ];
    e.CellStyle cellStyle = e.CellStyle(
      bold: true,
      textWrapping: e.TextWrapping.WrapText,
      rotation: 0,
    );
    var excel = e.Excel.createExcel();
    var sheet = excel['Sheet1'];

    sheet.appendRow(excelData);

    for (int i = 0; i < excelData.length; i++) {
      var cell = sheet.cell(e.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = cellStyle;
    }
    const downloadsFolderPath = '/storage/emulated/0/Download/';
    Directory dir = Directory(downloadsFolderPath);
    final file = File('${dir.path}/${appsName}_bulk_product_upload.xlsx');
    if (await file.exists()) {
      EasyLoading.showSuccess('The Excel file has already been downloaded');
    } else {
      await file.writeAsBytes(excel.encode()!);

      EasyLoading.showSuccess('Downloaded successfully in download folder');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Excel Uploader'),
        ),
        body: Consumer(builder: (context, ref, __) {
          final businessInfo = ref.watch(businessInfoProvider);
          return businessInfo.when(data: (details) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: file != null,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Card(
                            child: ListTile(
                                leading: Container(
                                    height: 40,
                                    width: 40,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                                    ),
                                    child: const Image(image: AssetImage('images/excel.png'))),
                                title: Text(
                                  getFileExtension(file?.path ?? ''),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        file = null;
                                      });
                                    },
                                    child: const Text('Remove')))),
                      ),
                    ),
                    Visibility(
                      visible: file == null,
                      child: const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Image(
                            height: 100,
                            width: 100,
                            image: AssetImage('images/file-upload.png'),
                          )),
                    ),
                    ElevatedButton(
                      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(kMainColor)),
                      onPressed: () async {
                        if (file == null) {
                          await pickAndUploadFile(ref: ref);
                        } else {
                          EasyLoading.show(status: 'Uploading...');
                          await uploadProducts(ref: ref, file: file!, context: context);
                          EasyLoading.dismiss();
                        }
                      },
                      child: Text(file == null ? 'Pick and Upload File' : 'Upload', style: const TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      // onPressed: () async => await downloadFile('excel_file.xlsx'),
                      onPressed: () async {
                        await createExcelFile();
                      },
                      child: const Text('Download Excel Format'),
                    ),
                  ],
                ),
              ),
            );
          }, error: (e, stack) {
            return Text(e.toString());
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
        }),
      ),
    );
  }

  ///

  Future<void> pickAndUploadFile({required WidgetRef ref}) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Excel Files',
      extensions: ['xlsx'],
    );
    final XFile? fileResult = await openFile(acceptedTypeGroups: [typeGroup]);

    if (fileResult != null) {
      final File files = File(fileResult.path);
      setState(() {
        file = files;
      });
    } else {
      print("No file selected");
    }
  }

  // Future<void> pickAndUploadFile({required WidgetRef ref}) async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['xlsx'],
  //   );
  //   if (result != null) {
  //     setState(() {
  //       file = File(result.files.single.path!);
  //     });
  //   }
  // }

  Future<void> uploadProducts({
    required File file,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    // print(file.readAsBytesSync());
    try {
      // List<int> data =   file.readAsBytesSync();
      // print(data);
      e.Excel excel = e.Excel.decodeBytes(file.readAsBytesSync());
      var sheet = excel.sheets.keys.first;
      var table = excel.tables[sheet]!;
      for (var row in table.rows) {
        ProductModel? data = await createProductModelFromExcelData(row: row, ref: ref);

        print("Name Of Product: ${data?.productName}");
        print("code: ${data?.productCode}");
        print("Stock: ${data?.productStock}");
        print("Purchasse: ${data?.productPurchasePrice}");
        print("Sales: ${data?.productSalePrice}");
        print("categoryId: ${data?.categoryId}");
        if (data != null) {
          final result = await productRepo.addForBulkUpload(
            productName: data.productName!,
            categoryId: data.categoryId.toString(),
            productCode: data.productCode.toString(),
            productStock: data.productStock.toString(),
            productSalePrice: data.productSalePrice.toString(),
            productPurchasePrice: data.productPurchasePrice.toString(),
            productWholeSalePrice: data.productWholeSalePrice.toString(),
            productManufacturer: data.productManufacturer,
            productDealerPrice: data.productDealerPrice.toString(),
            brandId: data.brandId.toString(),
            unitId: data.unitId.toString(),
          );
          print('product Add Result of ${data.productName}: $result');
        }
      }
      ref.refresh(productProvider);
      ref.refresh(categoryProvider);
      ref.refresh(brandsProvider);
      ref.refresh(unitsProvider);

      Future.delayed(const Duration(seconds: 1), () {
        EasyLoading.showSuccess('Upload Done');
        int count = 0;
        Navigator.popUntil(context, (route) {
          return count++ == 2;
        });
      });
    } catch (e) {
      EasyLoading.showError(e.toString());
      return;
    }
// e.Excel excel= e.Excel.createExcel();
  }

  Future<ProductModel?> createProductModelFromExcelData({
    required List<e.Data?> row,
    required WidgetRef ref,
  }) async {
    // Helper function to get category ID or add a new category
    Future<num?> getCategoryFromDatabase({
      required WidgetRef ref,
      required String givenCategoryName,
    }) async {
      final categoryData = ref.watch(categoryProvider);
      num? categoryId;

      // Wait for the category data to load
      await categoryData.when(
        data: (categories) async {
          for (var element in categories) {
            if (element.categoryName?.toLowerCase().trim() == givenCategoryName.toLowerCase().trim()) {
              categoryId = element.id;
              return;
            }
          }
          // If category is not found, add a new one
          categoryId = await categoryRepo.addCategoryForBulk(
            name: givenCategoryName,
          );
        },
        error: (error, stackTrace) {},
        loading: () {},
      );

      return categoryId;
    }

    // Helper function to get brand ID or add a new category
    Future<num?> getBrandFromDatabase({
      required WidgetRef ref,
      required String givenBrandName,
    }) async {
      final brandData = ref.watch(brandsProvider);
      num? barndId;

      // Wait for the category data to load
      await brandData.when(
        data: (barnds) async {
          for (var element in barnds) {
            if (element.brandName?.toLowerCase().trim() == givenBrandName.toLowerCase().trim()) {
              barndId = element.id;
              return;
            }
          }
          // If category is not found, add a new one
          barndId = await addBrand(brandName: givenBrandName);
        },
        error: (error, stackTrace) {},
        loading: () {},
      );

      return barndId;
    }

    // Helper function to get category ID or add a new category
    Future<num?> getUnitFromDatabase({
      required WidgetRef ref,
      required String givenUnitName,
    }) async {
      final categoryData = ref.watch(unitsProvider);
      num? unitId;

      // Wait for the category data to load
      await categoryData.when(
        data: (categories) async {
          for (var element in categories) {
            if (element.unitName?.toLowerCase().trim() == givenUnitName.toLowerCase().trim()) {
              unitId = element.id;
              return;
            }
          }
          // If category is not found, add a new one
          unitId = await addUnit(unitName: givenUnitName);
        },
        error: (error, stackTrace) {},
        loading: () {},
      );

      return unitId;
    }

    ProductModel productModel = ProductModel();

    // Loop through the row data
    for (var element in row) {
      if (element?.rowIndex == 0) {
        // Skip header row
        return null;
      }

      switch (element?.columnIndex) {
        case 1: // Product name
          if (element?.value == null) return null;
          productModel.productName = element?.value.toString();
          break;
        case 2: // Product code
          if (element?.value == null) return null;
          productModel.productCode = element?.value.toString();
          break;
        case 3: // Product stock
          if (element?.value == null || num.tryParse(element?.value.toString() ?? '') == null) {
            return null;
          }
          productModel.productStock = num.tryParse(element?.value.toString() ?? '') ?? 0;
          break;
        case 4: // Purchase price
          if (element?.value == null || num.tryParse(element?.value.toString() ?? '') == null) {
            return null;
          }
          productModel.productPurchasePrice = num.tryParse(element?.value.toString() ?? '') ?? 0;
          break;
        case 5: // Sales price
          if (element?.value == null || num.tryParse(element?.value.toString() ?? '') == null) {
            return null;
          }
          productModel.productSalePrice = num.tryParse(element?.value.toString() ?? '') ?? 0;
          break;
        case 6: // Wholesale price (optional)
          if (element?.value != null) {
            productModel.productWholeSalePrice = num.tryParse(element?.value.toString() ?? '') ?? 0;
          }
          break;
        case 7: // Dealer price (optional)
          if (element?.value != null) {
            productModel.productDealerPrice = num.tryParse(element?.value.toString() ?? '') ?? 0;
          }
          break;
        case 8: // Category (required)
          if (element?.value == null) return null;
          num? categoryId = await getCategoryFromDatabase(ref: ref, givenCategoryName: element?.value.toString() ?? '');
          print('categoryId $categoryId');
          if (categoryId == null) return null;
          productModel.categoryId = categoryId;
          break;
        case 9: // brand
          if (element?.value != null) {
            print('barand Id ${element?.value}');
            num? id = await getBrandFromDatabase(ref: ref, givenBrandName: element?.value.toString() ?? '');
            print('barand Id $id');
            productModel.brandId = id;
          }

          break;
        case 10: // unit
          if (element?.value != null) {
            print('unit Id ${element?.value}');
            num? id = await getUnitFromDatabase(ref: ref, givenUnitName: element?.value.toString() ?? '');
            productModel.unitId = id;
            print('unit Id $id');
          }
          break;
        case 11: // manufacturer
          if (element?.value != null) {
            productModel.productManufacturer = element?.value.toString();
          }
          break;
      }
    }

    // Return null if any of the required fields are missing
    if (productModel.productName == null || productModel.productCode == null || productModel.productStock == null || productModel.productPurchasePrice == null || productModel.productSalePrice == null || productModel.categoryId == null) {
      return null;
    }

    return productModel;
  }

  Future<num?> addCategory({required String unitsName}) async {
    return await CategoryRepo().addCategoryForBulk(
      name: unitsName,
    );
  }

  Future<num?> addBrand({required String brandName}) async {
    return await brandsRepo.addBrandForBulkUpload(
      name: brandName,
    );
  }

  Future<num?> addUnit({required String unitName}) async {
    return await UnitsRepo().addUnitForBulk(
      name: unitName,
    );
  }
}
