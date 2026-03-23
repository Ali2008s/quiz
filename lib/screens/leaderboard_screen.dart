import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/point_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFCC33), size: 40),
                  const SizedBox(width: 15),
                  Text(
                    'قائمة الصدارة',
                    style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),
            
            // Leaderboard content
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: PointService.getLeaderboard(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC33)));
                  }
                  
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد بيانات حالياً',
                        style: GoogleFonts.lalezar(fontSize: 20, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final name = item['name'] ?? 'لاعب مجهول';
                      final points = item['points'] ?? 0;
                      final wins = item['wins'] ?? 0;
                      final isTop3 = index < 3;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isTop3 ? const Color(0xFFFFF9C4) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isTop3 ? const Color(0xFFFFCC33) : const Color(0xFF1A1A1A),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // Rank Number/Icon
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: _getRankColor(index),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.lalezar(fontSize: 18, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // User Name
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.lalezar(fontSize: 22, color: const Color(0xFF1A1A2E)),
                              ),
                            ),
                            // Stats
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Text('$points', style: GoogleFonts.lalezar(fontSize: 18, color: const Color(0xFF2E7D32))),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.stars_rounded, size: 18, color: Color(0xFFFFCC33)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('$wins', style: GoogleFonts.lalezar(fontSize: 14, color: const Color(0xFFEF5350))),
                                    const SizedBox(width: 4),
                                    const Text('فوز', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFCC33); // Gold
    if (index == 1) return const Color(0xFFBDBDBD); // Silver
    if (index == 2) return const Color(0xFFCD7F32); // Bronze
    return const Color(0xFF1A1A2E); // Dark Blue
  }
}
