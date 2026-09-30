import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'db_helper.dart';
import 'excel_helper.dart';
import 'edit_item_screen.dart';
import 'barcode_scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiagPartApp());
}

class DiagPartApp extends StatelessWidget {
  const DiagPartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiagPart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const InventoryScreen(),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() async {
    final data = await DBHelper.getData('parts');
    setState(() {
      _items = data;
      _filteredItems = data;
    });
  }

  void _filterItems(String query) {
    final filtered = _items.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final partNumber = (item['partNumber'] ?? '').toString().toLowerCase();
      final location = (item['location'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      return name.contains(q) || partNumber.contains(q) || location.contains(q);
    }).toList();

    setState(() {
      _filteredItems = filtered;
    });
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final partNumberController = TextEditingController();
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('إضافة قطعة جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setStateSB(() {
                            imagePath = picked.path;
                          });
                        }
                      },
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 35),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم القطعة / السيارة'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: partNumberController,
                            decoration: const InputDecoration(labelText: 'رقم القطعة'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
                            );
                            if (res != null) {
                              setStateSB(() => partNumberController.text = res);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.green),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final XFile? img = await picker.pickImage(source: ImageSource.camera);
                            if (img != null) {
                              final inputImage = InputImage.fromFilePath(img.path);
                              final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
                              final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
                              await textRecognizer.close();
                              if (recognizedText.text.isNotEmpty) {
                                setStateSB(() => partNumberController.text = recognizedText.text.trim());
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعر'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'المكان'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      await DBHelper.insert('parts', {
                        'name': nameController.text,
                        'partNumber': partNumberController.text,
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'location': locationController.text,
                        'imagePath': imagePath,
                      });
                      _refreshItems();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DiagPart - إدارة القطع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'تصدير Excel',
            onPressed: () async {
              String? path = await ExcelHelper.exportToExcel(_items);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(path != null ? 'تم حفظ الملف في: $path' : 'حدث خطأ أثناء التصدير')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: 'بحث باسم القطعة، الرقم، أو المكان...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('لا توجد قطع مسجلة حتى الآن'))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final String? imgPath = item['imagePath'];
                      final String partNum = item['partNumber'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(File(imgPath), fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.build, color: Colors.grey),
                          ),
                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('رقم: $partNum | المكان: ${item['location'] ?? ''}'),
                          trailing: Text(
                            '${item['price'] ?? 0.0}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onTap: () async {
                            bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditItemScreen(item: item),
                              ),
                            );
                            if (updated == true) {
                              _refreshItems();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
