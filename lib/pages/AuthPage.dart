import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alcione_scouting/auth.dart';
import 'package:alcione_scouting/pages/main_page.dart';

class Authpage extends StatefulWidget {
  const Authpage({super.key});

  @override
  State<Authpage> createState() => _AuthpageState();
}

class _AuthpageState extends State<Authpage> with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? errorMessage;
  bool loading = false;
  bool _passwordVisible = false;
  bool _isPressed = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color deepBlue = const Color(0xFF000814);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      HapticFeedback.vibrate();
      setState(() => errorMessage = "CREDENTIALS REQUIRED");
      return;
    }
    setState(() { loading = true; errorMessage = null; });
    try {
      await Auth().signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
      }
    } on FirebaseAuthException catch (_) {
      HapticFeedback.mediumImpact();
      setState(() => errorMessage = 'ACCESS DENIED. CHECK DATA.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: deepBlue,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orangeAlcione.withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: keyboardOpen ? 15 : 45),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: keyboardOpen ? 40 : 55,
                        width: keyboardOpen ? 40 : 55,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Icon(Icons.bolt_rounded, color: orangeAlcione, size: keyboardOpen ? 22 : 28),
                      ),
                      const SizedBox(height: 25),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "ALCIONE\n",
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: orangeAlcione,
                                  letterSpacing: 4),
                            ),
                            TextSpan(
                              text: "SCOUTING\nFORCE",
                              style: GoogleFonts.montserrat(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 0.9,
                                  letterSpacing: -1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildNikeInput(
                        controller: _email,
                        label: "ACCOUNT",
                        hint: "email@alcionemilano.it",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildNikeInput(
                        controller: _password,
                        label: "PASSWORD",
                        hint: "••••••••",
                        icon: Icons.lock_outline_rounded,
                        isPass: !_passwordVisible,
                        suffix: IconButton(
                          icon: Icon(
                              _passwordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: Colors.white38,
                              size: 18),
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),

                      // --- ZONA ERRORE OTTIMIZZATA (NON SPOSTA IL TASTO) ---
                      Container(
                        height: 40, // Spazio prenotato fisso
                        alignment: Alignment.centerLeft,
                        child: errorMessage == null
                            ? const SizedBox.shrink()
                            : FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.montserrat(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // TASTO LOGIN CON EFFETTO "SHRINK"
                      GestureDetector(
                        onTapDown: (_) {
                          HapticFeedback.lightImpact();
                          setState(() => _isPressed = true);
                        },
                        onTapUp: (_) => setState(() => _isPressed = false),
                        onTapCancel: () => setState(() => _isPressed = false),
                        onTap: loading ? null : _login,
                        child: AnimatedScale(
                          scale: _isPressed ? 0.96 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 65,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [orangeAlcione, const Color(0xFFFF8E4D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                    color: orangeAlcione.withOpacity(0.35),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8))
                              ],
                            ),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                "ACCEDI ALL'ARENA",
                                style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      if (!keyboardOpen)
                        Center(
                          child: Text(
                            "OFFICIAL SCOUTING SYSTEM v3.0",
                            style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white24,
                                letterSpacing: 1.5),
                          ),
                        ),
                      const SizedBox(height: 15),
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

  Widget _buildNikeInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPass = false,
    Widget? suffix
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label,
            style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPass,
            enableSuggestions: !isPass,
            autocorrect: !isPass,
            cursorColor: orangeAlcione,
            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 13),
              prefixIcon: Icon(icon, color: orangeAlcione.withOpacity(0.7), size: 18),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}