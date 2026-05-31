import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
import '../models/maintenance.dart';
import '../services/maintenance_provider.dart';
import '../services/pdf_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _saving = false;
  bool _saved = false;
  Maintenance? _savedMaintenance;

  String _statusLabel(int v) {
    switch (v) {
      case 1: return 'OK';
      case 0: return 'No OK';
      case 2: return 'N/A';
      default: return '—';
    }
  }

  Color _statusColor(int v) {
    switch (v) {
      case 1: return Colors.green;
      case 0: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _val(double? v, String unit) =>
      v != null ? '${v % 1 == 0 ? v.toInt() : v} $unit' : '—';

  Future<void> _save() async {
    setState(() => _saving = true);
    final prov = context.read<MaintenanceProvider>();
    final m = prov.currentMaintenance!;
    final id = await DatabaseHelper.instance.insertMaintenance(m);
    final saved = await DatabaseHelper.instance.getMaintenance(id);

    // Sincroniza con Firestore en segundo plano
    if (saved != null) {
      try {
        await SyncService.saveMaintenance(
          saved,
          saved.clientId,
          saved.equipmentId,
        );
      } catch (_) {
        // Si falla la sync no interrumpe el flujo (modo offline)
      }
    }

    setState(() {
      _saving = false;
      _saved = true;
      _savedMaintenance = saved;
    });
  }

  Future<void> _generatePdf() async {
    final prov = context.read<MaintenanceProvider>();
    final m = _savedMaintenance ?? prov.currentMaintenance!;
    final client = prov.selectedClient!;
    final equipment = prov.selectedEquipment!;

    try {
      final file = await PdfService.generate(m, client, equipment);
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: 'mantenimiento_${equipment.number}_${m.date.replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

  void _finish() {
    // popUntil ANTES de reset() para evitar rebuild con datos nulos
    final prov = context.read<MaintenanceProvider>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    prov.reset();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MaintenanceProvider>();
    final m = prov.currentMaintenance;
    if (m == null) return const Scaffold(body: SizedBox());
    final eq = prov.selectedEquipment;
    final cl = prov.selectedClient;
    if (eq == null || cl == null) return const Scaffold(body: SizedBox());

    List<String> photos = [];
    if (m.photosPaths != null) {
      try {
        photos = List<String>.from(jsonDecode(m.photosPaths!));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen del mantenimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: const Color(0xFFE3F2FD),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Cliente', cl.name),
                    _row('Planta', cl.plant),
                    _row('Equipo', 'N° ${eq.number} · ${eq.location}'),
                    _row('Tipo', '${eq.capacity} BTU · ${eq.type} · ${eq.refrigerant}'),
                    _row('Técnico', m.technician),
                    _row('Fecha', m.date),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Checklist
            _sectionTitle('Checklist de limpieza'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _checkRow('Filtro/rejilla interior', m.filterCleaning),
                    _checkRow('Serpentina interior', m.interiorCoilCleaning),
                    _checkRow('Serpentina exterior', m.exteriorCoilCleaning),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mediciones
            _sectionTitle('Mediciones eléctricas'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _measureGroup('Tensión de línea', [
                      'L1–L2: ${_val(m.voltageL1L2, 'V')}',
                      'L2–L3: ${_val(m.voltageL2L3, 'V')}',
                      'L3–L1: ${_val(m.voltageL3L1, 'V')}',
                    ]),
                    const Divider(),
                    _measureGroup('Corriente compresor', [
                      'L1: ${_val(m.compressorCurrentL1, 'A')}',
                      'L2: ${_val(m.compressorCurrentL2, 'A')}',
                      'L3: ${_val(m.compressorCurrentL3, 'A')}',
                    ]),
                    const Divider(),
                    _measureGroup('Corriente forzador', [
                      'L1: ${_val(m.fanCurrentL1, 'A')}',
                      'L2: ${_val(m.fanCurrentL2, 'A')}',
                      'L3: ${_val(m.fanCurrentL3, 'A')}',
                    ]),
                    const Divider(),
                    _measureGroup('Presiones', [
                      'Baja: ${_val(m.lowPressure, 'bar')}',
                      'Alta: ${_val(m.highPressure, 'bar')}',
                    ]),
                    const Divider(),
                    _measureGroup('Temperaturas', [
                      'Ambiente: ${_val(m.ambientTemperature, '°C')}',
                      'Evaporador: ${_val(m.evaporatorTemperature, '°C')}',
                    ]),
                    const Divider(),
                    _measureGroup('Gas refrigerante', [
                      'Carga: ${_val(m.gasCharge, 'kg')}',
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Observaciones
            if (m.observations.isNotEmpty) ...[
              _sectionTitle('Observaciones'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(m.observations),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Firma
            _sectionTitle('Firma'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: m.signaturePath != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(m.signaturePath!),
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(m.technician,
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : const Text('Sin firma',
                        style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 12),

            // Fotos
            _sectionTitle('Fotos (${photos.length})'),
            if (photos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Sin fotos', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photos[i]),
                        width: 100, height: 100, fit: BoxFit.cover),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Acciones
            if (!_saved) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Guardando...' : 'Guardar mantenimiento'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Mantenimiento guardado correctamente',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generar y compartir PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  onPressed: _generatePdf,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al inicio'),
                  onPressed: _finish,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1565C0)),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _checkRow(String label, int status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                color: _statusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measureGroup(String title, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            children: values
                .map((v) => Text(v, style: const TextStyle(fontSize: 13)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
