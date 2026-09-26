import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'db_helper.dart';
import 'excel_helper.dart';

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
  List<Map<String, dynamic>> _allParts = [];
  List<Map<String, dynamic>> _filteredParts = [];
  bool _isLoading = true;
  bool _isSearching = false;

  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _partNumController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchAndRefreshParts();
  }

  Future<void> _fetchAndRefreshParts() async {
    final dataList = await DBHelper.getData('parts');
    setState(() {
      _allParts = dataList;
      _filteredParts = dataList;
      _isLoading = false;
    });
  }

  void _filterParts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredParts = _allParts;
      });
    } else {
      setState(() {
        _filteredParts = _allParts.where((part) {
          final name = part['name'].toString().toLowerCase();
          final partNum = part['partNumber'].toString().toLowerCase();
          final brand = part['brandModel'].toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
                 partNum.contains(searchLower) ||
                 brand.contains(searchLower);
        }).toList();
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addPart() async {
    if (_nameController.text.isEmpty) return;

    final newPart = {
      'name': _nameController.text,
      'partNumber': _partNumController.text,
      'brandModel': _brandController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'location': _locationController.text,
      'imagePath': _selectedImage?.path,
      'isSold': 0,
    };

    await DBHelper.insert('parts', newPart);
    await _fetchAndRefreshParts();

    _nameController.clear();
    _partNumController.clear();
    _brandController.clear();
    _priceController.clear();
    _locationController.clear();
    _selectedImage = null;

    Navigator.of(context).pop();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 16, left: 16, right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('إضافة قطعة جديدة - DiagPart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    await _takePhoto();
                    setModalState(() {});
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.grey[700]),
                              SizedBox(height: 5),
                              Text('التقط صورة للقطعة'),
                            ],
                          ),
                  ),
                ),
                TextField(controller: _nameController, decoration: InputDecoration(labelText: 'اسم القطعة')),
                TextField(controller: _partNumController, decoration: InputDecoration(labelText: 'رقم القطعة (Part Number / OE)')),
                TextField(controller: _brandController, decoration: InputDecoration(labelText: 'السيارة / الموديل')),
                TextField(controller: _priceController, decoration: InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number),
                TextField(controller: _locationController, decoration: InputDecoration(labelText: 'مكان التخزين (الرف)')),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addPart,
                  child: Text('حفظ القطعة'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'ابحث برقم القطعة أو الاسم...',
                  border: InputBorder.none,
                ),
                onChanged: _filterParts,
              )
            : Text('DiagPart - مخزون الورشة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.table_chart),
            tooltip: 'تصدير إلى Excel',
            onPressed: () async {
              if (_allParts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('لا توجد قطع لتصديرها!')),
                );
                return;
              }
              await ExcelHelper.exportToExcel(_allParts);
            },
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filterParts('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredParts.isEmpty
              ? Center(child: Text('لا توجد قطعة مسجلة مطابقة'))
              : ListView.builder(
                  itemCount: _filteredParts.length,
                  itemBuilder: (ctx, index) {
                    final item = _filteredParts[index];
                    final bool isSold = item['isSold'] == 1;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: item['imagePath'] != null && File(item['imagePath']).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(item['imagePath']),
                                  width: 60, height: 60, fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 60, height: 60,
                                color: Colors.grey[300],
                                child: Icon(Icons.build),
                              ),
                        title: Text(
                          '${item['name']} - ${item['brandModel']}',
                          style: TextStyle(
                            decoration: isSold ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text('رقم القطعة: ${item['partNumber']}\nالمكان: ${item['location']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item['price']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSold ? Colors.grey : Colors.green,
                              ),
                            ),
                            Text(
                              isSold ? 'مباعة' : 'متاحة',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSold ? Colors.red : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        onLongPress: () async {
                          await DBHelper.updateSoldStatus(item['id'], isSold ? 0 : 1);
                          _fetchAndRefreshParts();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
