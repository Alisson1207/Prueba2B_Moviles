import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'new_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> tareas = [];

  @override
  void initState() {
    super.initState();
    cargarTareas();
  }

  Future<void> cargarTareas() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('tareas')
        .select()
        .or('user_id.eq.$userId,compartida.eq.true')
        .order('fecha', ascending: false);

    setState(() {
      tareas = response;
    });
  }

  Future<void> marcarCompletada(String id, bool estadoActual) async {
    await Supabase.instance.client
        .from('tareas')
        .update({'estado': !estadoActual})
        .eq('id', id);

    await cargarTareas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Mis Tareas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewTaskPage()),
          );
          cargarTareas();
        },
      ),
      body: tareas.isEmpty
          ? const Center(child: Text('No hay tareas'))
          : ListView.builder(
              itemCount: tareas.length,
              itemBuilder: (context, index) {
                final tarea = tareas[index];
                final tieneImagen = tarea['imagen_url'] != null && tarea['imagen_url'].toString().isNotEmpty;
                final esCompartida = tarea['compartida'] == true;

                return Card(
  elevation: 4,
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tarea['titulo'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tarea['estado'] ? '✅ Completada' : '⏳ Pendiente',
                style: TextStyle(
                  color: tarea['estado'] ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tarea['compartida'] == true ? '👥 Tarea compartida' : '👤 Solo para mí',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              tarea['estado'] ? Icons.check_box : Icons.check_box_outline_blank,
              color: tarea['estado'] ? Colors.green : null,
            ),
            onPressed: () => marcarCompletada(tarea['id'], tarea['estado']),
          ),
        ),
        if (tarea['imagen_url'] != null && tarea['imagen_url'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                tarea['imagen_url'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.contain, // para que la imagen no se recorte y se vea completa
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          ),
      ],
    ),
  ),
);

              },
            ),
    );
  }
}
