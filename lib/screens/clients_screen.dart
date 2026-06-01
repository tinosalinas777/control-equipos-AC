import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
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
  String? _statusMsg; // mensaje de estado visible en pantalla

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _setStatus(String msg) {
    debugPrint('[ClientsScreen] $msg');
    if (!mounted) return;
    setState(() => _statusMsg = msg);
  }

  Future<void> _load() async {
    _setStatus('Cargando clientes locales...');
    setState(() => _loading = true);

    try {
      final local = await DatabaseHelper.instance.getClients();
      _setStatus('Local: ${local.length} clientes encontrados');

      if (local.isEmpty) {
        _setStatus('Sin datos locales. Descargando de Firestore...');
        try {
          await SyncService.downloadAll();
          _setStatus('Descarga de Firestore completada');
        } catch (e) {
          _setStatus('Error al descargar de Firestore: $e');
        }
      }

      final data = await DatabaseHelper.instance.getClients();
      _setStatus('Mostrando ${data.length} clientes');
      if (!mounted) return;
      setState(() {
        _clients = data;
        _loading = false;
        _statusMsg = null;
      });
    } catch (e) {
      _setStatus('ERROR en _load: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _confirmDelete(Client client) {
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
              Navigator.pop(context);

              // Quitar de la UI inmediatamente
              setState(() {
                _clients.removeWhere((c) => c.id == client.id);
                _statusMsg = 'Eliminando "${client.name}" localmente...';
              });

              // 1. Borrar en SQLite
              try {
                await DatabaseHelper.instance.deleteClient(client.id!);
                _setStatus('Borrado local OK. Sincronizando con Firestore...');
              } catch (e) {
                _setStatus('ERROR al borrar local: $e');
                return;
              }

              // 2. Borrar en Firestore en segundo plano
              SyncService.deleteClient(client.id!).then((_) {
                _setStatus('Borrado en Firestore OK');
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _statusMsg = null);
                });
              }).catchError((e) {
                _setStatus('AVISO: No se pudo borrar en Firestore: $e\n(Se reintentará con conexión)');
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted) setState(() => _statusMsg = null);
                });
              });
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
              final newClient = Client(
                name: nameCtrl.text.trim(),
                plant: plantCtrl.text.trim(),
              );
              final id = await DatabaseHelper.instance.insertClient(newClient);
              Navigator.pop(context);

              SyncService.uploadClient(Client(
                id: id,
                name: newClient.name,
                plant: newClient.plant,
              )).catchError((_) {});

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
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClient,
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Banner de estado visible en pantalla para diagnóstico
          if (_statusMsg != null)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMsg!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
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
          ),
        ],
      ),
    );
  }
}
