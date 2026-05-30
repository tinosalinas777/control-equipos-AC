import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/maintenance_provider.dart';
import 'checklist_screen.dart';
import 'measurements_screen.dart';
import 'photos_screen.dart';
import 'signature_screen.dart';
import 'summary_screen.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MaintenanceProvider>();
    final m = prov.currentMaintenance;
    final eq = prov.selectedEquipment;
    final cl = prov.selectedClient;

    if (m == null || eq == null || cl == null) {
      return const Scaffold(body: Center(child: Text('Error: sin datos')));
    }

    final steps = [
      _StepItem(
        icon: Icons.checklist,
        label: 'Checklist',
        subtitle: 'Control de limpieza',
        color: Colors.blue,
        done: m.filterCleaning != -1,
        screen: const ChecklistScreen(),
      ),
      _StepItem(
        icon: Icons.speed,
        label: 'Mediciones',
        subtitle: 'Tensiones, corrientes, presiones',
        color: Colors.orange,
        done: m.voltageL1L2 != null,
        screen: const MeasurementsScreen(),
      ),
      _StepItem(
        icon: Icons.photo_camera,
        label: 'Fotos',
        subtitle: 'Evidencia fotográfica',
        color: Colors.green,
        done: m.photosPaths != null,
        screen: const PhotosScreen(),
      ),
      _StepItem(
        icon: Icons.draw,
        label: 'Firma',
        subtitle: 'Firma del técnico',
        color: Colors.purple,
        done: m.signaturePath != null,
        screen: const SignatureScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo mantenimiento', style: TextStyle(fontSize: 16)),
            Text('Eq. ${eq.number} · ${eq.location}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Cabecera resumen del equipo
          Container(
            width: double.infinity,
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.ac_unit,
                        color: Color(0xFF1565C0), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(eq.location,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                              '${eq.capacity} BTU · ${eq.type} · ${eq.refrigerant}${eq.brand.isNotEmpty ? ' · ${eq.brand}' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text('Técnico: ${m.technician}  ·  ${m.date}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pasos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...steps.map((s) => _buildStepCard(context, s)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.summarize),
                    label: const Text('Ver resumen y guardar',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SummaryScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, _StepItem step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: step.done
                ? Colors.green.shade50
                : step.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            step.done ? Icons.check_circle : step.icon,
            color: step.done ? Colors.green : step.color,
            size: 28,
          ),
        ),
        title: Text(step.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(step.subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (step.done)
              const Text('Listo',
                  style:
                      TextStyle(color: Colors.green, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => step.screen),
        ),
      ),
    );
  }
}

class _StepItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool done;
  final Widget screen;

  _StepItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.done,
    required this.screen,
  });
}
