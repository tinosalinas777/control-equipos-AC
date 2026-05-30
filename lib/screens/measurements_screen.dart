import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/maintenance_provider.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  // Tensiones
  final _vL1L2 = TextEditingController();
  final _vL2L3 = TextEditingController();
  final _vL3L1 = TextEditingController();

  // Corrientes compresor
  final _ccL1 = TextEditingController();
  final _ccL2 = TextEditingController();
  final _ccL3 = TextEditingController();

  // Corrientes forzador
  final _cfL1 = TextEditingController();
  final _cfL2 = TextEditingController();
  final _cfL3 = TextEditingController();

  // Presiones
  final _lowP = TextEditingController();
  final _highP = TextEditingController();

  // Temperaturas
  final _ambTemp = TextEditingController();
  final _evapTemp = TextEditingController();

  // Gas
  final _gas = TextEditingController();

  // Observaciones
  final _obs = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = context.read<MaintenanceProvider>().currentMaintenance!;
    _vL1L2.text = _str(m.voltageL1L2);
    _vL2L3.text = _str(m.voltageL2L3);
    _vL3L1.text = _str(m.voltageL3L1);
    _ccL1.text = _str(m.compressorCurrentL1);
    _ccL2.text = _str(m.compressorCurrentL2);
    _ccL3.text = _str(m.compressorCurrentL3);
    _cfL1.text = _str(m.fanCurrentL1);
    _cfL2.text = _str(m.fanCurrentL2);
    _cfL3.text = _str(m.fanCurrentL3);
    _lowP.text = _str(m.lowPressure);
    _highP.text = _str(m.highPressure);
    _ambTemp.text = _str(m.ambientTemperature);
    _evapTemp.text = _str(m.evaporatorTemperature);
    _gas.text = _str(m.gasCharge);
    _obs.text = m.observations;
  }

  String _str(double? v) => v != null ? v.toString() : '';
  double? _parse(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  void _save() {
    context.read<MaintenanceProvider>().updateMeasurements(
          voltageL1L2: _parse(_vL1L2.text),
          voltageL2L3: _parse(_vL2L3.text),
          voltageL3L1: _parse(_vL3L1.text),
          compressorCurrentL1: _parse(_ccL1.text),
          compressorCurrentL2: _parse(_ccL2.text),
          compressorCurrentL3: _parse(_ccL3.text),
          fanCurrentL1: _parse(_cfL1.text),
          fanCurrentL2: _parse(_cfL2.text),
          fanCurrentL3: _parse(_cfL3.text),
          lowPressure: _parse(_lowP.text),
          highPressure: _parse(_highP.text),
          ambientTemperature: _parse(_ambTemp.text),
          evaporatorTemperature: _parse(_evapTemp.text),
          gasCharge: _parse(_gas.text),
          observations: _obs.text,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mediciones')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Section(
              title: 'Control de tensión de línea (V)',
              icon: Icons.bolt,
              color: Colors.amber.shade700,
              child: Row(children: [
                Expanded(child: _Field('L1–L2', _vL1L2, 'V')),
                const SizedBox(width: 8),
                Expanded(child: _Field('L2–L3', _vL2L3, 'V')),
                const SizedBox(width: 8),
                Expanded(child: _Field('L3–L1', _vL3L1, 'V')),
              ]),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Corriente de compresor (A)',
              icon: Icons.compress,
              color: Colors.blue.shade700,
              child: Row(children: [
                Expanded(child: _Field('L1', _ccL1, 'A')),
                const SizedBox(width: 8),
                Expanded(child: _Field('L2', _ccL2, 'A')),
                const SizedBox(width: 8),
                Expanded(child: _Field('L3', _ccL3, 'A')),
              ]),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Corriente de forzador (A)',
              icon: Icons.air,
              color: Colors.teal.shade700,
              child: Row(children: [
                Expanded(child: _Field('L1', _cfL1, 'A')),
                const SizedBox(width: 8),
                Expanded(child: _Field('L2', _cfL2, 'A')),
                const SizedBox(width: 8),
                Expanded(child: _Field('L3', _cfL3, 'A')),
              ]),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Presiones de gas (bar)',
              icon: Icons.speed,
              color: Colors.purple.shade700,
              child: Row(children: [
                Expanded(child: _Field('Baja', _lowP, 'bar')),
                const SizedBox(width: 8),
                Expanded(child: _Field('Alta', _highP, 'bar')),
              ]),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Temperaturas (°C)',
              icon: Icons.thermostat,
              color: Colors.red.shade700,
              child: Row(children: [
                Expanded(child: _Field('Ambiente', _ambTemp, '°C')),
                const SizedBox(width: 8),
                Expanded(child: _Field('Evaporador', _evapTemp, '°C')),
              ]),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Carga de gas refrigerante (kg)',
              icon: Icons.gas_meter,
              color: Colors.green.shade700,
              child: _Field('Cantidad', _gas, 'kg'),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Observaciones',
              icon: Icons.notes,
              color: Colors.grey.shade700,
              child: TextField(
                controller: _obs,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Observaciones del técnico...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Guardar mediciones'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _vL1L2, _vL2L3, _vL3L1,
      _ccL1, _ccL2, _ccL3,
      _cfL1, _cfL2, _cfL3,
      _lowP, _highP,
      _ambTemp, _evapTemp,
      _gas, _obs,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String unit;

  const _Field(this.label, this.ctrl, this.unit);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[,.]?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}
