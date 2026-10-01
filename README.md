# Quizze - Offline-First Trivia Application

**Quizze** is a modern, responsive, and robust trivia application built with Flutter. It utilizes an offline-first architecture, leveraging **SQLite** to cache trivia questions fetched from the **Open Trivia Database (OpenTDB)** REST API. This ensures users can enjoy seamless gameplay even without an active internet connection.

---

## ✨ Features

- **Offline-First Gameplay**: Automatically caches downloaded questions into a local SQLite database to save bandwidth and support offline play.
- **Extensive Category Selection**: 15 pre-configured trivia categories ranging from General Knowledge to Computer Science.
- **Customizable Quizzes**: Configure the exact number of questions (5-50), Difficulty (Easy/Medium/Hard), and Question Type (Multiple Choice / True-False).
- **Modern Material 3 UI**: Features sleek rounded cards, vibrant coloring, and custom 60fps sliding page transitions for a premium feel.
- **Adaptive Error Handling**: Includes user-friendly fallback screens if a requested configuration lacks sufficient questions from the API.

---

## 🛠️ Technology Stack & Architecture

- **Framework:** Flutter / Dart
- **State Management:** Ephemeral State (`StatefulWidget`) for localized UI logic
- **Networking:** `http` package for REST API communication
- **Local Database:** `sqflite` for fast, lightweight local storage and caching
- **Data Parsing:** `html_unescape` to correctly render complex HTML entities returned from OpenTDB
- **App Icons:** `flutter_launcher_icons` for dynamic Android Adaptive Icons

### How the Data Flows
1. **Request**: The user selects a category and configures their quiz.
2. **Local Check**: The `ApiService` queries the `DatabaseHelper` to check if enough questions exist locally.
3. **Network Fallback**: If local data is insufficient, the app reaches out to the OpenTDB API.
4. **Caching**: Fetched questions are parsed, permanently cached into SQLite, and served to the UI.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13.2 or higher)
- Android Studio / VS Code
- A physical device or emulator to test

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Yeamin-Talukder/QUIZ-APP.git
   ```

2. **Navigate to the project directory:**
   ```bash
   cd QUIZ-APP
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

### Building for Production
To build a highly optimized release APK for Android devices:
```bash
flutter build apk --release
```
The output file will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📸 Application Structure

```text
lib/
├── main.dart             # Core UI, Routing, and State (HomeScreen, QuizScreen, etc.)
├── api_service.dart      # Network layer managing HTTP requests & API error handling
└── database_helper.dart  # SQLite Schema, initialization, and data querying logic
```

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

---
*Built as a Flutter Lab Final Project.*
