import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/banner_ad_widget.dart';
import 'reels_tab.dart';
import 'shorts_tab.dart';
import 'whatsapp_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Smart Saver',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 2,
              color: const Color(0xFF102542),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
            tabs: [
              Tab(text: 'Reels'),
              Tab(text: 'Shorts'),
              Tab(text: 'WhatsApp'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                  ),
                ),
                child: const TabBarView(
                  children: [
                    ReelsTab(),
                    ShortsTab(),
                    WhatsAppTab(),
                  ],
                ),
              ),
            ),
            // Banner Ad at the bottom
            const BannerAdWidget(
              margin: EdgeInsets.only(bottom: 8),
              showBorder: false,
            ),
          ],
        ),
      ),
    );
  }
}