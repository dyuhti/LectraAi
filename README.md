# Smart Lecture Notes

An AI-powered educational productivity app that helps students capture, organize, summarize, and revise lecture content efficiently.

## Features

- **Lecture Recording**: Record live lectures with playback capability
- **Note Taking**: Take quick handwritten or typed notes
- **PDF/Image Upload**: Upload lecture slides and materials
- **AI-Powered Features**:
  - Speech-to-text conversion
  - Auto-summarization
  - Keyword extraction
  - Flashcard/Quiz generation
- **Camera Note Scanning**: Scan board notes or written pages
- **Cloud-based Storage**: Organize notes by subjects
- **Study Analytics Dashboard**: Track subjects, time spent, and progress
- **Revision Tools**: Smart study materials for better retention

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── lecture_recording.dart
│   ├── note_taking.dart
│   ├── analytics_dashboard.dart
│   └── ...
├── widgets/                  # Reusable widgets
├── models/                   # Data models
└── services/                 # Business logic & APIs

android/                       # Android-specific configuration
assets/                        # Images, icons, fonts
test/                         # Unit tests
pubspec.yaml                  # Flutter dependencies
```

## Getting Started

### Prerequisites

- Flutter 3.0 or higher
- Android Studio
- Android SDK
- Dart SDK

### Installation

1. Clone this repository or navigate to the project directory
2. Install dependencies:
   ```
   flutter pub get
   ```

3. Generate build files:
   ```
   flutter pub run build_runner build
   ```

4. Run the app:
   ```
   flutter run
   ```

### Development in Android Studio

1. Open Android Studio
2. Click "File" → "Open"
3. Navigate to and select the `smartnotes` folder
4. Android Studio will recognize it as a Flutter project
5. Click the Run button or press Shift+F10 to run the app

## Architecture

- **State Management**: Provider + GetX for navigation and state
- **Database**: SQLite for local storage
- **Cloud Services**: Firebase for authentication and analytics
- **AI Integration**: Google Generative AI for summarization and keyword extraction
- **Media Handling**: Camera, audio recording, image processing

## Dependencies

Key packages used:
- `get`: Navigation and state management
- `record`: Audio recording
- `image_picker`: Image selection
- `firebase_core`: Firebase integration
- `google_generative_ai`: AI features
- `sqflite`: Local database
- `fl_chart`: Analytics visualization

## Future Enhancements

- Back navigation improvements
- Advanced camera features
- Enhanced audio processing
- Real-time collaboration
- Offline-first capabilities

## License

MIT License

## Contact

For questions or suggestions, please reach out.
