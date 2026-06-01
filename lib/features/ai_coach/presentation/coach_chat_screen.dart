import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../state/coach_notifier.dart';

class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

    // Escucha cambios en el tamaño de la lista de mensajes para desplazarse hacia abajo
    ref.listen<CoachState>(coachProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.isThinking) {
        _scrollToBottom();
      }
    });

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
                    color: coachState.isModelInstalled ? AppTheme.electricCyan : Colors.white30,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  coachState.isModelInstalled 
                      ? context.tr('ai_status_active', ref) 
                      : context.tr('ai_status_inactive', ref),
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (coachState.isModelInstalled)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white60),
              tooltip: "Reiniciar Chat",
              onPressed: () {
                coachNotifier.clearChat();
              },
            ),
        ],
      ),
      body: coachState.isModelInstalled
          ? _buildChatInterface(context, coachState, coachNotifier)
          : _buildDownloadInterface(context, coachState, coachNotifier),
    );
  }

  // VISTA 1: Interfaz del Chat (Una vez instalada la IA)
  Widget _buildChatInterface(BuildContext context, CoachState state, CoachNotifier notifier) {
    return Column(
      children: [
        // SELECTOR DE ENTRENADORES PREMIUM
        _buildCoachSelector(state, notifier),

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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: context.tr('ai_chat_hint', ref),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.darkCarbon,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (val) => _handleSendMessage(val, notifier),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.electricCyan,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.darkCarbon),
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

  // Selector horizontal de entrenadores premium
  Widget _buildCoachSelector(CoachState state, CoachNotifier notifier) {
    final List<Map<String, dynamic>> coaches = [
      {
        'id': 'cristian',
        'name': 'Cristian',
        'specialty': 'Hipertrofia 💪',
        'color': AppTheme.voltYellow,
        'icon': Icons.fitness_center,
      },
      {
        'id': 'ana',
        'name': 'Ana',
        'specialty': 'Definición 🍎',
        'color': Colors.orangeAccent,
        'icon': Icons.restaurant_menu,
      },
      {
        'id': 'igor',
        'name': 'Igor',
        'specialty': 'Fuerza ⚡',
        'color': AppTheme.electricCyan,
        'icon': Icons.bolt,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(
        color: AppTheme.midnightGrey,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: coaches.map((coach) {
          final isSelected = state.selectedCoach == coach['id'];
          final Color coachColor = coach['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                notifier.selectCoach(coach['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? coachColor.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? coachColor : AppTheme.dividerColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected ? coachColor : AppTheme.darkCarbon,
                      child: Icon(
                        coach['icon'] as IconData,
                        size: 13,
                        color: isSelected ? AppTheme.darkCarbon : coachColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            coach['name'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white60,
                            ),
                          ),
                          Text(
                            coach['specialty'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              color: isSelected ? coachColor : Colors.white30,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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

  // VISTA 2: Interfaz de Descarga Inicial (Presentación Premium del Equipo)
  Widget _buildDownloadInterface(BuildContext context, CoachState state, CoachNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono destacado con pulso neón
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.midnightGrey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: const Icon(
                  Icons.bolt_outlined,
                  size: 54,
                  color: AppTheme.electricCyan,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              context.tr('ai_title', ref),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('ai_model_desc', ref),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),

            // PRESENTACIÓN DE LOS 3 ENTRENADORES
            _buildCoachIntroCard(
              name: "Cristian",
              specialty: context.tr('coach_cristian_specialty', ref),
              desc: context.tr('coach_cristian_desc', ref),
              color: AppTheme.voltYellow,
              icon: Icons.fitness_center,
            ),
            const SizedBox(height: 10),
            _buildCoachIntroCard(
              name: "Ana",
              specialty: context.tr('coach_ana_specialty', ref),
              desc: context.tr('coach_ana_desc', ref),
              color: Colors.orangeAccent,
              icon: Icons.restaurant_menu,
            ),
            const SizedBox(height: 10),
            _buildCoachIntroCard(
              name: "Igor",
              specialty: context.tr('coach_igor_specialty', ref),
              desc: context.tr('coach_igor_desc', ref),
              color: AppTheme.electricCyan,
              icon: Icons.bolt,
            ),
            const SizedBox(height: 28),

            // SECCIÓN DE DESCARGA O PROGRESO
            state.isDownloading
                ? Column(
                    children: [
                      Text(
                        "${context.tr('ai_downloading', ref)} ${state.downloadProgress}%",
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.voltYellow,
                          fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 8),
                      Text(
                        context.tr('ai_download_warning', ref),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.white30),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      notifier.downloadModel();
                    },
                    icon: const Icon(Icons.download_for_offline, color: AppTheme.darkCarbon),
                    label: Text(context.tr('ai_download_btn', ref)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: AppTheme.darkCarbon,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Tarjeta premium de presentación individual para cada entrenador
  Widget _buildCoachIntroCard({
    required String name,
    required String specialty,
    required String desc,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      specialty,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
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
    );
  }
}

// Helper para colores y fuentes personalizados
extension TextColorExtension on Colors {
  static const Color whitee8 = Color(0xffe8e8e8);
}
