import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/analytics_model.dart';

// ---------------------------------------------------------------------------
// NOT: Bu servis excel ve pdf paketlerini kullanir.
// pubspec.yaml'a asagidakilerin eklenmesi gerekir:
//   excel: ^4.0.6
//   pdf: ^3.11.1
//   printing: ^5.13.1
//   path_provider: ^2.1.4   (zaten mevcut olabilir)
//   share_plus: ^10.0.0
//
// Paketler henuz eklenmemisse CSV formatinda export yapilir.
// ---------------------------------------------------------------------------

class ReportExportService {
  static final _currencyFmt = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  static final _dateFmt = DateFormat('dd.MM.yyyy');
  static final _filenameFmt = DateFormat('yyyyMMdd_HHmm');

  // -------------------------------------------------------------------------
  // CSV export — paket bagimliligisiz, her zaman calisir
  // -------------------------------------------------------------------------
  Future<void> exportToCsv({
    required List<AnalyticsDailySalesData> salesData,
    required List<AnalyticsTopProductData> products,
    required List<FieldAgentPerformanceData> agents,
    required DateTimeRange dateRange,
  }) async {
    final buffer = StringBuffer();

    // Baslık satiri
    buffer.writeln('Nisa Ticaret - Satis Raporu');
    buffer.writeln(
      'Donem: ${_dateFmt.format(dateRange.start)} - ${_dateFmt.format(dateRange.end)}',
    );
    buffer.writeln('Olusturulma: ${_dateFmt.format(DateTime.now())}');
    buffer.writeln();

    // --- Gunluk Satislar ---
    buffer.writeln('== GUNLUK SATISLAR ==');
    buffer.writeln('Tarih,Gelir (TL),Siparis Sayisi,Ort. Siparis (TL)');
    for (final day in salesData) {
      buffer.writeln(
        '${_dateFmt.format(day.date)},'
        '${day.revenue.toStringAsFixed(2)},'
        '${day.orderCount},'
        '${day.averageOrderValue.toStringAsFixed(2)}',
      );
    }
    buffer.writeln();

    // --- Urun Performansi ---
    buffer.writeln('== URUN PERFORMANSI ==');
    buffer.writeln(
        'Urun,Kategori,Satis Adedi,Toplam Gelir (TL),Gelir Payi (%)');
    for (final p in products) {
      buffer.writeln(
        '${p.productName},'
        '${p.categoryName},'
        '${p.totalQuantity},'
        '${p.totalRevenue.toStringAsFixed(2)},'
        '${(p.revenueShare * 100).toStringAsFixed(1)}',
      );
    }
    buffer.writeln();

    // --- Saha Performansi ---
    buffer.writeln('== SAHA PERSONELI PERFORMANSI ==');
    buffer.writeln(
        'Personel,Toplam Siparis,Toplam Gelir (TL),Ort. Siparis (TL),Müşteri Sayisi');
    for (final a in agents) {
      buffer.writeln(
        '${a.agentName},'
        '${a.totalOrders},'
        '${a.totalRevenue.toStringAsFixed(2)},'
        '${a.averageOrderValue.toStringAsFixed(2)},'
        '${a.customersServed}',
      );
    }

    final fileName =
        'nisa_rapor_${_filenameFmt.format(DateTime.now())}.csv';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Nisa Ticaret Raporu',
      text:
          'Nisa Ticaret Satis Raporu\n'
          'Donem: ${_dateFmt.format(dateRange.start)} - '
          '${_dateFmt.format(dateRange.end)}',
    );
  }

  // -------------------------------------------------------------------------
  // PDF export — pw paketi olmadan temel metin PDF olusturur (dart:io + share)
  // Gercek implementasyon icin pdf: ^3.11.1 paketi eklenmelidir.
  // -------------------------------------------------------------------------
  Future<void> exportSummaryAsTxt({
    required List<AnalyticsDailySalesData> salesData,
    required List<AnalyticsTopProductData> products,
    required DateTimeRange dateRange,
  }) async {
    final totalRevenue = salesData.fold(0.0, (s, d) => s + d.revenue);
    final totalOrders = salesData.fold(0, (s, d) => s + d.orderCount);
    final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    final buffer = StringBuffer();
    buffer.writeln('==========================================');
    buffer.writeln('       NISA TICARET - SATIS RAPORU       ');
    buffer.writeln('==========================================');
    buffer.writeln(
      'Donem: ${_dateFmt.format(dateRange.start)} - '
      '${_dateFmt.format(dateRange.end)}',
    );
    buffer.writeln('Olusturulma: ${_dateFmt.format(DateTime.now())}');
    buffer.writeln('------------------------------------------');
    buffer.writeln('OZET');
    buffer.writeln(
        'Toplam Gelir : ${_currencyFmt.format(totalRevenue)}');
    buffer.writeln('Toplam Siparis: $totalOrders adet');
    buffer.writeln(
        'Ort. Siparis : ${_currencyFmt.format(avgOrder)}');
    buffer.writeln('------------------------------------------');
    buffer.writeln('EN COK SATILAN URUNLER (ilk 5)');

    final top5 = products.take(5).toList();
    for (int i = 0; i < top5.length; i++) {
      final p = top5[i];
      buffer.writeln(
        '${i + 1}. ${p.productName} — '
        '${p.totalQuantity} adet — '
        '${_currencyFmt.format(p.totalRevenue)}',
      );
    }
    buffer.writeln('==========================================');

    final fileName =
        'nisa_rapor_${_filenameFmt.format(DateTime.now())}.txt';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Nisa Ticaret Raporu',
    );
  }

  // -------------------------------------------------------------------------
  // Kategori rengi yardimci metodu
  // -------------------------------------------------------------------------
  static String categoryColorHex(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'su':
        return '00A6AB';
      case 'gazli':
      case 'gazli icecek':
        return 'E73A99';
      case 'meyve suyu':
        return '13275A';
      default:
        return 'FF9800';
    }
  }
}

final reportExportServiceProvider =
    Provider<ReportExportService>((ref) => ReportExportService());
