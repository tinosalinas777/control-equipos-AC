//import 'dart:convert';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
//import 'package:provider/provider.dart';
import '../database/database_helper.dart';
//import '../models/maintenance.dart';
import '../models/client.dart';
import '../models/equipment.dart';
//import '../services/maintenance_provider.dart';
import '../services/pdf_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  // estado de generación de PDF por id de mantenimiento
  final Map<int, bool> _generating = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance.getMaintenancesWithDetails();
    setState(() {
      _all = data;
      _filtered = data;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all
          .where(
            (m) =>
                (m['client_name'] ?? '').toLowerCase().contains(q) ||
                (m['eq_location'] ?? '').toLowerCase().contains(q) ||
                (m['technician'] ?? '').toLowerCase().contains(q) ||
                (m['date'] ?? '').contains(q),
          )
          .toList();
    });
  }

  // ── VER / REENVIAR PDF ────────────────────────────────────────────────────
  Future<void> _openOrGeneratePdf(Map<String, dynamic> row) async {
    final id = row['id'] as int;
    setState(() => _generating[id] = true);

    try {
      final maintenance = await DatabaseHelper.instance.getMaintenance(id);
      if (maintenance == null) {
        throw Exception('No se encontro el mantenimiento #$id');
      }

      // Reconstruye Client desde el JOIN
      final client = Client(
        id: maintenance.clientId,
        name: (row['client_name'] as String?) ?? 'Cliente',
        plant: (row['client_plant'] as String?) ?? '',
      );

      // Equipo desde DB; si fue eliminado usa datos del JOIN como fallback
      Equipment equipment;
      final dbEq = await DatabaseHelper.instance.getEquipment(
        maintenance.equipmentId,
      );
      if (dbEq != null) {
        equipment = dbEq;
      } else {
        equipment = Equipment(
          id: maintenance.equipmentId,
          clientId: maintenance.clientId,
          number: (row['eq_number'] as int?) ?? 0,
          location: (row['eq_location'] as String?) ?? 'Desconocido',
          capacity: '',
          type: (row['eq_type'] as String?) ?? '',
          refrigerant: '',
          brand: (row['eq_brand'] as String?) ?? '',
        );
      }

      // Siempre regenera (tmp se limpia entre sesiones)
      final file = await PdfService.generate(maintenance, client, equipment);
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'mant_${equipment.number}_${maintenance.date.replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _generating.remove(id));
    }
  }

  // ── HELPERS DE UI ─────────────────────────────────────────────────────────
  String _statusLabel(int? v) {
    switch (v) {
      case 1:
        return 'OK';
      case 0:
        return 'No OK';
      case 2:
        return 'N/A';
      default:
        return '—';
    }
  }

  Color _statusColor(int? v) {
    switch (v) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de mantenimientos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, equipo, técnico o fecha...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} registro${_filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin registros',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      final id = m['id'] as int;
                      final hasPdf =
                          m['pdf_path'] != null &&
                          (m['pdf_path'] as String).isNotEmpty;
                      final isGenerating = _generating[id] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            // ── Cabecera con botón PDF ──────────────────
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF1565C0,
                                ).withValues(alpha: 0.1),
                                child: Text(
                                  '#$id',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                m['eq_location'] ?? '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${m['client_name']} · ${m['technician']} · ${m['date']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isGenerating
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      tooltip: hasPdf
                                          ? 'Ver / reenviar PDF'
                                          : 'Generar PDF',
                                      icon: Icon(
                                        Icons.picture_as_pdf,
                                        color: hasPdf
                                            ? Colors.deepOrange
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _openOrGeneratePdf(m),
                                    ),
                            ),

                            // ── Detalle expandible ──────────────────────
                            ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              title: const Text(
                                'Ver detalle',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const Text(
                                        'Checklist',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _statusChip(
                                        'Filtro/rejilla',
                                        m['filter_cleaning'],
                                      ),
                                      _statusChip(
                                        'Serpentina interior',
                                        m['interior_coil_cleaning'],
                                      ),
                                      _statusChip(
                                        'Serpentina exterior',
                                        m['exterior_coil_cleaning'],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mediciones',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _measureLine(
                                        'Tensión L1–L2',
                                        m['voltage_l1_l2'],
                                        'V',
                                      ),
                                      _measureLine(
                                        'Tensión L2–L3',
                                        m['voltage_l2_l3'],
                                        'V',
                                      ),
                                      _measureLine(
                                        'Tensión L3–L1',
                                        m['voltage_l3_l1'],
                                        'V',
                                      ),
                                      _measureLine(
                                        'Corriente Comp. L1',
                                        m['compressor_current_l1'],
                                        'A',
                                      ),
                                      _measureLine(
                                        'Corriente Forzador L1',
                                        m['fan_current_l1'],
                                        'A',
                                      ),
                                      _measureLine(
                                        'Presión baja',
                                        m['low_pressure'],
                                        'bar',
                                      ),
                                      _measureLine(
                                        'Presión alta',
                                        m['high_pressure'],
                                        'bar',
                                      ),
                                      _measureLine(
                                        'T° ambiente',
                                        m['ambient_temperature'],
                                        '°C',
                                      ),
                                      _measureLine(
                                        'T° evaporador',
                                        m['evaporator_temperature'],
                                        '°C',
                                      ),
                                      _measureLine(
                                        'Gas refrigerante',
                                        m['gas_charge'],
                                        'kg',
                                      ),
                                      if ((m['observations'] ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Observaciones',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(m['observations'] ?? ''),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, int? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(value).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(value),
              style: TextStyle(
                color: _statusColor(value),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measureLine(String label, dynamic value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value != null ? '$value $unit' : '—',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
