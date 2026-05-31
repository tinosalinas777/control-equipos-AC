import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/maintenance_provider.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // -1 = sin marcar, 0 = No OK, 1 = OK, 2 = N/A
  late int _filterCleaning;
  late int _interiorCoil;
  late int _exteriorCoil;

  @override
  void initState() {
    super.initState();
    final m = context.read<MaintenanceProvider>().currentMaintenance!;
    _filterCleaning = m.filterCleaning;
    _interiorCoil = m.interiorCoilCleaning;
    _exteriorCoil = m.exteriorCoilCleaning;
  }

  void _save() {
    context.read<MaintenanceProvider>().updateChecklist(
      filterCleaning: _filterCleaning,
      interiorCoilCleaning: _interiorCoil,
      exteriorCoilCleaning: _exteriorCoil,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _CheckItem(
        label: 'Limpieza de filtro/rejilla unidad interior',
        value: _filterCleaning,
        onChanged: (v) => setState(() => _filterCleaning = v),
      ),
      _CheckItem(
        label: 'Revisión limpieza de serpentina interior',
        value: _interiorCoil,
        onChanged: (v) => setState(() => _interiorCoil = v),
      ),
      _CheckItem(
        label: 'Revisión limpieza de serpentina exterior',
        value: _exteriorCoil,
        onChanged: (v) => setState(() => _exteriorCoil = v),
      ),
    ];

    final allMarked = [
      _filterCleaning,
      _interiorCoil,
      _exteriorCoil,
    ].every((v) => v != -1);

    return Scaffold(
      appBar: AppBar(title: const Text('Checklist de limpieza')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _Legend(color: Colors.green, label: 'OK'),
                const SizedBox(width: 12),
                _Legend(color: Colors.red, label: 'No OK'),
                const SizedBox(width: 12),
                _Legend(color: Colors.grey, label: 'N/A'),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildCheckCard(items[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allMarked ? _save : null,
                child: const Text('Guardar checklist'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard(_CheckItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusButton(
                  label: 'OK',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  selected: item.value == 1,
                  onTap: () => item.onChanged(1),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  label: 'No OK',
                  icon: Icons.cancel,
                  color: Colors.red,
                  selected: item.value == 0,
                  onTap: () => item.onChanged(0),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  label: 'N/A',
                  icon: Icons.remove_circle_outline,
                  color: Colors.grey,
                  selected: item.value == 2,
                  onTap: () => item.onChanged(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem {
  final String label;
  final int value;
  final void Function(int) onChanged;
  const _CheckItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.grey.shade100,
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Colors.grey,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
