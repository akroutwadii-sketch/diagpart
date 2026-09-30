import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExcelHelper {
  static Future<String?> exportToExcel(List<Map<String, dynamic>> items) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Inventory'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('الاسم'),
      TextCellValue('رقم القطعة'),
      TextCellValue('السعر'),
      TextCellValue('المكان'),
    ]);

    for (var item in items) {
      sheetObject.appendRow([
        IntCellValue(item['id'] ?? 0),
        TextCellValue(item['name'] ?? ''),
        TextCellValue(item['partNumber'] ?? ''),
        DoubleCellValue(double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0),
        TextCellValue(item['location'] ?? ''),
      ]);
    }

    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      String filePath = "${directory.path}/DiagPart_Inventory.xlsx";
      File file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      return filePath;
    }
    return null;
  }
}
