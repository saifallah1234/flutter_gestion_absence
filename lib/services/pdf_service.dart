// lib/services/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAbsencesPdf({
    required String nom,
    required String prenom,
    required List<Map<String, dynamic>> seances,
  }) async {
    final pdf = pw.Document();

    // Filter only absence records (statut != 'present')
    final absencesList = seances.where((s) => s['statut'] != 'present').toList();
    final presentsList = seances.where((s) => s['statut'] == 'present').toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header with logo
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FSB Bizerte',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'Faculté des Sciences de Bizerte',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(30),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'FSB',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          
          // Title
          pw.Center(
            child: pw.Text(
              'RAPPORT D\'ABSENCES',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Student info card
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Informations de l\'étudiant',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Nom complet: $prenom $nom'),
                    ),
                    pw.Expanded(
                      child: pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Statistics section
          pw.Text(
            'Statistiques',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          
          pw.Row(
            children: [
              _buildStatCard('Total séances', seances.length, PdfColors.blue700),
              _buildStatCard('Présences', presentsList.length, PdfColors.green700),
              _buildStatCard('Absences', absencesList.length, PdfColors.red700),
            ],
          ),
          
          pw.SizedBox(height: 30),
          
          // Absences list title
          pw.Text(
            'Liste des absences',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Absences table
          if (absencesList.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Aucune absence enregistrée',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.Table.fromTextArray(
              headers: ['N°', 'Matière', 'Date', 'Heure', 'Statut'],
              data: absencesList.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final s = entry.value;
                return [
                  index.toString(),
                  s['matiere'] ?? '-',
                  _formatDate(s['date_seance'] ?? ''),
                  s['heure_debut'] ?? '-',
                  s['statut'] == 'justifié' ? 'JUSTIFIÉ' : 'ABSENT',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
              cellStyle: pw.TextStyle(fontSize: 11),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
            ),
          
          pw.SizedBox(height: 30),
          
          // All sessions table
          pw.Text(
            'Toutes les séances',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['N°', 'Matière', 'Date', 'Heure', 'Statut'],
            data: seances.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final s = entry.value;
              String statutText = '';
              PdfColor statutColor = PdfColors.grey700;
              if (s['statut'] == 'present') {
                statutText = 'PRÉSENT';
              } else if (s['statut'] == 'justifié') {
                statutText = 'JUSTIFIÉ';
              } else {
                statutText = 'ABSENT';
              }
              return [
                index.toString(),
                s['matiere'] ?? '-',
                _formatDate(s['date_seance'] ?? ''),
                s['heure_debut'] ?? '-',
                statutText,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            cellStyle: pw.TextStyle(fontSize: 11),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
          
          pw.SizedBox(height: 30),
          
          // Footer
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Document généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
              pw.Text(
                'FSB Sanctuary - Gestion des Absences',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _buildStatCard(String title, int value, PdfColor color) {
  return pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.all(5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        // Simulate opacity manually
        color: PdfColor(color.red, color.green, color.blue, 0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor(color.red, color.green, color.blue, 0.3),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value.toString(),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    ),
  );
}

  static String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }
}