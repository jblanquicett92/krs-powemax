import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Proveedor del idioma actual (por defecto español 'es')
final localeProvider = StateProvider<String>((ref) => 'es');

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'PowerMax 1RM',
      'nav_calculator': 'Calculator',
      'nav_history': 'History',
      'nav_ai_coach': 'Coaches',
      'nav_settings': 'Settings',
      
      // Calculator Screen
      'calc_weight': 'Weight Lifted',
      'calc_reps': 'Repetitions',
      'calc_formula': 'Formula',
      'calc_result_title': 'Estimated 1RM',
      'calc_save_btn': 'Save Record',
      'calc_exercise_label': 'Exercise Name',
      'calc_exercise_hint': 'e.g. Bench Press, Squat',
      'calc_success_save': 'Record saved successfully!',
      'calc_error_empty': 'Please fill all fields',
      
      // Zones
      'zone_warmup': 'Warm-up / Endurance',
      'zone_hypertrophy': 'Muscle Hypertrophy',
      'zone_strength': 'Maximal Strength',
      'zone_power': 'Explosive Power',
      
      // History Screen
      'history_title': 'Brand History',
      'history_empty': 'No records registered yet. Start lifting!',
      'history_chart_title': 'Strength Evolution (1RM)',
      
      // AI Coach
      'ai_title': 'My Coach',
      'ai_subtitle': '100% offline & private trainers',
      'ai_chat_hint': 'Ask about sets, routines, or exercises...',
      'ai_model_not_installed': 'Trainers are not active yet.',
      'ai_model_desc': 'Unlock the knowledge profiles of your coaching team to receive tailored advice on routines, hypertrophy, and strength progression, 100% offline and private.',
      'ai_download_btn': 'Unlock Offline Coaches (~1.6GB)',
      'ai_downloading': 'Loading Coaches...',
      'ai_ready': 'Coaches are ready to help!',
      'ai_welcome_msg': 'Hello! I am your coach. I have analyzed your calculated 1RM. How can I help you optimize your training today?',
      'ai_thinking': 'Thinking...',
      'ai_status_active': 'Coaches Active (Offline)',
      'ai_status_inactive': 'Coaches Inactive',
      'ai_download_warning': 'Do not close the app. It will be saved permanently and 100% offline.',
      'coach_cristian_specialty': 'Muscle Hypertrophy',
      'coach_cristian_desc': 'Giant sets, tempos, and RPE 8-10 to gain maximum muscle mass and pump.',
      'coach_ana_specialty': 'Definition & Nutrition',
      'coach_ana_desc': 'Metabolic cardio, smart caloric deficit, and supplementation to lean out.',
      'coach_igor_specialty': 'Maximal Strength & Power',
      'coach_igor_desc': 'Heavy lifting 1RM progression at low reps and complete rest.',
      
      // Settings Screen
      'settings_title': 'Configuration',
      'settings_language': 'Language',
      'settings_units': 'Weight Unit',
      'settings_default_formula': 'Default Formula',
      'settings_about': 'About PowerMax',
      'settings_about_desc': 'PowerMax 1RM is a premium tool designed for powerlifters and strength enthusiasts. Features fully offline on-device integration with your team of personalized coaches.',
    },
    'es': {
      'app_title': 'PowerMax 1RM',
      'nav_calculator': 'Calculadora',
      'nav_history': 'Historial',
      'nav_ai_coach': 'Coaches',
      'nav_settings': 'Ajustes',
      
      // Calculator Screen
      'calc_weight': 'Peso Levantado',
      'calc_reps': 'Repeticiones',
      'calc_formula': 'Fórmula',
      'calc_result_title': '1RM Estimado',
      'calc_save_btn': 'Guardar Marca',
      'calc_exercise_label': 'Nombre del Ejercicio',
      'calc_exercise_hint': 'Ej. Press de Banca, Sentadilla',
      'calc_success_save': '¡Marca guardada correctamente!',
      'calc_error_empty': 'Por favor, llena todos los campos',
      
      // Zones
      'zone_warmup': 'Calentamiento / Resistencia',
      'zone_hypertrophy': 'Hipertrofia Muscular',
      'zone_strength': 'Fuerza Máxima',
      'zone_power': 'Potencia Explosiva',
      
      // History Screen
      'history_title': 'Historial de Marcas',
      'history_empty': 'Sin marcas registradas aún. ¡A entrenar!',
      'history_chart_title': 'Evolución de Fuerza (1RM)',
      
      // AI Coach
      'ai_title': 'Mi Coach',
      'ai_subtitle': 'Entrenadores 100% offline y privados',
      'ai_chat_hint': 'Pregunta sobre series, rutinas o ejercicios...',
      'ai_model_not_installed': 'Los entrenadores no están activos.',
      'ai_model_desc': 'Desbloquea el perfil de conocimiento de tus entrenadores para recibir asesoramiento a la medida sobre rutinas, hipertrofia y fuerza, 100% offline y de forma privada.',
      'ai_download_btn': 'Desbloquear Entrenadores Offline (~1.6GB)',
      'ai_downloading': 'Cargando Entrenadores...',
      'ai_ready': '¡Tus entrenadores están listos para ayudarte!',
      'ai_welcome_msg': '¡Hola! Soy tu entrenador. He analizado tus cálculos de 1RM. ¿Cómo puedo ayudarte a optimizar tu entrenamiento hoy?',
      'ai_thinking': 'Pensando...',
      'ai_status_active': 'Coaches Activos (Offline)',
      'ai_status_inactive': 'Coaches Desactivados',
      'ai_download_warning': 'No cierres la app. Se guardará de forma permanente y 100% offline.',
      'coach_cristian_specialty': 'Hipertrofia Muscular',
      'coach_cristian_desc': 'Series gigantes, tempos y RPE 8-10 para ganar la máxima masa muscular y bombeo.',
      'coach_ana_specialty': 'Definición y Nutrición',
      'coach_ana_desc': 'Cardio metabólico, déficit calórico inteligente y suplementación para secar.',
      'coach_igor_specialty': 'Fuerza Máxima y Potencia',
      'coach_igor_desc': 'Progresión de cargas pesadas de 1RM a bajas reps y descansos completos.',
      
      // Settings Screen
      'settings_title': 'Configuración',
      'settings_language': 'Idioma',
      'settings_units': 'Unidad de Peso',
      'settings_default_formula': 'Fórmula por Defecto',
      'settings_about': 'Acerca de PowerMax',
      'settings_about_desc': 'PowerMax 1RM es una herramienta premium diseñada para atletas de fuerza. Cuenta con integración de tu equipo de entrenadores personalizados 100% offline.',
    },
    'pt': {
      'app_title': 'PowerMax 1RM',
      'nav_calculator': 'Calculadora',
      'nav_history': 'Histórico',
      'nav_ai_coach': 'Coaches',
      'nav_settings': 'Ajustes',
      
      // Calculator Screen
      'calc_weight': 'Peso Levantado',
      'calc_reps': 'Repetições',
      'calc_formula': 'Fórmula',
      'calc_result_title': '1RM Estimado',
      'calc_save_btn': 'Salvar Marca',
      'calc_exercise_label': 'Nome do Exercício',
      'calc_exercise_hint': 'Ex: Supino, Agachamento',
      'calc_success_save': 'Marca salva com sucesso!',
      'calc_error_empty': 'Por favor, preencha todos os campos',
      
      // Zones
      'zone_warmup': 'Aquecimento / Resistência',
      'zone_hypertrophy': 'Hipertrofia Muscular',
      'zone_strength': 'Força Máxima',
      'zone_power': 'Potência Explosiva',
      
      // History Screen
      'history_title': 'Histórico de Marcas',
      'history_empty': 'Nenhuma marca registrada ainda. Bons treinos!',
      'history_chart_title': 'Evolução de Força (1RM)',
      
      // AI Coach
      'ai_title': 'Meu Coach',
      'ai_subtitle': 'Treinadores 100% offline e privados',
      'ai_chat_hint': 'Pergunte sobre séries, rotinas ou exercícios...',
      'ai_model_not_installed': 'Os treinadores não estão ativos.',
      'ai_model_desc': 'Desbloqueie o perfil de conhecimento dos seus treinadores para receber orientação personalizada sobre treinos, hipertrofia e força, 100% offline e privada.',
      'ai_download_btn': 'Desbloquear Treinadores Offline (~1.6GB)',
      'ai_downloading': 'Carregando Treinadores...',
      'ai_ready': 'Os treinadores estão prontos para ajudar!',
      'ai_welcome_msg': 'Olá! Sou o seu treinador. Analisei a sua marca de 1RM. Como posso ajudar você a otimizar o seu treino hoje?',
      'ai_thinking': 'Pensando...',
      'ai_status_active': 'Treinadores Ativos (Offline)',
      'ai_status_inactive': 'Treinadores Desativados',
      'ai_download_warning': 'Não feche o app. Ele será salvo permanentemente e 100% offline.',
      'coach_cristian_specialty': 'Hipertrofia Muscular',
      'coach_cristian_desc': 'Séries gigantes, tempos e RPE 8-10 para ganhar o máximo de massa muscular e pump.',
      'coach_ana_specialty': 'Definição e Nutrição',
      'coach_ana_desc': 'Cardio metabólico, déficit calórico inteligente e suplementação para secar.',
      'coach_igor_specialty': 'Força Máxima e Potência',
      'coach_igor_desc': 'Progressão de cargas pesadas de 1RM a baixas repetições e descansos completos.',
      
      // Settings Screen
      'settings_title': 'Configurações',
      'settings_language': 'Idioma',
      'settings_units': 'Unidade de Peso',
      'settings_default_formula': 'Fórmula Padrão',
      'settings_about': 'Sobre o PowerMax',
      'settings_about_desc': 'PowerMax 1RM é uma ferramenta premium projetada para atletas de força. Possui integração da sua equipe de treinadores personalizados 100% offline.',
    }
  };

  // Método estático para obtener traducciones de forma fácil
  static String translate(BuildContext context, String key, [WidgetRef? ref]) {
    String currentLocale = 'es';
    if (ref != null) {
      currentLocale = ref.watch(localeProvider);
    } else {
      // Intenta leer el idioma local
      final String? langCode = Localizations.localeOf(context).languageCode;
      if (langCode != null && _localizedValues.containsKey(langCode)) {
        currentLocale = langCode;
      }
    }
    
    return _localizedValues[currentLocale]?[key] ?? key;
  }
}

// Extensión para simplificar la traducción en la UI
extension TranslationExtension on BuildContext {
  String tr(String key, [WidgetRef? ref]) => AppLocalizations.translate(this, key, ref);
}
