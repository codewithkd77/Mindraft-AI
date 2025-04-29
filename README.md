🧠 Mindraft AI

🤖 AI-powered note-taking app that generates structured notes from text, images, PDFs, and YouTube videos.

![Alt text](https://raw.githubusercontent.com/codewithkd77/technews-flutter/refs/heads/main/banner.jpeg)
![Alt text](https://raw.githubusercontent.com/codewithkd77/technews-flutter/refs/heads/main/banner.jpeg)
![Alt text](https://raw.githubusercontent.com/codewithkd77/technews-flutter/refs/heads/main/banner.jpeg)

🛠️ Tech
- 📱 Flutter + 🔥 Supabase + 🤖 Google Gemini
- 🔐 Google Sign-In
- 📝 Markdown support
- 🌓 Dark/Light theme

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Android Studio / VS Code
- Android SDK (for Android development)
- Google Cloud Account (for Gemini API)
- Supabase Account

### Setup Steps

1. **Clone the Repository**
```bash
git clone https://github.com/yourusername/mindraft-ai.git
cd mindraft-ai
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Configure Supabase**
- Create a new project on [Supabase](https://supabase.com)
- Copy your project URL and anon key
- Create a `.env` file in the root directory:
```
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

4. **Configure Google Gemini API**
- Create a project in [Google Cloud Console](https://console.cloud.google.com)
- Enable Gemini API
- Create an API key
- Add the API key to `lib/config/api_keys.dart`

5. **Configure Google Sign-In**
- Create a project in [Google Cloud Console](https://console.cloud.google.com)
- Configure OAuth consent screen
- Create OAuth 2.0 credentials
- Update the Web Client ID in `lib/pages/auth/login_page.dart`

6. **Run the App**
```bash
flutter run
```

### Environment Setup
- Android: minSdkVersion 23
- Java: Version 17
- Kotlin: Version 1.8.0

### Troubleshooting
- If you encounter any issues with dependencies, try:
```bash
flutter clean
flutter pub get
```

- For Android build issues, ensure you have:
  - Android SDK installed
  - JAVA_HOME environment variable set
  - Android Studio with Flutter plugin

### Contributing
Feel free to submit issues and enhancement requests!

## 📱 Features

### Note Generation
- Text-based note generation
- Image-to-note conversion
- PDF document processing
- YouTube video summarization

### Organization
- Folder-based note organization
- Search functionality
- Markdown support
- Dark/Light theme

### Learning Tools
- Flashcard generation
- Quiz creation
- Smart content formatting

## 🔐 Security
- Secure authentication with Google Sign-In
- Encrypted local storage
- Secure API key management

## 📦 Dependencies
- `supabase_flutter`: Authentication and database
- `google_generative_ai`: AI-powered note generation
- `flutter_markdown`: Rich text support
- `image_picker`: Image selection
- `file_picker`: File handling
- `syncfusion_flutter_pdf`: PDF processing
- `youtube_explode_dart`: YouTube video processing
- `intl`: Date formatting
- `share_plus`: Content sharing

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments
- Flutter team for the amazing framework
- Supabase for backend services
- Google for Gemini AI
- All contributors and users
