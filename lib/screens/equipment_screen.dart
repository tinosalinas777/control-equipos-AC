import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/equipment.dart';
import '../services/maintenance_provider.dart';
import 'maintenance_screen.dart';

class EquipmentScreen extends StatefulWidget {
  final Client client;
  const EquipmentScreen({super.key, required this.client});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<Equipment> _all = [];
  List<Equipment> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance
        .getEquipmentsByClient(widget.client.id!);
    setState(() {
      _all = data;
      _filtered = _applyFilter(data, _searchCtrl.text);
      _loading = false;
    });
  }

  List<Equipment> _applyFilter(List<Equipment> list, String q) {
    if (q.isEmpty) return list;
    final lq = q.toLowerCase();
    return list
        .where((e) =>
            e.location.toLowerCase().contains(lq) ||
            e.number.toString().contains(lq) ||
            e.brand.toLowerCase().contains(lq))
        .toList();
  }

  void _filter() {
    setState(() => _filtered = _applyFilter(_all, _searchCtrl.text));
  }

  // ── AGREGAR EQUIPO ────────────────────────────────────────────────────────
  void _addEquipment() {
    final numCtrl      = TextEditingController();
    final locationCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    String type        = 'Split';
    String refrigerant = 'R410';
    final brandCtrl    = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Agregar equipo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: numCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'N° equipo *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Capacidad (BTU) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['Split', 'Piso/Techo', 'Multisplit', 'Cassette']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setS(() => type = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: refrigerant,
                  decoration: const InputDecoration(
                    labelText: 'Refrigerante',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['R410', 'R22', 'R32', 'R407C']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setS(() => refrigerant = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: brandCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (numCtrl.text.isEmpty ||
                    locationCtrl.text.isEmpty ||
                    capacityCtrl.text.isEmpty) {
                  return;
                }
                await DatabaseHelper.instance.insertEquipment(Equipment(
                  clientId: widget.client.id!,
                  number: int.parse(numCtrl.text),
                  location: locationCtrl.text.trim(),
                  capacity: capacityCtrl.text.trim(),
                  type: type,
                  refrigerant: refrigerant,
                  brand: brandCtrl.text.trim(),
                ));
                if (!mounted) return;
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── ELIMINAR EQUIPO ───────────────────────────────────────────────────────
  void _confirmDelete(Equipment eq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar equipo'),
        content: Text(
          '¿Eliminás "${eq.location}" (N° ${eq.number})?\n\n'
          'También se borrarán todos los mantenimientos registrados para este equipo.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteEquipment(eq.id!);
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

  // ── INICIAR MANTENIMIENTO ─────────────────────────────────────────────────
  void _startMaintenance(Equipment equipment) {
    final techCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Iniciar mantenimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipo: ${equipment.displayName}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
                '${equipment.capacity} BTU · ${equipment.type} · ${equipment.refrigerant}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: techCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del técnico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (techCtrl.text.trim().isEmpty) return;
              context.read<MaintenanceProvider>().startMaintenance(
                    widget.client,
                    equipment,
                    techCtrl.text.trim(),
                  );
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
              );
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  Color _refrigerantColor(String ref) =>
      ref == 'R22' ? Colors.orange.shade700 : Colors.green.shade700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.client.name, style: const TextStyle(fontSize: 16)),
            Text('Planta ${widget.client.plant}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEquipment,
        backgroundColor: const Color(0xFF1565C0),
        tooltip: 'Agregar equipo',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por ubicación, N° o marca...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filtered.length} equipo${_filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ac_unit,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Sin equipos',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _addEquipment,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar equipo'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final eq = _filtered[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                  '${eq.number}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: Text(eq.location,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${eq.capacity} BTU · ${eq.type}'
                                  '${eq.brand.isNotEmpty ? ' · ${eq.brand}' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _refrigerantColor(eq.refrigerant)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      eq.refrigerant,
                                      style: TextStyle(
                                        color:
                                            _refrigerantColor(eq.refrigerant),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    tooltip: 'Eliminar equipo',
                                    onPressed: () => _confirmDelete(eq),
                                  ),
                                ],
                              ),
                              onTap: () => _startMaintenance(eq),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
