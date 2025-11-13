# 📚 BookSwap App

A modern Flutter application for book enthusiasts to trade books with others in their community. Built with Flutter and Firebase, BookSwap offers a seamless experience for listing, browsing, and swapping books.

## ✨ Features

### 🔐 Authentication
- **Secure Login/Signup**: Email/password authentication using Firebase
- **Email Verification**: Ensures valid user emails
- **Profile Management**: User profiles with customizable settings
- **Secure Sessions**: Persistent login state management

### 📚 Book Management
- **Easy Listing**: Create and manage book listings with:
  - Title and author
  - Condition (New, Like New, Good, Used)
  - Cover image upload
  - Real-time updates
- **Browse & Search**: Explore available books
- **My Library**: Manage your listed books
- **Detailed Views**: Comprehensive book information

### 🔄 Swap System
- **Simple Swapping**: One-tap swap requests
- **Real-time Updates**: Instant status changes
- **Request Management**: Accept/reject incoming swaps
- **Swap History**: Track all your transactions

### 💬 Chat System
- **Real-time Messaging**: Instant communication
- **Swap-specific Chats**: Organized by swap request
- **Chat History**: Persistent message storage
- **Notifications**: Stay updated on messages

### ⚡ Technical Features
- Provider state management
- Firebase integration
- Real-time data sync
- Image upload & caching
- Clean architecture
- Responsive UI

## 🚀 Getting Started

### Prerequisites
- Flutter (latest version)
- Firebase account
- Android Studio/VS Code
- Git

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/bookswap_app.git
   cd bookswap_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Enable Authentication and Firestore
   - Add your app to Firebase
   - Download config files:
     - Android: `google-services.json`
     - iOS: `GoogleService-Info.plist`
   - Place config files in respective directories

4. **Run the App**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable components
└── main.dart        # App entry point
```

## 🛠️ Built With

- **Flutter**: UI framework
- **Firebase**: Backend services
  - Authentication
  - Cloud Firestore
  - Storage
- **Provider**: State management
- **Image Picker**: Media selection
- **Cached Network Image**: Image optimization

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Flutter Team
- Firebase
- Open-source community
- All contributors

---

Made with ❤️ by Olivier Ishimwe
