import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../settings/state/settings_notifier.dart';
import '../../settings/presentation/settings_screen.dart';
import 'routines_screen.dart';
import 'profile_onboarding_screen.dart';
import 'avatar_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  late TextEditingController _goalController;
  DateTime? _birthDate;

  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.userName);
    _heightController = TextEditingController(
      text: settings.userHeight == 0.0 ? '' : settings.userHeight.toStringAsFixed(1),
    );
    _weightController = TextEditingController(
      text: settings.userWeight == 0.0 ? '' : settings.userWeight.toStringAsFixed(1),
    );
    _ageController = TextEditingController(
      text: settings.userAge == 0 ? '' : settings.userAge.toString(),
    );
    _goalController = TextEditingController(
      text: settings.userGoal,
    );
    if (settings.userAge > 0) {
      _birthDate = DateTime(DateTime.now().year - settings.userAge, 1, 1);
    }
  }

  bool _onboardingShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_onboardingShown) {
      _onboardingShown = true;
      final settings = ref.read(settingsProvider);
      // Only auto-launch if the user has never completed or skipped setup
      if (!settings.profileSetupDone) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Wait for settings to load from SharedPreferences before deciding
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            final s = ref.read(settingsProvider);
            if (!s.profileSetupDone) {
              _openOnboarding();
            }
          });
        });
      }
    }
  }

  void _openOnboarding() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            const ProfileOnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  double _calculateBmi(double weight, double heightCm, String unit) {
    if (heightCm <= 0) return 0;
    double weightKg = weight;
    if (unit == 'lbs') {
      weightKg = weight * 0.45359237;
    }
    double heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  ({String label, Color color}) _getBmiCategory(double bmi) {
    if (bmi <= 0) return (label: 'Sin Datos', color: Colors.white30);
    if (bmi < 18.5) return (label: 'Bajo Peso', color: Colors.blueAccent);
    if (bmi < 25.0) return (label: 'Normal', color: AppTheme.electricCyan);
    if (bmi < 30.0) return (label: 'Sobrepeso', color: AppTheme.voltYellow);
    return (label: 'Obesidad', color: Colors.redAccent);
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 100);
    final DateTime lastDate = DateTime(now.year - 5);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.voltYellow,
              onPrimary: Colors.black,
              surface: AppTheme.midnightGrey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.darkCarbon,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _ageController.text = _calculateAge(picked).toString();
      });
    }
  }

  Future<void> _pickProfileImage() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un avatar desde las opciones de foto de perfil.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCarbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final settings = ref.watch(settingsProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library_rounded, color: AppTheme.voltYellow),
                      title: Text(
                        'Seleccionar de la galería',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickProfileImage();
                      },
                    ),
                    if (settings.profileImagePath.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                        title: Text(
                          'Eliminar foto de perfil',
                          style: GoogleFonts.spaceGrotesk(color: Colors.redAccent),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(settingsProvider.notifier).setProfileImagePath('');
                        },
                      ),
                    const Divider(color: AppTheme.dividerColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'O ELIGE UN AVATAR FITNESS:',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.voltYellow,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: builtInAvatars.entries.map((entry) {
                          final key = entry.key;
                          final avatar = entry.value;
                          final isSelected = settings.profileImagePath == key;
                          return GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await ref.read(settingsProvider.notifier).setProfileImagePath(isSelected ? '' : key);
                            },
                            child: Container(
                              width: 55,
                              height: 55,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: avatar.bg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.voltYellow : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  avatar.icon,
                                  color: avatar.color,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final double? height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final double? weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final int? age = int.tryParse(_ageController.text.trim());
    final goal = _goalController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMsg = 'Por favor ingresa tu nombre.');
      return;
    }
    if (height == null || weight == null) {
      setState(() => _errorMsg = 'Ingresa valores numéricos válidos para altura y peso.');
      return;
    }
    if (height <= 50 || height > 280) {
      setState(() => _errorMsg = 'Ingresa una altura válida entre 50 y 280 cm.');
      return;
    }
    if (weight <= 10 || weight > 500) {
      setState(() => _errorMsg = 'Ingresa un peso válido entre 10 y 500.');
      return;
    }
    if (_ageController.text.trim().isNotEmpty && (age == null || age < 1 || age > 120)) {
      setState(() => _errorMsg = 'Ingresa una edad válida entre 1 y 120 años.');
      return;
    }

    setState(() => _errorMsg = null);
    final notifier = ref.read(settingsProvider.notifier);
    notifier.setUserName(name);
    notifier.setUserHeight(height);
    notifier.setUserWeight(weight);
    notifier.setUserAge(age ?? 0);
    notifier.setUserGoal(goal);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Perfil actualizado con éxito!'),
        backgroundColor: AppTheme.voltYellow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to settingsProvider changes to populate controller fields when loaded or updated
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (_nameController.text.isEmpty && next.userName.isNotEmpty) {
        _nameController.text = next.userName;
      }
      if (_heightController.text.isEmpty && next.userHeight > 0) {
        _heightController.text = next.userHeight.toStringAsFixed(1);
      }
      if (_weightController.text.isEmpty && next.userWeight > 0) {
        _weightController.text = next.userWeight.toStringAsFixed(1);
      }
      if (_ageController.text.isEmpty && next.userAge > 0) {
        _ageController.text = next.userAge.toString();
        _birthDate = DateTime(DateTime.now().year - next.userAge, 1, 1);
      }
      if (_goalController.text.isEmpty && next.userGoal.isNotEmpty) {
        _goalController.text = next.userGoal;
      }
    });

    final settings = ref.watch(settingsProvider);
    final bmi = _calculateBmi(settings.userWeight, settings.userHeight, settings.weightUnit);
    final bmiCat = _getBmiCategory(bmi);
    final bool isUnconfigured = settings.userName.isEmpty || settings.userHeight == 0.0 || settings.userWeight == 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mi Perfil",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TARJETA DE RESUMEN IMC / ESTADO
            if (isUnconfigured)
              GestureDetector(
                onTap: _openOnboarding,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightGrey,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.voltYellow.withOpacity(0.4),
                        width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.voltYellow.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.voltYellow.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          size: 40,
                          color: AppTheme.voltYellow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Configura tu perfil!',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca aquí para completar tu perfil en menos de un minuto.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.voltYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Empezar',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkCarbon,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 18, color: AppTheme.darkCarbon),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.midnightGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    // Avatar + edit button
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showPhotoOptions,
                          child: buildAvatarWidget(
                            path: settings.profileImagePath,
                            radius: 36,
                            fallbackColor: bmiCat.color,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _openOnboarding,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppTheme.voltYellow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.darkCarbon, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  size: 13, color: AppTheme.darkCarbon),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      settings.userName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fila IMC
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ÍNDICE DE MASA CORPORAL",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white38,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  bmi.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: bmiCat.color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "kg/m²",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: bmiCat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: bmiCat.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            bmiCat.label.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: bmiCat.color,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tarjeta de Mis Rutinas
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoutinesScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.voltYellow.withOpacity(0.12),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: AppTheme.voltYellow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mis Rutinas de Entrenamiento",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Agrupa tus marcas y organiza tus rutinas",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // FORMULARIO DE EDICIÓN
              Text(
                "EDITAR DATOS DE PERFIL",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.midnightGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      'NOMBRE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Altura, Peso y Edad
                    Row(
                      children: [
                        // Altura
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALTURA',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _heightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  suffixText: 'cm',
                                  suffixStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Peso
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PESO',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  suffixText: settings.weightUnit,
                                  suffixStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.white54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Edad
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EDAD',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white38,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectBirthDate(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.dividerColor),
                                    color: Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _ageController.text.isNotEmpty
                                            ? _ageController.text
                                            : 'Seleccionar',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _ageController.text.isEmpty ? Colors.white38 : Colors.white,
                                        ),
                                      ),
                                      const Icon(Icons.cake_outlined, color: Colors.white38, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Objetivo Gym (Información complementaria)
                    Text(
                      'OBJETIVO DE GIMNASIO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _goalController,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ej. Ganar masa muscular, Perder grasa',
                        hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),

                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMsg!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Guardar Cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.voltYellow,
                          foregroundColor: AppTheme.darkCarbon,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
