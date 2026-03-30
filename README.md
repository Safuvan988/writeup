# WriteUp

A modern Flutter application for writing, reading, and sharing blogs and articles. 

WriteUp provides a seamless platform for creators to express their thoughts, readers to discover compelling content, and everyone to engage in a community of writers.

## 🌟 Features

* **Authentication**: Secure Login and Registration for users.
* **Home Feed**: Browse through a feed of recent and popular blogs.
* **Create Blogs**: Rich text editor or simple writing interface to create new blogs with images.
* **Blog Details**: Read full articles with a clean and focused reading mode.
* **Bookmarks**: Save your favorite articles to read them later.
* **User Profile**: Manage your profile, view your published blogs, and update your information.
* **Share**: Easy sharing of blogs with others using `share_plus`.

## 🛠 Tech Stack & Dependencies

* **Framework**: Flutter
* **Networking**: `http`, `http_parser`
* **Local Storage**: `shared_preferences` (for auth tokens & app state)
* **Media / Images**: `image_picker` (for uploading blog covers and profile pictures)
* **UI Utilities**: `flutter_svg`, `google_fonts`, `cupertino_icons`

## 📁 Project Structure

The project follows a modular, feature-first architecture:

```text
lib/
├── app/
│   └── theme_data/       # App-wide theme, colors, and typography
├── src/
│   ├── core/
│   │   └── services/     # Core services like StorageService
│   └── modules/
│       ├── auth/         # Login and Registration screens
│       ├── home_screen/  # Home feed, Create Blog, Blog Details, and Bookmarks
│       └── profile/      # User profile management
└── main.dart             # App entry point & initialization
```

## 🚀 Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

* Flutter SDK (>=3.10.7)
* Dart SDK
* An IDE (Android Studio, VS Code, or IntelliJ)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd write_up
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📚 Resources

To learn more about Flutter development:
* [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
* [Online Documentation](https://docs.flutter.dev/)
