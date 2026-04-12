/// Converts Russian gender text to backend enum value
String mapGenderToBackend(String russianGender) {
  switch (russianGender.toLowerCase()) {
    case 'мужской':
    case 'мужчина':
      return 'MALE';
    case 'женский':
    case 'женщина':
      return 'FEMALE';
    case 'другое':
      return 'OTHER';
    default:
      return russianGender; // Return as-is if not recognized
  }
}

/// Converts backend enum value to Russian text for display
String mapGenderFromBackend(String backendGender) {
  switch (backendGender.toUpperCase()) {
    case 'MALE':
      return 'Мужской';
    case 'FEMALE':
      return 'Женский';
    case 'OTHER':
      return 'Другое';
    default:
      return backendGender;
  }
}

/// Converts Russian goal text to backend enum value
String mapGoalToBackend(String russianGoal) {
  switch (russianGoal.toLowerCase()) {
    case 'похудеть':
    case 'похудеть до 60 кг':
    case 'снизить процент жира':
      return 'LOSE_WEIGHT';
    case 'набрать мышцы':
    case 'набрать массу до 70 кг':
    case 'набрать мышечную массу':
      return 'GAIN_MUSCLE_MASS';
    case 'улучшить здоровье':
    case 'поддержать текущий вес':
    case 'улучшить выносливость':
    case 'поддержать':
      return 'KEEP_FIT';
    default:
      return 'KEEP_FIT'; // Default to KEEP_FIT if not recognized
  }
}

/// Converts backend enum value to Russian text for display
String mapGoalFromBackend(String backendGoal) {
  switch (backendGoal.toUpperCase()) {
    case 'LOSE_WEIGHT':
      return 'Похудеть';
    case 'GAIN_MUSCLE_MASS':
      return 'Набрать мышцы';
    case 'KEEP_FIT':
      return 'Улучшить здоровье';
    default:
      return backendGoal;
  }
}
