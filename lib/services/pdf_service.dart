import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../etudiants/absences.dart'; // adjust path

class PdfService {
  static Future<void> generateAbsencesPdf({
    required String nom,
    required String prenom,
    required List<Absence> absences,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Rapport des absences',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Text('Étudiant: $prenom $nom'),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['Matière', 'Date', 'Heure', 'Statut'],
            data: absences.map((a) {
              return [
                a.matiere,
                a.dateSeance,
                a.heureDebut,
                a.statut,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}