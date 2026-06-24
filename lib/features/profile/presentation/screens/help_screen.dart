import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    {
      'q': 'Siparisimi nasil takip ederim?',
      'a':
          'Siparislerim ekranindan tum siparislerinizi takip edebilirsiniz.',
    },
    {
      'q': 'Teslimat ne kadar surer?',
      'a':
          'Siparisleriniz genellikle ayni gun veya ertesi gun teslim edilir.',
    },
    {
      'q': 'Siparisimi iptal edebilir miyim?',
      'a':
          'Siparis hazirlanmaya baslamadan once iptal edebilirsiniz.',
    },
    {
      'q': 'Damacana teslimi nasil calisir?',
      'a': 'Yeni damacana getirirken eski damacanayi aliriz.',
    },
    {
      'q': 'Nasil uye olabilirim?',
      'a':
          'Telefon numaranizla kayit olabilirsiniz, herhangi bir form doldurmana gerek yok.',
    },
  ];

  Future<void> _launchWhatsapp() async {
    final uri = Uri.parse('https://wa.me/905000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+905000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text('Yardım & İletişim'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // SSS baslik
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Sik Sorulan Sorular',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // SSS accordion
          ..._faq.map((faq) => _FaqItem(question: faq['q']!, answer: faq['a']!)),

          // Iletisim baslik
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Bize Ulasin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // WhatsApp butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Material(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(46),
              child: InkWell(
                onTap: _launchWhatsapp,
                borderRadius: BorderRadius.circular(46),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'WhatsApp ile Yaz',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Telefon butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Material(
              color: AppColors.waterBlue,
              borderRadius: BorderRadius.circular(46),
              child: InkWell(
                onTap: _launchPhone,
                borderRadius: BorderRadius.circular(46),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+90 500 000 0000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [AppShadows.sm],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: AppColors.surface,
          collapsedBackgroundColor: AppColors.surface,
          iconColor: AppColors.primary,
          children: [
            Text(
              answer,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
