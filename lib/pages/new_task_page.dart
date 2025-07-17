import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class NewTaskPage extends StatefulWidget {
  const NewTaskPage({super.key});

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final titleCtrl = TextEditingController();
  bool estado = false;
  DateTime? fecha;
  bool compartida = false;

  XFile? pickedImage; // Imagen seleccionada (web y móvil)
  Uint8List? imageBytes; // Solo para web: bytes de la imagen

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            pickedImage = picked;
            imageBytes = bytes;
          });
        } else {
          setState(() {
            pickedImage = picked;
            imageBytes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La cámara no está soportada en web.')));
      return;
    }
    try {
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        setState(() {
          pickedImage = picked;
          imageBytes = null;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (pickedImage == null) return null;

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final uuid = const Uuid().v4();
    final path = 'tareas/$userId/$uuid.jpg';

    try {
      final storage = Supabase.instance.client.storage.from('imagenes');

      if (kIsWeb && imageBytes != null) {
        await storage.uploadBinary(
          path,
          imageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      } else if (!kIsWeb) {
        final file = File(pickedImage!.path);
        await storage.upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
      }

      final publicUrl = storage.getPublicUrl(path);
      debugPrint('Imagen subida con URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveTask() async {
    final titulo = titleCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El título es obligatorio')));
      return;
    }
    final fechaTask = fecha ?? DateTime.now();

    final userId = Supabase.instance.client.auth.currentUser!.id;

    String? imageUrl = await _uploadImage();

    try {
      await Supabase.instance.client.from('tareas').insert({
        'user_id': userId,
        'titulo': titulo,
        'estado': estado,
        'fecha': fechaTask.toIso8601String(),
        'imagen_url': imageUrl,
        'compartida': compartida,
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando tarea: $e')));
    }
  }

  Widget _buildImagePreview() {
    if (pickedImage == null) {
      return const Text(
        'No se ha seleccionado imagen',
        style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.memory(imageBytes!, height: 180, fit: BoxFit.contain),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.file(File(pickedImage!.path), height: 180, fit: BoxFit.contain),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFF0D47A1); // Azul oscuro elegante
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text(
          'Nueva Tarea',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: mainColor, fontWeight: FontWeight.w600),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                fillColor: mainColor.withOpacity(0.1),
                filled: true,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: estado,
                        onChanged: (val) => setState(() => estado = val ?? false),
                        activeColor: mainColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '¿Completada?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: compartida,
                        onChanged: (val) => setState(() => compartida = val ?? false),
                        activeColor: mainColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '¿Compartida?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                fecha == null
                    ? 'Seleccionar fecha'
                    : 'Fecha: ${DateFormat.yMMMd().format(fecha!)}',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: mainColor),
              ),
              trailing: Icon(Icons.calendar_today, color: mainColor),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fecha ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: mainColor,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: mainColor,
                        ),
                        dialogBackgroundColor: Colors.white,
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    fecha = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            _buildImagePreview(),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo, color: Colors.white),
                  label: const Text(
                    'Galería',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Cámara',
                    style: TextStyle(fontWeight: FontWeight.w600,color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Guardar tarea',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color:Colors.white ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 7,
                  shadowColor: mainColor.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
