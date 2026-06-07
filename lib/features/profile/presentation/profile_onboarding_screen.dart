import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/state/settings_notifier.dart';
import 'avatar_helper.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controladores
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Selecciones
  String? _selectedGoal; // 'muscle', 'fat_loss', 'strength', 'endurance', 'health'
  String _weightUnit = 'kg';
  DateTime? _birthDate;
  String _profileImagePath = '';

  // Animación
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    final settings = ref.read(settingsProvider);
    _weightUnit = settings.weightUnit;
    _profileImagePath = settings.profileImagePath;

    // Pre-fill existing data
    if (settings.userName.isNotEmpty) {
      _nameController.text = settings.userName;
    }
    if (settings.userAge > 0) {
      _ageController.text = settings.userAge.toString();
      _birthDate = DateTime(DateTime.now().year - settings.userAge, 1, 1);
    }
    if (settings.userHeight > 0) {
      _heightController.text = settings.userHeight.toStringAsFixed(1);
    }
    if (settings.userWeight > 0) {
      _weightController.text = settings.userWeight.toStringAsFixed(1);
    }

    // Map saved goal string back to key
    const goalMap = {
      'Ganar masa muscular': 'muscle',
      'Perder grasa': 'fat_loss',
      'Aumentar fuerza': 'strength',
      'Mejorar resistencia': 'endurance',
      'Salud general': 'health',
    };
    if (settings.userGoal.isNotEmpty) {
      _selectedGoal = goalMap[settings.userGoal];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    setState(() => _errorMsg = null);
    if (_currentStep < _totalSteps - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _errorMsg = null);
      _fadeController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          setState(() => _errorMsg = 'Por favor ingresa tu nombre.');
          return false;
        }
        return true;
      case 1:
        final age = int.tryParse(_ageController.text.trim());
        if (age == null || age < 10 || age > 100) {
          setState(() => _errorMsg = 'Ingresa una edad válida (10–100).');
          return false;
        }
        return true;
      case 2:
        final h = double.tryParse(_heightController.text.replaceAll(',', '.'));
        final w = double.tryParse(_weightController.text.replaceAll(',', '.'));
        if (h == null || h < 50 || h > 280) {
          setState(() => _errorMsg = 'Ingresa una altura válida (50–280 cm).');
          return false;
        }
        if (w == null || w < 10 || w > 500) {
          setState(() => _errorMsg = 'Ingresa un peso válido.');
          return false;
        }
        return true;
      case 3:
        if (_selectedGoal == null) {
          setState(() => _errorMsg = 'Selecciona tu objetivo.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _finish() {
    final notifier = ref.read(settingsProvider.notifier);
    notifier.setUserName(_nameController.text.trim());
    notifier.setProfileImagePath(_profileImagePath);
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    notifier.setUserAge(age);
    final h = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0;
    notifier.setUserHeight(h);
    final w = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    notifier.setUserWeight(w);
    notifier.setWeightUnit(_weightUnit);

    final goalLabels = {
      'muscle': 'Ganar masa muscular',
      'fat_loss': 'Perder grasa',
      'strength': 'Aumentar fuerza',
      'endurance': 'Mejorar resistencia',
      'health': 'Salud general',
    };
    notifier.setUserGoal(goalLabels[_selectedGoal] ?? '');
    notifier.setProfileSetupDone(true);

    Navigator.of(context).pop();
  }

  // ────────────────────────────────────────────────
  //  PASOS
  // ────────────────────────────────────────────────

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _profileImagePath = result.files.single.path!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el selector del sistema. Selecciona un avatar.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _stepName() {
    return _StepWrapper(
      icon: Icons.person_outline_rounded,
      title: '¿Cómo te llamas?',
      subtitle: 'Tu nombre personaliza toda la experiencia.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            hint: 'Tu nombre o apodo',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          Text(
            'FOTO DE PERFIL (OPCIONAL)',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.voltYellow,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Botón subir propia imagen
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightGrey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _profileImagePath.isNotEmpty && !_profileImagePath.startsWith('avatar:')
                            ? AppTheme.voltYellow
                            : AppTheme.dividerColor,
                        width: _profileImagePath.isNotEmpty && !_profileImagePath.startsWith('avatar:') ? 2.0 : 1.0,
                      ),
                    ),
                    child: ClipOval(
                      child: _profileImagePath.isNotEmpty && !_profileImagePath.startsWith('avatar:')
                          ? buildAvatarWidget(path: _profileImagePath, radius: 28, fallbackColor: Colors.white24)
                          : const Icon(Icons.add_a_photo_rounded, color: Colors.white54, size: 20),
                    ),
                  ),
                ),
                // Avatars predeterminados
                ...builtInAvatars.entries.map((entry) {
                  final key = entry.key;
                  final avatar = entry.value;
                  final isSelected = _profileImagePath == key;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profileImagePath = isSelected ? '' : key;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
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
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _stepAge() {
    final String ageText = _birthDate == null
        ? 'Seleccionar'
        : '${_calculateAge(_birthDate!)}';

    return _StepWrapper(
      icon: Icons.cake_outlined,
      title: '¿Cuántos años tienes?',
      subtitle: 'La edad influye en el cálculo de tu 1RM y métricas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _selectBirthDate(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _birthDate != null ? AppTheme.voltYellow : AppTheme.dividerColor,
                  width: _birthDate != null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ageText,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _birthDate == null ? Colors.white24 : Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.cake_outlined, color: AppTheme.voltYellow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() {
    return _StepWrapper(
      icon: Icons.straighten_rounded,
      title: 'Tu altura y peso',
      subtitle: 'Necesitamos estos datos para calcular tu IMC.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unidad de peso
          Row(
            children: [
              Text(
                'UNIDAD DE PESO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _UnitToggle(
                value: _weightUnit,
                onChanged: (v) => setState(() => _weightUnit = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _heightController,
            hint: 'Ej. 175',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: 'cm',
            label: 'ALTURA',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _weightController,
            hint: _weightUnit == 'kg' ? 'Ej. 75' : 'Ej. 165',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: _weightUnit,
            label: 'PESO',
          ),
        ],
      ),
    );
  }

  Widget _stepGoal() {
    final goals = [
      ('muscle', Icons.fitness_center_rounded, 'Ganar masa muscular',
          'Hipertrofia y volumen'),
      ('fat_loss', Icons.local_fire_department_rounded, 'Perder grasa',
          'Definición y quema de calorías'),
      ('strength', Icons.bolt_rounded, 'Aumentar fuerza',
          'Fuerza máxima y potencia'),
      ('endurance', Icons.directions_run_rounded, 'Mejorar resistencia',
          'Cardio y resistencia muscular'),
      ('health', Icons.favorite_rounded, 'Salud general',
          'Bienestar y estilo de vida activo'),
    ];

    return _StepWrapper(
      icon: Icons.track_changes_rounded,
      title: '¿Cuál es tu objetivo?',
      subtitle: 'Esto personaliza tus recomendaciones.',
      child: Column(
        children: goals.map((g) {
          final (key, icon, label, sub) = g;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectCard(
              icon: icon,
              label: label,
              subtitle: sub,
              isSelected: _selectedGoal == key,
              onTap: () => setState(() => _selectedGoal = key),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ────────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final steps = [
      _stepName(),
      _stepAge(),
      _stepBody(),
      _stepGoal(),
    ];

    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      backgroundColor: AppTheme.darkCarbon,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        GestureDetector(
                          onTap: _prevStep,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.midnightGrey,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: Colors.white70),
                          ),
                        )
                      else
                        const SizedBox(width: 36),
                      Text(
                        '${_currentStep + 1} / $_totalSteps',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(settingsProvider.notifier).setProfileSetupDone(true);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Omitir',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white30,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: AppTheme.midnightGrey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.voltYellow),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _currentStep = idx);
                  _fadeController.reset();
                  _fadeController.forward();
                },
                children: steps,
              ),
            ),

            // ── Error message ──
            if (_errorMsg != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── CTA Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.voltYellow,
                    foregroundColor: AppTheme.darkCarbon,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep ? '¡Empezar!' : 'Continuar',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastStep
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers ──

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
    String? label,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.voltYellow,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          cursorColor: AppTheme.voltYellow,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 22,
              color: Colors.white24,
              fontWeight: FontWeight.bold,
            ),
            suffixText: suffix,
            suffixStyle: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 14,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: AppTheme.midnightGrey,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.voltYellow, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────
//  Sub-widgets
// ────────────────────────────────────────────────

class _StepWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.voltYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.voltYellow.withOpacity(0.3)),
            ),
            child: Icon(icon, size: 32, color: AppTheme.voltYellow),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.voltYellow.withOpacity(0.08)
              : AppTheme.midnightGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.voltYellow : AppTheme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.voltYellow.withOpacity(0.15)
                    : AppTheme.darkCarbon,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.voltYellow : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: isSelected
                            ? AppTheme.voltYellow.withOpacity(0.8)
                            : Colors.white38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.voltYellow, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _UnitToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: ['kg', 'lbs'].map((unit) {
          final isSelected = value == unit;
          return GestureDetector(
            onTap: () => onChanged(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.voltYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                unit,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.darkCarbon : Colors.white54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
