import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report.dart';

class PdfReportService {
  static const PdfColor blueAlcione = PdfColor.fromInt(0xFF001D3D);
  static const PdfColor orangeAlcione = PdfColor.fromInt(0xFFFF6600);

  // Grigio chiaro per i testi secondari nell'header
  static const PdfColor greyText = PdfColor.fromInt(0xFFB0BEC5);

  static Future<void> generaPdf(Report report) async {
    final pdf = pw.Document();

    final fontBold = await PdfGoogleFonts.montserratBold();
    final fontReg = await PdfGoogleFonts.montserratRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: blueAlcione,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("REPORT TECNICO ALCIONE",
                              style: pw.TextStyle(font: fontBold, color: orangeAlcione, fontSize: 9, letterSpacing: 1.2)),
                          pw.SizedBox(height: 6),
                          pw.Text("${report.cognomereport} ${report.nomereport}".toUpperCase(),
                              style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 22)),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Text(report.ruoloSpecifico.toUpperCase(),
                                  style: pw.TextStyle(font: fontBold, color: orangeAlcione, fontSize: 11)),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                                child: pw.Text("•", style: pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                              ),
                              pw.Text("CLASSE ${report.annoreport}",
                                  style: pw.TextStyle(font: fontBold, color: greyText, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("RANKING", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9)),
                        pw.Text("${report.totale}",
                            style: pw.TextStyle(font: fontBold, color: orangeAlcione, fontSize: 34)),
                        pw.Text("MAX 24", style: pw.TextStyle(font: fontBold, color: PdfColors.grey400, fontSize: 7)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              pw.Text("DETTAGLI ATLETA", style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700)),
              pw.Divider(color: orangeAlcione, thickness: 1.5),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 30,
                runSpacing: 15,
                children: [
                  _pdfInfoBox("SQUADRA ATTUALE", report.squadrareport, fontBold),
                  _pdfInfoBox("PIEDE PREFERITO", report.piede, fontBold),
                  _pdfInfoBox("COSTITUZIONE", report.costituzione, fontBold),
                  _pdfInfoBox("STRUTTURA FISICA", report.fisico, fontBold),
                  _pdfInfoBox("OSSERVATORE", report.segnalatore, fontBold),
                ],
              ),

              pw.SizedBox(height: 35),

              pw.Text("PARAMETRI TECNICI", style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700)),
              pw.Divider(color: orangeAlcione, thickness: 1.5),
              pw.SizedBox(height: 15),
              ...report.valutazioni.entries.map((e) => _pdfRatingRow(e.key, e.value, fontBold)),

              pw.SizedBox(height: 35),

              if (report.note != null && report.note!.isNotEmpty) ...[
                pw.Text("ANALISI TECNICA", style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700)),
                pw.Divider(color: orangeAlcione, thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    report.note!,
                    style: pw.TextStyle(font: fontReg, fontSize: 10, lineSpacing: 1.5),
                  ),
                ),
              ],

              pw.Spacer(),

              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ALCIONE MILANO - AREA SCOUTING", style: pw.TextStyle(font: fontBold, fontSize: 8, color: blueAlcione)),
                  pw.Text("Generato il: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      style: pw.TextStyle(font: fontReg, fontSize: 8, color: PdfColors.grey500)),
                ],
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Report_${report.cognomereport}_${report.nomereport}.pdf',
    );
  }

  static pw.Widget _pdfInfoBox(String label, String value, pw.Font bold) {
    return pw.SizedBox(
      width: 120,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 7, color: PdfColors.grey500)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 10, color: blueAlcione)),
        ],
      ),
    );
  }

  static pw.Widget _pdfRatingRow(String key, int val, pw.Font bold) {
    double progressRatio = val == -1 ? 0 : (val / 3.0);
    // Gestione specifica per il Potenziale (voto raddoppiato / 6)
    if (key == 'Potenziale' && val != -1) progressRatio = (val * 2) / 6.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
              width: 110,
              child: pw.Text(key.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 8, color: blueAlcione))
          ),
          pw.Expanded(
            child: pw.Stack(
              alignment: pw.Alignment.centerLeft,
              children: [
                pw.Container(
                  height: 5,
                  decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(2)
                  ),
                ),
                pw.Container(
                  height: 5,
                  // Calcolo manuale approssimativo della larghezza basato su un valore fisso o flessibile
                  width: 300 * progressRatio,
                  decoration: pw.BoxDecoration(
                      color: orangeAlcione,
                      borderRadius: pw.BorderRadius.circular(2)
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
              key == 'Potenziale' ? (val == -1 ? "N.C." : "${val * 2}/6") : (val == -1 ? "N.C." : "$val/3"),
              style: pw.TextStyle(font: bold, fontSize: 9, color: orangeAlcione)
          ),
        ],
      ),
    );
  }
}