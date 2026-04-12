class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите email";
    }
    if (!value.contains("@") || !value.contains(".")) {
      return "Некорректный email";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите пароль";
    }
    if (value.length < 6) {
      return "Пароль должен быть не менее 6 символов";
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return "Подтвердите пароль";
    }
    if (value != password) {
      return "Пароли не совпадают";
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите имя";
    }
    if (value.length < 2) {
      return "Имя должно быть не менее 2 символов";
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите вес";
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0 || weight > 300) {
      return "Введите корректный вес (1-300 кг)";
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите рост";
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0 || height > 250) {
      return "Введите корректный рост (1-250 см)";
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите возраст";
    }
    final age = int.tryParse(value);
    if (age == null || age < 10 || age > 120) {
      return "Введите корректный возраст (10-120 лет)";
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "Поле $fieldName не может быть пустым";
    }
    return null;
  }
}
