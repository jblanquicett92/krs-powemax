import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../state/coach_notifier.dart';
import '../../settings/state/settings_notifier.dart';
import '../../history/state/history_notifier.dart';

class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Variables locales de control para el cuestionario de Onboarding
  int _onboardingStep = 0;
  String? _selectedObjective; // 'hipertrofia', 'definicion', 'fuerza'
  String? _selectedExperience; // 'Principiante', 'Intermedio', 'Avanzado'
  String? _selectedFrequency; // '1-2 días', '3-4 días', '5+ días'

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(coachProvider);
    final coachNotifier = ref.read(coachProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isOnline = settings.aiMode == 'online';

    // Escucha cambios en el tamaño de la lista de mensajes para desplazarse hacia abajo
    ref.listen<CoachState>(coachProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.isThinking) {
        _scrollToBottom();
      }
    });

    // Formatear el nombre del coach para la barra superior
    String statusSubtitle = "";
    Color dotColor = Colors.white30;
    if (isOnline || coachState.isModelInstalled) {
      if (coachState.isOnboarded) {
        final name = coachState.selectedCoach;
        final coachName = "${name[0].toUpperCase()}${name.substring(1)}";
        if (isOnline) {
          statusSubtitle = "$coachName (Online)";
          dotColor = AppTheme.electricCyan;
        } else if (coachState.isUsingLocalAI) {
          statusSubtitle = "$coachName (Offline)";
          dotColor = AppTheme.electricCyan;
        } else {
          statusSubtitle = "$coachName (Offline)";
          dotColor = Colors.orangeAccent;
        }
      } else {
        statusSubtitle = "Configurando...";
        dotColor = AppTheme.voltYellow;
      }
    } else {
      statusSubtitle = context.tr('ai_status_inactive', ref);
      dotColor = Colors.white30;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ai_title', ref),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusSubtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isOnline || coachState.isModelInstalled) ...[
            if (coachState.isOnboarded)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white60),
                tooltip: "Reiniciar Chat",
                onPressed: () {
                  coachNotifier.clearChat();
                },
              ),
            if (coachState.isOnboarded)
              IconButton(
                icon: const Icon(Icons.psychology_outlined, color: Colors.white60),
                tooltip: "Re-evaluar Objetivo",
                onPressed: () {
                  _showResetOnboardingDialog(context, coachNotifier);
                },
              ),
          ],
        ],
      ),
      body: (!isOnline && !coachState.isModelInstalled)
          ? _buildDownloadInterface(context, coachState, coachNotifier)
          : (!coachState.isOnboarded
              ? _buildOnboardingInterface(context, coachState, coachNotifier)
              : _buildChatInterface(context, coachState, coachNotifier)),
    );
  }

  // VISTA 1: Interfaz del Chat (Una vez instalada la IA y asignado el coach)
  Widget _buildChatInterface(BuildContext context, CoachState state, CoachNotifier notifier) {
    final records = ref.watch(historyProvider);
    // Obtener lista única de ejercicios para los chips de conversación
    final List<String> exercises = records.map((r) => r.exerciseName).toSet().toList();

    return Column(
      children: [
        // FILTRO DE CONVERSACIONES (Chips horizontales)
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 1 + exercises.length,
            itemBuilder: (context, index) {
              final String topic = index == 0 ? 'General' : exercises[index - 1];
              final bool isSelected = topic == state.activeExercise;
              
              Color accentColor = AppTheme.electricCyan;
              if (state.selectedCoach == 'cristian') {
                accentColor = AppTheme.voltYellow;
              } else if (state.selectedCoach == 'ana') {
                accentColor = Colors.orangeAccent;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      notifier.selectExercise(topic);
                    }
                  },
                  selectedColor: accentColor.withOpacity(0.15),
                  backgroundColor: AppTheme.midnightGrey,
                  labelStyle: TextStyle(
                    color: isSelected ? accentColor : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? accentColor 
                          : AppTheme.dividerColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // HISTORIAL DE MENSAJES
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final msg = state.messages[index];
              return _buildMessageBubble(msg, state.selectedCoach);
            },
          ),
        ),

        // INDICADOR DE PENSANDO
        if (state.isThinking)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricCyan),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('ai_thinking', ref),
                  style: const TextStyle(fontSize: 12, color: AppTheme.electricCyan, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

        // BARRA DE INPUT AL PIE
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppTheme.midnightGrey,
            border: Border(
              top: BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: context.tr('ai_chat_hint', ref),
                      hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 14),
                      fillColor: AppTheme.darkCarbon,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _handleSendMessage(val, notifier),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.voltYellow,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.darkCarbon, size: 18),
                    onPressed: () => _handleSendMessage(_messageController.text, notifier),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Burbuja de chat premium con acoplamiento dinámico de color según el entrenador
  Widget _buildMessageBubble(ChatMessage msg, String selectedCoach) {
    Color coachColor = AppTheme.electricCyan;
    if (selectedCoach == 'cristian') {
      coachColor = AppTheme.voltYellow;
    } else if (selectedCoach == 'ana') {
      coachColor = Colors.orangeAccent;
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.voltYellow.withOpacity(0.08) : AppTheme.darkCarbon,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser 
                ? AppTheme.voltYellow.withOpacity(0.3) 
                : coachColor.withOpacity(0.3), // Borde acoplado dinámicamente al color del coach
          ),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.5,
            height: 1.4,
            color: msg.isUser ? AppTheme.voltYellow : const Color(0xffe8e8e8),
          ),
        ),
      ),
    );
  }

  void _handleSendMessage(String text, CoachNotifier notifier) {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    notifier.sendMessage(text);
  }

  void _showForceDownloadWarning(BuildContext context, CoachNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "¿Descargar de todos modos?",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Tu dispositivo cuenta con menos memoria RAM de la recomendada (4.0 GB). Esto podría causar lentitud extrema, que la app se cierre sola o que el teléfono se caliente. ¿Deseas continuar bajo tu propio riesgo?",
            style: GoogleFonts.spaceGrotesk(fontSize: 14, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancelar",
                style: GoogleFonts.spaceGrotesk(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.downloadModel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                "Descargar",
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // VISTA 2: Interfaz de Descarga Inicial (Presentación Premium del Equipo)
  Widget _buildDownloadInterface(BuildContext context, CoachState state, CoachNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono destacado con pulso neón
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.midnightGrey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricCyan.withOpacity(0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 64,
                  color: AppTheme.electricCyan,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              context.tr('ai_title', ref),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('ai_model_desc', ref),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),

            // Tarjeta de Requisitos del Sistema
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Requisitos del Sistema:",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // RAM Row
                  Row(
                    children: [
                      Icon(
                        state.isDeviceCompatible
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: state.isDeviceCompatible
                            ? AppTheme.electricCyan
                            : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Memoria RAM: Mínimo 4.0 GB (Tu dispositivo: ${state.deviceRamMb > 0 ? '${(state.deviceRamMb / 1024).toStringAsFixed(1)} GB' : 'Desconocido'})",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: state.isDeviceCompatible
                                ? Colors.white60
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Storage Row
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.electricCyan,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Almacenamiento: ~1.6 GB de espacio libre",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Compatibilidad general
                  Row(
                    children: [
                      Icon(
                        state.isDeviceCompatible
                            ? Icons.verified_user_outlined
                            : Icons.gpp_maybe_outlined,
                        color: state.isDeviceCompatible
                            ? AppTheme.electricCyan
                            : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Compatibilidad: ${state.isDeviceCompatible ? 'Tu dispositivo es compatible' : 'Tu dispositivo no es recomendado'}",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: state.isDeviceCompatible
                                ? AppTheme.electricCyan
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SECCIÓN DE DESCARGA O PROGRESO
            !state.isDeviceCompatible
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Dispositivo No Recomendado",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tu teléfono cuenta con ${state.deviceRamMb > 0 ? '${(state.deviceRamMb / 1024).toStringAsFixed(1)} GB' : 'poca'} de memoria RAM. Se requieren mínimo 4.0 GB de RAM para ejecutar la IA local sin comprometer el rendimiento del sistema.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13.5,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showForceDownloadWarning(context, notifier);
                          },
                          icon: const Icon(Icons.warning, color: Colors.white, size: 18),
                          label: Text(
                            "Descargar de todos modos",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : (state.isDownloading
                    ? Column(
                        children: [
                          Text(
                            "${context.tr('ai_downloading', ref)} ${state.downloadProgress}%",
                            style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.voltYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: state.downloadProgress / 100.0,
                              minHeight: 12,
                              backgroundColor: AppTheme.midnightGrey,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.voltYellow),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('ai_download_warning', ref),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white30),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          notifier.downloadModel();
                        },
                        icon: const Icon(Icons.download_for_offline, color: AppTheme.darkCarbon, size: 22),
                        label: Text(
                          context.tr('ai_download_btn', ref),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCyan,
                          foregroundColor: AppTheme.darkCarbon,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ref.read(settingsProvider.notifier).setAiMode('online');
                },
                icon: const Icon(Icons.cloud_outlined, color: AppTheme.electricCyan, size: 20),
                label: Text(
                  "Usar IA Online (Gratis, sin descargas)",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: AppTheme.electricCyan,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // VISTA 3: Cuestionario de Onboarding para autodetectar el coach ideal
  Widget _buildOnboardingInterface(BuildContext context, CoachState state, CoachNotifier notifier) {
    if (_onboardingStep == 0) {
      return _buildOnboardingWelcomeScreen(context, state, notifier);
    }
    if (_onboardingStep == 4) {
      return _buildCoachProposalScreen(context, state, notifier);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de pasos visual premium (para pasos 1, 2 y 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final int currentQuestionIndex = _onboardingStep - 1;
                final bool isActive = index == currentQuestionIndex;
                final bool isCompleted = index < currentQuestionIndex;
                return Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive 
                            ? AppTheme.voltYellow 
                            : (isCompleted ? AppTheme.electricCyan : AppTheme.midnightGrey),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive 
                              ? AppTheme.voltYellow 
                              : (isCompleted ? AppTheme.electricCyan : AppTheme.dividerColor),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (index + 1).toString(),
                          style: GoogleFonts.spaceGrotesk(
                            color: isActive ? AppTheme.darkCarbon : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (index < 2)
                      Container(
                        width: 32,
                        height: 2,
                        color: isCompleted ? AppTheme.electricCyan : AppTheme.dividerColor,
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 32),

            if (_onboardingStep == 1) ...[
              Text(
                "¿Cuál es tu objetivo de entrenamiento principal?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Esto determinará al experto de fuerza ideal para ti.",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildOptionCard(
                title: "Hipertrofia Muscular",
                subtitle: "Ganar la máxima masa muscular, bombeo y series de alto volumen.",
                icon: Icons.fitness_center,
                isSelected: _selectedObjective == 'hipertrofia',
                onTap: () {
                  setState(() {
                    _selectedObjective = 'hipertrofia';
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: "Definición y Nutrición",
                subtitle: "Reducir porcentaje de grasa corporal sin perder masa muscular.",
                icon: Icons.restaurant_menu,
                isSelected: _selectedObjective == 'definicion',
                onTap: () {
                  setState(() {
                    _selectedObjective = 'definicion';
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: "Fuerza Máxima y Potencia",
                subtitle: "Elevar tus marcas de 1RM, bajas reps y descansos completos.",
                icon: Icons.bolt,
                isSelected: _selectedObjective == 'fuerza',
                onTap: () {
                  setState(() {
                    _selectedObjective = 'fuerza';
                  });
                },
              ),
            ] else if (_onboardingStep == 2) ...[
              Text(
                "¿Cuál es tu nivel de experiencia levantando?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Adaptaremos las intensidades y RPE sugeridos por tu coach.",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildOptionCard(
                title: "Principiante (Menos de 1 año)",
                subtitle: "Enfoque en dominar la técnica de los levantamientos básicos.",
                icon: Icons.fitness_center_outlined,
                isSelected: _selectedExperience == 'Principiante',
                onTap: () {
                  setState(() {
                    _selectedExperience = 'Principiante';
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: "Intermedio (1 a 3 años)",
                subtitle: "Entreno de forma constante y busco superar estancamientos.",
                icon: Icons.trending_up,
                isSelected: _selectedExperience == 'Intermedio',
                onTap: () {
                  setState(() {
                    _selectedExperience = 'Intermedio';
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: "Avanzado (Más de 3 años)",
                subtitle: "Familiarizado con la fatiga del sistema nervioso y cargas pico.",
                icon: Icons.workspace_premium_outlined,
                isSelected: _selectedExperience == 'Avanzado',
                onTap: () {
                  setState(() {
                    _selectedExperience = 'Avanzado';
                  });
                },
              ),
            ] else ...[
              Text(
                "¿Con qué frecuencia entrenas por semana?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Ajustará las rutinas y pautas metabólicas diarias.",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildOptionCard(
                title: "1 - 2 días por semana",
                subtitle: "Entrenamiento general enfocado en salud y movilidad.",
                icon: Icons.calendar_today_outlined,
                isSelected: _selectedFrequency == '1-2 días',
                onTap: () {
                  setState(() {
                    _selectedFrequency = '1-2 días';
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: "3 - 4 días por semana",
                subtitle: "Frecuencia ideal para progresión constante de cargas.",
                icon: Icons.date_range_outlined,
                isSelected: _selectedFrequency == '3-4 días',
                onTap: () {
                  setState(() {
                    _selectedFrequency = '3-4 días';
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: "5 o más días por semana",
                subtitle: "Dedicación avanzada con divisiones y cargas exigentes.",
                icon: Icons.calendar_month_outlined,
                isSelected: _selectedFrequency == '5+ días',
                onTap: () {
                  setState(() {
                    _selectedFrequency = '5+ días';
                  });
                },
              ),
            ],
            const SizedBox(height: 32),

            // Botones de navegación del Wizard
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _onboardingStep--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Atrás",
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isNextButtonEnabled()
                        ? () {
                            setState(() {
                              _onboardingStep++;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.voltYellow,
                      foregroundColor: AppTheme.darkCarbon,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppTheme.midnightGrey,
                      disabledForegroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _onboardingStep == 3 ? "Ver mi Coach" : "Siguiente",
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Pantalla de Bienvenida / Explicación del Test de Onboarding
  Widget _buildOnboardingWelcomeScreen(BuildContext context, CoachState state, CoachNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono de activación exitosa
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.midnightGrey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricCyan.withOpacity(0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: const Icon(
                  Icons.lock_open_outlined,
                  size: 64,
                  color: AppTheme.electricCyan,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              "¡Entrenadores Desbloqueados!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "El motor de inteligencia y los perfiles de tu equipo de asesores deportivos se han instalado correctamente y de forma 100% local en tu dispositivo.",
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.voltYellow, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Para asignarte el entrenador ideal según tus necesidades, realizaremos un test rápido de 3 preguntas.",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _onboardingStep = 1; // Inicia el test
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.voltYellow,
                foregroundColor: AppTheme.darkCarbon,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Comenzar Configuración",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta premium interactiva de selección de opciones
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.voltYellow.withOpacity(0.08) : AppTheme.midnightGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.voltYellow : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? AppTheme.voltYellow : Colors.white60,
                size: 22,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.voltYellow : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
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

  // Pantalla de asignación y presentación formal del Coach propuesto
  Widget _buildCoachProposalScreen(BuildContext context, CoachState state, CoachNotifier notifier) {
    String coachName = "";
    String coachSpecialty = "";
    String coachDesc = "";
    Color coachColor = Colors.white;
    IconData coachIcon = Icons.bolt;

    if (_selectedObjective == 'hipertrofia') {
      coachName = "Cristian";
      coachSpecialty = "Hipertrofia Muscular";
      coachDesc = "¡Hola, crack! De acuerdo con tu meta de Hipertrofia Muscular y tu nivel $_selectedExperience, estructuraremos entrenamientos intensivos de $_selectedFrequency a la semana enfocado en tiempo bajo tensión, RPE 8-10 y series gigantes para maximizar tu ganancia de masa muscular.";
      coachColor = AppTheme.voltYellow;
      coachIcon = Icons.fitness_center;
    } else if (_selectedObjective == 'definicion') {
      coachName = "Ana";
      coachSpecialty = "Definición y Nutrición";
      coachDesc = "¡Hola! De acuerdo con tu meta de Definición y tu nivel $_selectedExperience, estructuraremos entrenamientos metabólicos de $_selectedFrequency a la semana enfocados en déficit calórico inteligente, cardio de alta intensidad y nutrición idónea para conservar tu músculo mientras quemas grasa.";
      coachColor = Colors.orangeAccent;
      coachIcon = Icons.restaurant_menu;
    } else {
      coachName = "Igor";
      coachSpecialty = "Fuerza Máxima y Potencia";
      coachDesc = "Saludos. De acuerdo con tu meta de Fuerza Máxima y tu nivel $_selectedExperience, estructuraremos entrenamientos de $_selectedFrequency a la semana enfocados en descansos completos de 3-5 minutos, bajas repeticiones (1-5 reps) y progresión de cargas para llevar tu 1RM al límite.";
      coachColor = AppTheme.electricCyan;
      coachIcon = Icons.bolt;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "¡Tu Coach Ideal Asignado!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Tarjeta animada del Coach asignado
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: coachColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: coachColor.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: coachColor.withOpacity(0.1),
                    child: Icon(coachIcon, color: coachColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    coachName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: coachColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coachSpecialty,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: coachColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    coachDesc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                notifier.completeOnboarding(
                  objective: _selectedObjective!,
                  experienceLevel: _selectedExperience!,
                  trainingFrequency: _selectedFrequency!,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: coachColor,
                foregroundColor: AppTheme.darkCarbon,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Comenzar Asesoramiento",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _onboardingStep = 1; // Volver a la primera pregunta
                  _selectedObjective = null;
                  _selectedExperience = null;
                  _selectedFrequency = null;
                });
              },
              child: Text(
                "Volver a responder test",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Diálogo para re-evaluar objetivo y cambiar de entrenador
  void _showResetOnboardingDialog(BuildContext context, CoachNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "¿Re-evaluar Objetivo?",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Al cambiar de objetivo deportivo, se asignará un nuevo coach y se reiniciará el historial de chat actual para que tu asesoría sea consistente con tu nueva meta. ¿Deseas continuar?",
            style: GoogleFonts.spaceGrotesk(fontSize: 14, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancelar",
                style: GoogleFonts.spaceGrotesk(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _onboardingStep = 0;
                  _selectedObjective = null;
                  _selectedExperience = null;
                  _selectedFrequency = null;
                });
                notifier.resetOnboarding();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.voltYellow,
                foregroundColor: AppTheme.darkCarbon,
              ),
              child: Text(
                "Confirmar",
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }



  bool _isNextButtonEnabled() {
    if (_onboardingStep == 1) return _selectedObjective != null;
    if (_onboardingStep == 2) return _selectedExperience != null;
    if (_onboardingStep == 3) return _selectedFrequency != null;
    return true;
  }
}

// Helper para colores y fuentes personalizados
extension TextColorExtension on Colors {
  static const Color whitee8 = Color(0xffe8e8e8);
}
