import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'db_helper.dart';

class EditItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController nameController;
  late TextEditingController partNumberController;
  late TextEditingController priceController;
  late TextEditingController locationController;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item['name'] ?? '');
    partNumberController = TextEditingController(text: widget.item['partNumber'] ?? '');
    priceController = TextEditingController(text: widget.item['price']?.toString() ?? '0.0');
    locationController = TextEditingController(text: widget.item['location'] ?? '');
    imagePath = widget.item['imagePath'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveChanges() async {
    Map<String, dynamic> updatedItem = {
      'id': widget.item['id'],
      'name': nameController.text,
      'partNumber': partNumberController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'location': locationController.text,
      'imagePath': imagePath,
    };

    await DBHelper.update('parts', updatedItem);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteItem() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت تأكد من أنك تريد حذف هذه القطعة نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.delete('parts', widget.item['id']);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل / حذف القطعة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteItem,
            tooltip: 'حذف',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'حفظ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: imagePath != null && imagePath!.isNotEmpty
                    ? Image.file(File(imagePath!), fit: BoxFit.cover)
                    : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            const Text('اضغط لتغيير الصورة', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
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
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _deleteItem,
                    child: const Text('حذف القطعة', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('حفظ التغييرات'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
