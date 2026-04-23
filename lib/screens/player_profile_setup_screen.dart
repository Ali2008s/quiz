import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/audio_service.dart';

/// شاشة إعداد الملف الشخصي - اختيار الاسم والصورة الشخصية
class PlayerProfileSetupScreen extends StatefulWidget {
  final Widget nextScreen;
  final String? title;

  const PlayerProfileSetupScreen({
    super.key,
    required this.nextScreen,
    this.title,
  });

  @override
  State<PlayerProfileSetupScreen> createState() =>
      _PlayerProfileSetupScreenState();
}

class _PlayerProfileSetupScreenState extends State<PlayerProfileSetupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  String _selectedAvatar = AuthService.availableAvatars[0];
  bool _isSaving = false;

  late AnimationController _floatController;
  late AnimationController _entryController;
  late Animation<double> _floatAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  // صور شخصيات مجسمة جميلة
  static const List<Map<String, String>> avatarCategories = [
    {
      'label': 'أبطال',
      'url':
          'https://api.dicebear.com/7.x/avataaars/png?seed=hero1&backgroundColor=b6e3f4'
    },
    {
      'label': 'محاربون',
      'url':
          'https://api.dicebear.com/7.x/avataaars/png?seed=warrior&backgroundColor=ffdfbf'
    },
    {
      'label': 'سحرة',
      'url':
          'https://api.dicebear.com/7.x/avataaars/png?seed=mage&backgroundColor=c0aede'
    },
    {
      'label': 'ملوك',
      'url':
          'https://api.dicebear.com/7.x/avataaars/png?seed=king&backgroundColor=ffd5dc'
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entryController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndProceed() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('من فضلك اكتب اسمك!',
              style: GoogleFonts.lalezar(fontSize: 16)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    AudioService.playClick();
    await AuthService.setUserName(name);
    await AuthService.setUserAvatar(_selectedAvatar);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  // ── الرأس ──
                  SlideTransition(
                    position: _slideAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // أيقونة متحركة طائرة
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: child,
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFF8C00)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_pin_rounded,
                                  color: Colors.white, size: 55),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.title ?? 'أهلاً بك! 👋',
                            style: GoogleFonts.lalezar(
                              fontSize: 32,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                    color: Color(0xFFFFD700),
                                    blurRadius: 10,
                                    offset: Offset(0, 0))
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'اختر اسمك وشخصيتك قبل البدء',
                            style: GoogleFonts.lalezar(
                              fontSize: 16,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── معاينة الأفاتار المختار ──
                  SlideTransition(
                    position: _slideAnim,
                    child: _buildSelectedAvatarPreview(),
                  ),

                  const SizedBox(height: 24),

                  // ── حقل الاسم ──
                  SlideTransition(
                    position: _slideAnim,
                    child: _buildNameField(),
                  ),

                  const SizedBox(height: 24),

                  // ── اختيار الأفاتار ──
                  SlideTransition(
                    position: _slideAnim,
                    child: _buildAvatarSelector(),
                  ),

                  const SizedBox(height: 32),

                  // ── زر الدخول ──
                  SlideTransition(
                    position: _slideAnim,
                    child: _buildStartButton(),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAvatarPreview() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.5),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E54E9).withValues(alpha: 0.6),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.transparent,
          backgroundImage: NetworkImage(_selectedAvatar),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        textAlign: TextAlign.center,
        style: GoogleFonts.lalezar(
          fontSize: 20,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: '✏️ اكتب اسمك هنا...',
          hintStyle: GoogleFonts.lalezar(
            color: Colors.white38,
            fontSize: 18,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: const Icon(Icons.person_outline_rounded,
              color: Color(0xFF8E54E9), size: 26),
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 14),
          child: Row(
            children: [
              const Icon(Icons.face_retouching_natural,
                  color: Color(0xFFFFD700), size: 22),
              const SizedBox(width: 8),
              Text(
                'اختر صورتك الشخصية:',
                style: GoogleFonts.lalezar(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // شبكة الأفاتارات
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: AuthService.availableAvatars.length,
          itemBuilder: (context, index) {
            final avatar = AuthService.availableAvatars[index];
            final isSelected = avatar == _selectedAvatar;

            return GestureDetector(
              onTap: () {
                AudioService.playClick();
                setState(() => _selectedAvatar = avatar);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                transform: Matrix4.identity()..scale(isSelected ? 1.12 : 1.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        )
                      : null,
                  color:
                      isSelected ? null : Colors.white.withValues(alpha: 0.1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.7),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 3 : 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF8E54E9),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // صف إضافي من الأفاتار الخاصة بالشخصيات 3D
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 10, top: 4),
          child: Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFF4776E6), size: 20),
              const SizedBox(width: 8),
              Text(
                'شخصيات حصرية:',
                style: GoogleFonts.lalezar(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: AuthService.extraAvatars.length,
            itemBuilder: (context, index) {
              final avatar = AuthService.extraAvatars[index];
              final isSelected = avatar == _selectedAvatar;

              return GestureDetector(
                onTap: () {
                  AudioService.playClick();
                  setState(() => _selectedAvatar = avatar);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.elasticOut,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 75,
                  height: 75,
                  transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4776E6)
                          : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4776E6)
                                  .withValues(alpha: 0.7),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person,
                          color: Colors.white54, size: 30),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveAndProceed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _isSaving
            ? const Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'ابدأ اللعب!',
                    style: GoogleFonts.lalezar(
                      fontSize: 26,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
