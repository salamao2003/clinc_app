import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/Billing_logic.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:async';

/// خدمة طباعة الفواتير
/// هذه الخدمة مسؤولة عن إنشاء وطباعة فواتير PDF احترافية
/// تدعم اللغة العربية والإنجليزية
class PrintInvoiceService {
  /// طباعة فاتورة احترافية مع معاينة أولاً
  static Future<void> printInvoice(
    Invoice invoice,
    bool isArabic,
    BuildContext context,
  ) async {
    try {
      final pdf = pw.Document();

      // تحميل الخطوط العربية مع معالجة الأخطاء
      pw.Font? ttfArabic;
      pw.Font? ttfArabicBold;
      pw.ImageProvider? logoImage;
      
      if (isArabic) {
        try {
          final arabicFont = await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
          final arabicFontBold = await rootBundle.load("assets/fonts/NotoSansArabic-Bold.ttf");
          ttfArabic = pw.Font.ttf(arabicFont);
          ttfArabicBold = pw.Font.ttf(arabicFontBold);
        } catch (fontError) {
          print('Warning: Arabic fonts not found, using default fonts');
          // سنستخدم null ليتم استخدام الخط الافتراضي
        }
      }

      // تحميل صورة الشعار
      try {
        final logoBytes = await rootBundle.load("assets/download (1).png");
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (logoError) {
        print('Warning: Logo image not found, proceeding without logo');
      }

      // إنشاء صفحة الفاتورة
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          build: (pw.Context context) {
            return _buildInvoiceContent(invoice, isArabic, ttfArabic, ttfArabicBold, logoImage);
          },
        ),
      );

      // إظهار نافذة المعاينة المخصصة
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SimplePrintPreviewScreen(
            pdfDocument: pdf,
            fileName: _getInvoiceFileName(invoice, isArabic),
            isArabic: isArabic,
          ),
        ),
      );
      
    } catch (e) {
      print('Error in printInvoice: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'خطأ في طباعة الفاتورة: $e' : 'Error printing invoice: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// معاينة الفاتورة في نافذة مخصصة
  static Future<void> previewInvoice(
    Invoice invoice,
    bool isArabic,
    BuildContext context,
  ) async {
    // إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'جاري تحضير المعاينة...' : 'Preparing preview...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      if (!context.mounted) return;
      
      final pdf = pw.Document();

      // تحميل الخطوط العربية مع معالجة الأخطاء
      pw.Font? ttfArabic;
      pw.Font? ttfArabicBold;
      pw.ImageProvider? logoImage;
      
      if (isArabic) {
        try {
          final arabicFont = await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
          final arabicFontBold = await rootBundle.load("assets/fonts/NotoSansArabic-Bold.ttf");
          ttfArabic = pw.Font.ttf(arabicFont);
          ttfArabicBold = pw.Font.ttf(arabicFontBold);
        } catch (fontError) {
          print('Warning: Arabic fonts not found, using default fonts');
          // سنستخدم null ليتم استخدام الخط الافتراضي
        }
      }

      // تحميل صورة الشعار
      try {
        final logoBytes = await rootBundle.load("assets/download (1).png");
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (logoError) {
        print('Warning: Logo image not found, proceeding without logo');
      }

      // إنشاء صفحة الفاتورة
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          build: (pw.Context context) {
            return _buildInvoiceContent(invoice, isArabic, ttfArabic, ttfArabicBold, logoImage);
          },
        ),
      );
      
      // إغلاق مؤشر التحميل
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // إظهار نافذة المعاينة المخصصة
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SimplePrintPreviewScreen(
              pdfDocument: pdf,
              fileName: _getInvoiceFileName(invoice, isArabic),
              isArabic: isArabic,
            ),
          ),
        );
      }
      
    } catch (e) {
      print('Error in previewInvoice: $e');
      
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'خطأ في معاينة الفاتورة: $e' : 'Error previewing invoice: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إظهار نافذة حوار للاختيار بين المعاينة والطباعة المباشرة
  static Future<void> showPrintDialog(
    Invoice invoice,
    bool isArabic,
    BuildContext context,
  ) async {
    try {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.print, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  isArabic ? 'خيارات الطباعة' : 'Print Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            content: Container(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    isArabic 
                      ? 'كيف تريد طباعة الفاتورة؟'
                      : 'How would you like to print the invoice?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            actions: [
              // زر المعاينة
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.preview, color: Colors.white),
                  label: Text(
                    isArabic ? 'معاينة أولاً' : 'Preview First',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      Navigator.of(context).pop();
                      await previewInvoice(invoice, isArabic, context);
                    } catch (e) {
                      print('Error in preview: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic ? 'خطأ في المعاينة' : 'Preview error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              SizedBox(height: 8),
              // زر الطباعة المباشرة
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.print, color: Colors.white),
                  label: Text(
                    isArabic ? 'طباعة مباشرة' : 'Print Directly',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      Navigator.of(context).pop();
                      await printInvoice(invoice, isArabic, context);
                    } catch (e) {
                      print('Error in direct print: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic ? 'خطأ في الطباعة' : 'Print error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              SizedBox(height: 8),
              // زر الإلغاء
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  child: Text(
                    isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error in showPrintDialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'خطأ في عرض خيارات الطباعة' : 'Error showing print options'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إنشاء محتوى الفاتورة
  static pw.Widget _buildInvoiceContent(
    Invoice invoice, 
    bool isArabic, 
    pw.Font? ttfArabic, 
    pw.Font? ttfArabicBold,
    pw.ImageProvider? logoImage
  ) {
    try {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // رأس الفاتورة
          _buildHeader(isArabic, ttfArabic, ttfArabicBold, logoImage),
          pw.SizedBox(height: 10),
          
          // عنوان الشركة
          _buildCompanyAddress(isArabic, ttfArabic),
          pw.SizedBox(height: 10),
          
          // معلومات الفاتورة والعميل
          _buildBillToAndInvoiceDetails(invoice, isArabic, ttfArabic, ttfArabicBold),
          pw.SizedBox(height: 10),
          
          // صندوق الملخص
          _buildSummaryBox(invoice, isArabic, ttfArabic),
          pw.SizedBox(height: 10),
          
          // جدول الخدمات
          _buildServicesTable(invoice, isArabic, ttfArabic, ttfArabicBold),
          pw.SizedBox(height: 8),
          
          // قسم الإجمالي
          _buildTotalSection(invoice, isArabic, ttfArabicBold),
          pw.Spacer(),
          
          // التذييل
          _buildFooter(isArabic, ttfArabic),
          
          // ملاحظة حالة الدفع
          if (invoice.paymentStatus != 'Paid') ...[
            pw.SizedBox(height: 15),
            _buildPaymentStatusNote(invoice, isArabic, ttfArabic, ttfArabicBold),
          ],
        ],
      );
    } catch (e) {
      print('Error building invoice content: $e');
      // إرجاع محتوى بديل في حالة الخطأ
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              isArabic ? 'خطأ في إنشاء محتوى الفاتورة' : 'Error creating invoice content',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              e.toString(),
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  /// إنشاء رأس الفاتورة
  static pw.Widget _buildHeader(bool isArabic, pw.Font? ttfArabic, pw.Font? ttfArabicBold, pw.ImageProvider? logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // عنوان الفاتورة
        pw.Text(
          isArabic ? 'فاتورة' : 'Invoice',
          style: pw.TextStyle(
            font: (isArabic && ttfArabicBold != null) ? ttfArabicBold : null,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        // شعار الشركة
        _buildCompanyLogo(isArabic, ttfArabic, ttfArabicBold, logoImage),
      ],
    );
  }

  /// إنشاء شعار الشركة
  static pw.Widget _buildCompanyLogo(bool isArabic, pw.Font? ttfArabic, pw.Font? ttfArabicBold, pw.ImageProvider? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // إضافة صورة الشعار إذا كانت متوفرة
        if (logoImage != null) ...[
          pw.Image(
            logoImage,
            width: 60,
            height: 60,
            fit: pw.BoxFit.contain,
          ),
          pw.SizedBox(height: 8),
        ],
        
        // اسم الشركة
        pw.Text(
          isArabic ? 'العيادة الطبية' : 'Smart Dental',
          style: pw.TextStyle(
            font: (isArabic && ttfArabicBold != null) ? ttfArabicBold : null,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.Text(
          isArabic ? 'النظام الطبي' : 'CLINIC',
          style: pw.TextStyle(
            font: (isArabic && ttfArabic != null) ? ttfArabic : null,
            fontSize: 11,
            color: PdfColors.black,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
      ],
    );
  }

  /// إنشاء عنوان الشركة
  static pw.Widget _buildCompanyAddress(bool isArabic, pw.Font? ttfArabic) {
    return pw.Text(
      isArabic 
        ? 'العيادة الطبية، شارع الطب، القاهرة 1061، مصر'
        : 'MediCare Clinic, 125 Industry Road, Cairo 1061, Egypt',
      style: pw.TextStyle(
        font: isArabic ? ttfArabic : null,
        fontSize: 10,
        color: PdfColors.grey700,
      ),
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    );
  }

  /// إنشاء معلومات الفاتورة والعميل
  static pw.Widget _buildBillToAndInvoiceDetails(
    Invoice invoice, 
    bool isArabic, 
    pw.Font? ttfArabic, 
    pw.Font? ttfArabicBold
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // الجهة المرسلة إليها الفاتورة
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isArabic ? 'إرسال الفاتورة إلى' : 'BILL TO',
                style: pw.TextStyle(
                  font: isArabic ? ttfArabicBold : null,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                isArabic ? 'المريض' : 'Patient',
                style: pw.TextStyle(
                  font: isArabic ? ttfArabic : null,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                invoice.patientName,
                style: pw.TextStyle(
                  font: isArabic ? ttfArabic : null,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                invoice.phoneNumber,
                style: pw.TextStyle(
                  font: isArabic ? ttfArabic : null,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        
        // تفاصيل الفاتورة
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  isArabic ? 'التاريخ :' : 'Date :',
                  style: pw.TextStyle(
                    font: isArabic ? ttfArabic : null,
                    fontSize: 10,
                  ),
                  textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// إنشاء صندوق الملخص
  static pw.Widget _buildSummaryBox(Invoice invoice, bool isArabic, pw.Font? ttfArabic) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        children: [
          // التاريخ
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                border: pw.Border.all(color: PdfColors.grey600),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isArabic ? 'التاريخ' : 'Date',
                    style: pw.TextStyle(
                      font: isArabic ? ttfArabic : null,
                      fontSize: 10,
                      color: PdfColors.black,
                    ),
                    textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  ),
                  pw.Text(
                    '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // الإجمالي
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                border: pw.Border.all(color: PdfColors.grey600),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isArabic ? 'الإجمالي (ج.م)' : 'Total due (EGP)',
                    style: pw.TextStyle(
                      font: isArabic ? ttfArabic : null,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  ),
                  pw.Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} LE',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// إنشاء جدول الخدمات
  static pw.Widget _buildServicesTable(
    Invoice invoice, 
    bool isArabic, 
    pw.Font? ttfArabic, 
    pw.Font? ttfArabicBold
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          // رأس الجدول
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  isArabic ? 'الوصف' : 'Description',
                  style: pw.TextStyle(
                    font: isArabic ? ttfArabicBold : null,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  isArabic ? 'الكمية' : 'Quantity',
                  style: pw.TextStyle(
                    font: isArabic ? ttfArabicBold : null,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  isArabic ? 'السعر (ج.م)' : 'Unit price (LE)',
                  style: pw.TextStyle(
                    font: isArabic ? ttfArabicBold : null,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  isArabic ? 'المبلغ (ج.م)' : 'Amount (LE)',
                  style: pw.TextStyle(
                    font: isArabic ? ttfArabicBold : null,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
            ],
          ),
          // صفوف الخدمات
          ...invoice.services.map((service) => pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  service.serviceName,
                  style: pw.TextStyle(
                    font: isArabic ? ttfArabic : null,
                    fontSize: 8,
                  ),
                  textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${service.quantity}',
                  style: pw.TextStyle(
                    fontSize: 8,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${service.unitPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${service.totalPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          )).toList(),
        ],
      ),
    );
  }

  /// إنشاء قسم الإجمالي
  static pw.Widget _buildTotalSection(Invoice invoice, bool isArabic, pw.Font? ttfArabicBold) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Container(),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    isArabic ? 'المجموع (ج.م):' : 'Total (EGP):',
                    style: pw.TextStyle(
                      font: isArabic ? ttfArabicBold : null,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                    textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  ),
                  pw.Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} LE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// إنشاء تذييل الفاتورة
  static pw.Widget _buildFooter(bool isArabic, pw.Font? ttfArabic) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isArabic ? 'العيادة الطبية' : 'MediCare',
                style: pw.TextStyle(
                  font: isArabic ? ttfArabic : null,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                isArabic ? 'شارع الطب' : '125 Industry Road',
                style: pw.TextStyle(
                  font: isArabic ? ttfArabic : null,
                  fontSize: 10,
                ),
                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                isArabic ? 'القاهرة 1061، مصر' : 'Cairo 1061, Egypt',
                style: pw.TextStyle(
                  font: isArabic ? ttfArabic : null,
                  fontSize: 10,
                ),
                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ],
          ),
          pw.Text(
            isArabic 
              ? 'info@mediclinic.co.eg' 
              : 'info@medicareclinic.co.eg',
            style: pw.TextStyle(
              font: isArabic ? ttfArabic : null,
              fontSize: 10,
            ),
            textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  /// إنشاء ملاحظة حالة الدفع
  static pw.Widget _buildPaymentStatusNote(
    Invoice invoice, 
    bool isArabic, 
    pw.Font? ttfArabic, 
    pw.Font? ttfArabicBold
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        isArabic 
          ? 'تنبيه: هذه الفاتورة ${_getStatusTextArabic(invoice.paymentStatus).toLowerCase()}'
          : 'Note: This invoice is ${invoice.paymentStatus.toLowerCase()}',
        style: pw.TextStyle(
          font: isArabic ? ttfArabicBold : null,
          fontSize: 10,
          color: PdfColors.red,
          fontWeight: pw.FontWeight.bold,
        ),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    );
  }

  // Helper method to get Arabic status text
  static String _getStatusTextArabic(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'مدفوعة';
      case 'unpaid':
        return 'غير مدفوعة';
      case 'partially paid':
        return 'مدفوعة جزئياً';
      default:
        return status;
    }
  }

  /// الحصول على اسم ملف الفاتورة
  static String _getInvoiceFileName(Invoice invoice, bool isArabic) {
    return isArabic ? 'فاتورة_${invoice.id.substring(0, 8)}' : 'Invoice_${invoice.id.substring(0, 8)}';
  }
}

/// شاشة معاينة مبسطة للطباعة بدون أزرار المشاركة
class SimplePrintPreviewScreen extends StatefulWidget {
  final pw.Document pdfDocument;
  final String fileName;
  final bool isArabic;

  const SimplePrintPreviewScreen({
    Key? key,
    required this.pdfDocument,
    required this.fileName,
    required this.isArabic,
  }) : super(key: key);

  @override
  State<SimplePrintPreviewScreen> createState() => _SimplePrintPreviewScreenState();
}

class _SimplePrintPreviewScreenState extends State<SimplePrintPreviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  Future<void> _initializePreview() async {
    try {
      // تأخير بسيط للسماح للمعاينة بالتحميل
      await Future.delayed(const Duration(milliseconds: 300));
      
      // اختبار إنشاء PDF للتأكد من عدم وجود أخطاء
      await widget.pdfDocument.save();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? 'معاينة الفاتورة' : 'Invoice Preview'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                try {
                  await Printing.layoutPdf(
                    onLayout: (format) => widget.pdfDocument.save(),
                    name: widget.fileName,
                    format: PdfPageFormat.a4,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isArabic ? 'خطأ في الطباعة' : 'Print error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isArabic ? 'جاري تحميل المعاينة...' : 'Loading preview...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic ? 'خطأ في تحميل الفاتورة' : 'Error loading invoice',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializePreview();
                },
                child: Text(widget.isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PdfPreview(
              build: (format) async {
                try {
                  return await widget.pdfDocument.save();
                } catch (e) {
                  print('Error generating PDF preview: $e');
                  rethrow;
                }
              },
              allowSharing: false,
              allowPrinting: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              actions: const [],
              useActions: false,
              maxPageWidth: 700,
              previewPageMargin: const EdgeInsets.all(8),
              scrollViewDecoration: const BoxDecoration(
                color: Colors.white,
              ),
              pdfPreviewPageDecoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              initialPageFormat: PdfPageFormat.a4,
              dpi: 150, // زيادة الجودة
              onError: (context, error) {
                print('PDF Preview Error: $error');
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isArabic ? 'خطأ في عرض الفاتورة' : 'Error displaying invoice',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
              onPrinted: (context) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isArabic ? 'تم إرسال الفاتورة للطباعة' : 'Invoice sent to printer',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
