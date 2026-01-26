import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../providers/gamification_provider.dart' as game;

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<game.GamificationProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Civic Progress',
          style: GoogleFonts.poppins(
            color: AppTheme.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score Radial Gauge
            SizedBox(
              height: 250,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 1000,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      cornerStyle: CornerStyle.bothCurve,
                      color: AppTheme.glassBorder,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: gameProvider.civicScore.toDouble(),
                        cornerStyle: CornerStyle.bothCurve,
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        gradient: const SweepGradient(
                          colors: [AppTheme.electricBlue, AppTheme.neonCyan],
                        ),
                      )
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        positionFactor: 0.1,
                        angle: 90,
                        widget: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              gameProvider.civicScore.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.electricBlue,
                              ),
                            ),
                            Text(
                              'CIVIC SCORE',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.pureWhite.withOpacity(0.5),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            
            // Level Card
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppTheme.warning, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Level ${gameProvider.level}: Citizen',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Badges Grid
            Text(
              'Your Badges',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.pureWhite,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: gameProvider.badges.length,
              itemBuilder: (context, index) {
                final badge = gameProvider.badges[index];
                return _buildBadgeCard(badge);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(game.Badge badge) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      gradientColors: badge.isUnlocked 
          ? [AppTheme.electricBlue.withOpacity(0.1), AppTheme.electricBlue.withOpacity(0.05)]
          : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.icon, 
            size: 40, 
            color: badge.isUnlocked ? AppTheme.electricBlue : Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: badge.isUnlocked ? AppTheme.pureWhite : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: badge.isUnlocked ? AppTheme.pureWhite.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
