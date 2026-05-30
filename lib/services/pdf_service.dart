import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/maintenance.dart';
import '../models/client.dart';
import '../models/equipment.dart';

class PdfService {
  // Carga las fuentes Roboto (con soporte Unicode completo)
  static Future<_Fonts> _loadFonts() async {
    final regular = await rootBundle.load(
      'fonts/Roboto-Italic-VariableFont_wdth,wght.ttf',
    );
    final bold = await rootBundle.load(
      'fonts/Roboto-VariableFont_wdth,wght.ttf',
    );
    return _Fonts(regular: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
  }

  static String _statusLabel(int v) {
    switch (v) {
      case 1:
        return 'OK';
      case 0:
        return 'No OK';
      case 2:
        return 'N/A';
      default:
        return '-';
    }
  }

  static PdfColor _statusColor(int v) {
    switch (v) {
      case 1:
        return PdfColors.green800;
      case 0:
        return PdfColors.red800;
      default:
        return PdfColors.grey600;
    }
  }

  static String _val(double? v, String unit) => v != null
      ? '${v % 1 == 0 ? v.toInt() : v}${unit.isNotEmpty ? ' $unit' : ''}'
      : '-';

  static Future<File> generate(
    Maintenance m,
    Client client,
    Equipment equipment,
  ) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document();

    // Estilos base con Roboto
    final baseStyle = pw.TextStyle(font: fonts.regular, fontSize: 10);
    final boldStyle = pw.TextStyle(font: fonts.bold, fontSize: 10);
    final whiteStyle = pw.TextStyle(
      font: fonts.regular,
      fontSize: 10,
      color: PdfColors.white,
    );
    final whiteBold = pw.TextStyle(
      font: fonts.bold,
      fontSize: 10,
      color: PdfColors.white,
    );
    final greyStyle = pw.TextStyle(
      font: fonts.regular,
      fontSize: 10,
      color: PdfColors.grey,
    );

    // Firma
    pw.ImageProvider? sigImage;
    if (m.signaturePath != null) {
      final bytes = await File(m.signaturePath!).readAsBytes();
      sigImage = pw.MemoryImage(bytes);
    }

    // Fotos
    final List<pw.ImageProvider> photos = [];
    if (m.photosPaths != null && m.photosPaths!.isNotEmpty) {
      try {
        final paths = List<String>.from(jsonDecode(m.photosPaths!));
        for (final p in paths) {
          final f = File(p);
          if (await f.exists()) {
            photos.add(pw.MemoryImage(await f.readAsBytes()));
          }
        }
      } catch (_) {}
    }

    const blue = PdfColor.fromInt(0xFF1565C0);
    const lightBlue = PdfColor.fromInt(0xFFE3F2FD);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: blue,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MANTENIMIENTO PREVENTIVO',
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text('Equipos de Refrigeración', style: whiteStyle),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Fecha: ${m.date}', style: whiteStyle),
                      pw.Text(
                        'N° ${m.id ?? "-"}',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (ctx) => [
          // Info cliente / equipo
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightBlue,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _row('Cliente', client.name, boldStyle, baseStyle),
                      _row('Planta', client.plant, boldStyle, baseStyle),
                      _row('Técnico', m.technician, boldStyle, baseStyle),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _row(
                        'Equipo N°',
                        '${equipment.number}',
                        boldStyle,
                        baseStyle,
                      ),
                      _row(
                        'Ubicación',
                        equipment.location,
                        boldStyle,
                        baseStyle,
                      ),
                      _row(
                        'Tipo',
                        '${equipment.capacity} BTU · ${equipment.type} · ${equipment.refrigerant}'
                            '${equipment.brand.isNotEmpty ? " · ${equipment.brand}" : ""}',
                        boldStyle,
                        baseStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Checklist
          _sectionTitle('Control de estados', blue, fonts),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeader(['Ítem', 'Estado'], blue, whiteBold),
              _tableRow(
                [
                  'Limpieza de filtro/rejilla unidad interior',
                  _statusLabel(m.filterCleaning),
                ],
                _statusColor(m.filterCleaning),
                baseStyle,
                boldStyle,
              ),
              _tableRow(
                [
                  'Revisión limpieza de serpentina interior',
                  _statusLabel(m.interiorCoilCleaning),
                ],
                _statusColor(m.interiorCoilCleaning),
                baseStyle,
                boldStyle,
              ),
              _tableRow(
                [
                  'Revisión limpieza de serpentina exterior',
                  _statusLabel(m.exteriorCoilCleaning),
                ],
                _statusColor(m.exteriorCoilCleaning),
                baseStyle,
                boldStyle,
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Tensión
          _sectionTitle('Control de tensión de línea', blue, fonts),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeader(['L1–L2', 'L2–L3', 'L3–L1'], blue, whiteBold),
              pw.TableRow(
                children: [
                  _cell(_val(m.voltageL1L2, 'V'), baseStyle),
                  _cell(_val(m.voltageL2L3, 'V'), baseStyle),
                  _cell(_val(m.voltageL3L1, 'V'), baseStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Corriente compresor
          _sectionTitle('Control de corriente de compresor', blue, fonts),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeader(['L1', 'L2', 'L3'], blue, whiteBold),
              pw.TableRow(
                children: [
                  _cell(_val(m.compressorCurrentL1, 'A'), baseStyle),
                  _cell(_val(m.compressorCurrentL2, 'A'), baseStyle),
                  _cell(_val(m.compressorCurrentL3, 'A'), baseStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Corriente forzador
          _sectionTitle('Control de corriente de forzador', blue, fonts),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeader(['L1', 'L2', 'L3'], blue, whiteBold),
              pw.TableRow(
                children: [
                  _cell(_val(m.fanCurrentL1, 'A'), baseStyle),
                  _cell(_val(m.fanCurrentL2, 'A'), baseStyle),
                  _cell(_val(m.fanCurrentL3, 'A'), baseStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Presiones y temperaturas
          _sectionTitle('Presiones y temperaturas', blue, fonts),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeader(
                [
                  'Presión baja',
                  'Presión alta',
                  'T° ambiente',
                  'T° evaporador',
                ],
                blue,
                whiteBold,
              ),
              pw.TableRow(
                children: [
                  _cell(_val(m.lowPressure, 'bar'), baseStyle),
                  _cell(_val(m.highPressure, 'bar'), baseStyle),
                  _cell(_val(m.ambientTemperature, '°C'), baseStyle),
                  _cell(_val(m.evaporatorTemperature, '°C'), baseStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Gas
          _sectionTitle('Carga de gas refrigerante', blue, fonts),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(_val(m.gasCharge, 'kg'), style: baseStyle),
          ),
          pw.SizedBox(height: 14),

          // Observaciones
          if (m.observations.isNotEmpty) ...[
            _sectionTitle('Observaciones', blue, fonts),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                m.observations,
                style: pw.TextStyle(font: fonts.regular, fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // Firma
          if (sigImage != null) ...[
            _sectionTitle('Firma del técnico', blue, fonts),
            pw.SizedBox(height: 6),
            pw.Container(
              height: 100,
              width: 200,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Image(sigImage, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 6),
            pw.Text(m.technician, style: greyStyle),
            pw.SizedBox(height: 14),
          ],

          // Fotos
          if (photos.isNotEmpty) ...[
            _sectionTitle('Registro fotográfico', blue, fonts),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photos
                  .map(
                    (p) => pw.Container(
                      width: 230,
                      height: 160,
                      child: pw.Image(p, fit: pw.BoxFit.cover),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/mant_$ts.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String text, PdfColor color, _Fonts fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 9,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.TableRow _tableHeader(
    List<String> cols,
    PdfColor color,
    pw.TextStyle style,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: color),
      children: cols
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(c, style: style),
            ),
          )
          .toList(),
    );
  }

  static pw.TableRow _tableRow(
    List<String> cols,
    PdfColor valueColor,
    pw.TextStyle base,
    pw.TextStyle bold,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(cols[0], style: base),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(cols[1], style: bold.copyWith(color: valueColor)),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _row(
    String label,
    String value,
    pw.TextStyle bold,
    pw.TextStyle base,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label: ', style: bold),
          pw.Expanded(child: pw.Text(value, style: base)),
        ],
      ),
    );
  }
}

class _Fonts {
  final pw.Font regular;
  final pw.Font bold;
  const _Fonts({required this.regular, required this.bold});
}
