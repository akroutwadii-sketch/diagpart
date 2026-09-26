import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ExcelHelper {
  static Future<void> exportToExcel(List<Map<String, dynamic>> parts) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['مخزون DiagPart'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('الرقم'),
      TextCellValue('اسم القطعة'),
      TextCellValue('رقم القطعة (Part Number)'),
      TextCellValue('السيارة/الموديل'),
      TextCellValue('السعر'),
      TextCellValue('مكان التخزين'),
      TextCellValue('الحالة'),
    ]);

    for (var i = 0; i < parts.length; i++) {
      var item = parts[i];
      sheetObject.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item['name'] ?? ''),
        TextCellValue(item['partNumber'] ?? ''),
        TextCellValue(item['brandModel'] ?? ''),
        DoubleCellValue(double.tryParse(item['price'].toString()) ?? 0.0),
        TextCellValue(item['location'] ?? ''),
        TextCellValue(item['isSold'] == 1 ? 'مباعة' : 'متاحة'),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/DiagPart_Inventory_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await OpenFile.open(filePath);
    }
  }
}
