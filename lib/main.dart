import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'db_helper.dart';
import 'excel_helper.dart';
import 'edit_item_screen.dart';

void main() {
  runApp(DiagPartApp());
}

class DiagPartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiagPart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: InventoryScreen(),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  TextEditingController _searchController = TextEditingController();

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
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 40),
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم القطعة / السيارة'),
                    ),
                    TextField(
                      controller: partNumberController,
                      decoration: const InputDecoration(labelText: 'رقم القطعة'),
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
                      Navigator.pop(context);
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
        title: const Text('DiagPart - مخزون الورشة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () async {
              await ExcelHelper.exportToExcel(_items);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تصدير ملف Excel بنجاح')),
              );
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
                ? const Center(child: Text('لا توجد قطع مسجلة'))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final String? imgPath = item['imagePath'];
                      final String partNum = item['partNumber'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
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
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync()
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(File(imgPath), fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.build, size: 35, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? '',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      if (partNum.isNotEmpty)
                                        Text('رقم القطعة: $partNum', style: const TextStyle(color: Colors.black87)),
                                      if ((item['location'] ?? '').toString().isNotEmpty)
                                        Text('المكان: ${item['location']}', style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item['price'] ?? 0.0}',
                                      style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                    const Text('متاحة', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
