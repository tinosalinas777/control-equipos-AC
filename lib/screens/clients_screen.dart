import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import 'equipment_screen.dart';
import 'history_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getClients();
    setState(() {
      _clients = data;
      _loading = false;
    });
  }

  void _confirmDelete(client) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Eliminás "${client.name}"?\n\n'
          'También se borrarán todos sus equipos y mantenimientos.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteClient(client.id!);
              if (!mounted) return;
              Navigator.pop(context);
              _load();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _addClient() {
    final nameCtrl = TextEditingController();
    final plantCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: plantCtrl,
              decoration: const InputDecoration(labelText: 'Planta'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await DatabaseHelper.instance.insertClient(
                Client(
                    name: nameCtrl.text.trim(),
                    plant: plantCtrl.text.trim()),
              );
              Navigator.pop(context);
              _load();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClient,
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? const Center(child: Text('No hay clientes cargados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _clients.length,
                  itemBuilder: (context, i) {
                    final c = _clients[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0),
                          child: Text(
                            c.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(c.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Planta: ${c.plant}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              tooltip: 'Eliminar cliente',
                              onPressed: () => _confirmDelete(c),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EquipmentScreen(client: c)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
