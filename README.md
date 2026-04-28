# 🏟️ Sahalat - Smart Stadium Navigation System

A Flutter-based mobile application that provides intelligent indoor navigation for stadiums using AR, AI crowd detection, and advanced pathfinding algorithms.

## 📋 Table of Contents
- [Features](#features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Project](#running-the-project)
- [Project Structure](#project-structure)
- [AI Crowd Detection Setup](#ai-crowd-detection-setup)
- [Unity AR Integration](#unity-ar-integration)
- [Algorithms](#algorithms)
- [Team](#team)

---

## ✨ Features

### 🧭 Smart Navigation
- **A* & Dijkstra Pathfinding**: Choose between two proven algorithms for optimal route calculation
- **Congestion-Aware Routing**: Dynamic path adjustment based on real-time crowd levels
- **GPS Integration**: Automatic detection of user's current location in the stadium
- **Multi-Destination Support**: Navigate to VIP sections, standard seats, food courts, and restrooms

### 🤖 AI-Powered Crowd Detection
- **CSRNet CNN Model**: Real-time crowd density estimation using deep learning
- **Live Mode**: Continuous scanning (every 3 seconds) for crowd monitoring
- **Auto-Reroute**: Automatic path recalculation when high congestion is detected
- **Smart Facility Selection**: AI recommends least crowded facilities

### 🥽 Augmented Reality Navigation
- **Unity AR Integration**: Immersive AR navigation with visual path indicators
- **Real-time 3D Visualization**: See your route overlaid on the real world
- **Indoor Positioning**: Accurate location tracking within the stadium

### 📱 Additional Features
- Car parking location save & navigate back
- Seat finder with row/seat number input
- Nearby facilities discovery
- Interactive stadium map
- Real-time capacity indicators

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Navigation  │  │  Crowd Scan  │  │   Unity AR   │      │
│  │    Screen    │  │    Screen    │  │   Integration│      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
                             │ HTTP API
                             │
┌────────────────────────────▼─────────────────────────────────┐
│              Python Flask API Server                         │
│  ┌────────────────────────────────────────────────────┐     │
│  │           CSRNet CNN Model (PyTorch)                │     │
│  │  - VGG16 Backbone                                   │     │
│  │  - Crowd Density Estimation                         │     │
│  │  - Real-time Image Processing                       │     │
│  └────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.x - Cross-platform mobile framework
- **Dart** - Programming language
- **Unity** 2021.3+ - AR navigation engine

### Backend
- **Python** 3.8+ - API server
- **Flask** - Web framework
- **PyTorch** - Deep learning framework
- **CSRNet** - Crowd counting model

### Algorithms
- **A* (A-Star)** - Heuristic pathfinding (default)
- **Dijkstra** - Alternative pathfinding algorithm
- **Haversine Formula** - GPS distance calculation
- **VGG16 CNN** - Feature extraction for crowd detection

### Services
- **Geolocator** - GPS positioning
- **Camera** - Image capture for AI analysis
- **MethodChannel** - Flutter-Unity communication

---

## 📦 Prerequisites

### Required Software
1. **Flutter SDK** 3.0 or higher
   ```bash
   flutter --version
   ```

2. **Android Studio** or **VS Code** with Flutter extensions

3. **Python** 3.8 or higher
   ```bash
   python --version
   ```

4. **Unity** 2021.3+ (for AR features)

5. **Git**
   ```bash
   git --version
   ```

### Required Hardware
- Android device (Android 7.0+) or emulator
- Computer with at least 8GB RAM
- Stable network connection

---

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/sahalat.git
cd sahalat
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Setup Python Environment for AI Server
```bash
# Navigate to the CSRNet server directory
cd csrnet_server

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 4. Download CSRNet Model
Download the pre-trained CSRNet model:
- Place `csrnet_epoch_81.pth` in `csrnet_server/saved_models/`
- [Model Download Link - Add your link here]

### 5. Unity AR Setup (Optional)
If you need AR features:
1. Open the Unity project in Unity Editor
2. Go to **Edit → Project Settings → Player → Android**
3. Set **Application Entry Point** to **Activity** (NOT GameActivity)
4. Export Android Library:
   - **File → Build Settings → Android → Export Project**
   - Export to: `Builds/AndroidFlutterExport/unityLibrary`
5. Copy `unityLibrary` to Flutter project:
   ```bash
   cp -r UnityProject/Builds/AndroidFlutterExport/unityLibrary android/
   ```

---

## 🏃 Running the Project

### Step 1: Start the AI Server
```bash
cd csrnet_server
python run_server_forever.py
```
Server will start on: `http://YOUR_IP:5000`

**Important**: Update the server IP in the Flutter app:
- File: `lib/core/crowd_detection_service.dart`
- Line: `static String _apiBaseUrl = 'http://YOUR_IP:5000';`

### Step 2: Run the Flutter App
```bash
flutter run
```

Or for a specific device:
```bash
flutter devices
flutter run -d DEVICE_ID
```

### Step 3: Build APK (Production)
```bash
flutter build apk --release
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 Project Structure

```
sahalat/
├── lib/
│   ├── core/                    # Core services
│   │   ├── location_service.dart          # GPS & geolocation
│   │   ├── crowd_detection_service.dart   # AI crowd detection API
│   │   ├── unity_navigation_bridge.dart   # Flutter-Unity bridge
│   │   └── car_location_service.dart      # Car parking feature
│   │
│   ├── domain/                  # Business logic
│   │   ├── stadium_layout.dart            # Stadium graph structure
│   │   ├── pathfinder.dart                # A* & Dijkstra implementation
│   │   ├── congestion_model.dart          # Crowd congestion management
│   │   ├── facility_selector.dart         # Smart facility recommendations
│   │   └── stadium_models.dart            # Data models
│   │
│   ├── features/                # UI Features
│   │   ├── navigation/
│   │   │   ├── navigation_steps_screen.dart
│   │   │   ├── crowd_scan_screen.dart     # AI camera screen
│   │   │   └── widgets/
│   │   │       ├── destination_chip_selector.dart
│   │   │       └── mini_stadium_map.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   └── camera_nav/
│   │       └── camera_nav_screen.dart
│   │
│   └── main.dart                # App entry point
│
├── android/
│   ├── app/
│   └── unityLibrary/            # Unity AR integration (not in git)
│
├── assets/                      # Images, fonts, etc.
│
├── csrnet_server/               # Python AI Server (separate repo recommended)
│   ├── api_server.py            # Flask API
│   ├── run_server_forever.py   # Auto-restart script
│   ├── model.py                 # CSRNet model definition
│   ├── requirements.txt         # Python dependencies
│   └── saved_models/            # Model weights (not in git)
│
├── pubspec.yaml                 # Flutter dependencies
└── README.md                    # This file
```

---

## 🤖 AI Crowd Detection Setup

### API Endpoints

#### 1. Health Check
```bash
GET http://YOUR_IP:5000/health
```
Response:
```json
{
  "status": "ok",
  "model_loaded": true,
  "device": "cpu"
}
```

#### 2. Detect Crowd (Base64 Image)
```bash
POST http://YOUR_IP:5000/detect_base64
Content-Type: application/json

{
  "image": "base64_encoded_image_string"
}
```
Response:
```json
{
  "success": true,
  "count": 45,
  "crowd_level": "moderate",
  "processing_time": 1.23
}
```

### Crowd Levels
- **Low**: < 20 people 🟢
- **Moderate**: 20-50 people 🟡
- **High**: 50-100 people 🟠
- **Very High**: > 100 people 🔴

### Fallback Mode
If the server is unavailable, the app uses **simulation mode** with realistic crowd estimates based on time of day.

---

## 🥽 Unity AR Integration

### Requirements
1. Unity 2021.3 or higher
2. AR Foundation package
3. ARCore XR Plugin (Android)

### Integration Steps
1. Set **Application Entry Point** to **Activity** in Unity Player Settings
2. Export as Android Library
3. Copy to `android/unityLibrary/`
4. Run `flutter clean && flutter build apk`

### Communication
Flutter ↔ Unity communication via `MethodChannel`:
```dart
UnityNavigationBridge.openUnityWithNavigation(
  pathNodeIds: ['gateA', 'concourse1', 'food1'],
);
```

---

## 🧮 Algorithms

### 1. A* (A-Star) Pathfinding
- **Type**: Informed search algorithm
- **Heuristic**: Euclidean distance
- **Complexity**: O(b^d) where b=branching factor, d=depth
- **Use Case**: Default algorithm for fast, optimal routing

**Formula**:
```
f(n) = g(n) + h(n)
where:
- g(n) = cost from start to node n
- h(n) = estimated cost from n to goal (heuristic)
```

### 2. Dijkstra's Algorithm
- **Type**: Uninformed search algorithm
- **Guarantee**: Always finds shortest path
- **Complexity**: O((V + E) log V)
- **Use Case**: When guaranteed optimal path is required

### 3. Congestion-Aware Routing
Adjusts edge weights based on crowd levels:
```
final_weight = base_weight + congestion_penalty
```

Congestion penalties:
- Low: +0
- Medium: +3
- High: +8

### 4. CSRNet (Crowd Counting)
- **Architecture**: VGG16 + Dilated Convolutions
- **Input**: RGB image (any size)
- **Output**: Density map → total count
- **Training**: ShanghaiTech Dataset

---

## 👥 Team

**Graduation Project - [University Name]**

- **Team Member 1** - [Role]
- **Team Member 2** - [Role]
- **Team Member 3** - [Role]
- **Supervisor** - [Name]

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- CSRNet implementation based on [MCNN Paper](https://arxiv.org/abs/1803.03095)
- Stadium layout inspired by real-world venues
- Unity AR Foundation documentation
- Flutter community

---

## 📞 Support

For issues or questions:
- Open an issue on GitHub
- Contact: [your-email@example.com]

---

## 🔮 Future Enhancements

- [ ] Multi-language support (Arabic/English)
- [ ] Real-time user location tracking
- [ ] Social features (meet friends at stadium)
- [ ] Integration with ticketing systems
- [ ] Offline mode support
- [ ] iOS support
- [ ] Cloud deployment of AI server

---

**Made with ❤️ by Team Sahalat**
