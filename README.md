# HazMove Robot Control

A professional Flutter mobile application using Clean Architecture principles to control a robotic arm mounted on a linear rail system.

## 🎯 Features

### Core Functionality
- **Real-time Robot Control**: Control servo motors, linear rail, and base rotation
- **Multiple Control Modes**: Manual control and automated preset execution
- **Live Visualization**: Animated robot arm representation showing current state
- **Connection Management**: WebSocket and Bluetooth connectivity
- **Safety Features**: Movement limits, emergency stop, pause/resume

### UI Components
- **Modern Industrial Design**: Dark theme with cyan/blue accents
- **Real-time Status**: Connection status, movement indicators
- **Interactive Controls**: Sliders, buttons, and input fields
- **Responsive Layout**: Optimized for mobile devices

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Shared utilities and core functionality
│   ├── constants/           # App constants and configuration
│   ├── di/                 # Dependency injection setup
│   ├── error/               # Error handling and failures
│   ├── network/             # Network information utilities
│   ├── usecases/            # Base use case classes
│   └── utils/              # Utility functions and extensions
├── features/
│   └── robot_control/       # Main feature module
│       ├── data/            # Data layer implementation
│       │   ├── datasources/  # Remote and local data sources
│       │   ├── models/       # Data models
│       │   └── repositories/ # Repository implementations
│       ├── domain/          # Business logic layer
│       │   ├── entities/     # Business entities
│       │   ├── repositories/ # Repository interfaces
│       │   └── usecases/    # Use case implementations
│       └── presentation/    # UI layer
│           ├── bloc/         # State management
│           ├── pages/        # Screen widgets
│           └── widgets/      # Reusable UI components
└── main.dart               # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.11.5)
- Dart SDK (>= 3.11.5)
- WebSocket-enabled robot controller

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hazmove_robot
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Robot Connection
Configure your robot connection in Settings:
- **WebSocket URL**: Default `ws://10.76.62.83:81`
- **Bluetooth**: Select device from available list
- **Connection Timeout**: 15 seconds

### Movement Limits
Adjust safety limits in Settings:
- **Servo Angles**: 0° - 180°
- **Linear Rail**: 0 - 100 cm
- **Base Rotation**: 0° - 360°
- **Speed Ranges**: 1 - 100 for all motors

## 📱 Usage

### Manual Control
1. **Connect** to your robot via WebSocket or Bluetooth
2. **Navigate** to Manual Control screen
3. **Adjust** servo angles using sliders or quick position buttons
4. **Control** linear rail movement and base rotation
5. **Monitor** real-time status and movement indicators

### Auto Mode
1. **Create** movement presets with multiple steps
2. **Execute** presets for automated sequences
3. **Pause/Resume** running sequences as needed
4. **Save** frequently used movements for quick access

### Safety Features
- **Emergency Stop**: Immediately halt all movements
- **Movement Limits**: Prevent out-of-range operations
- **Collision Detection**: Avoid potential damage
- **Status Monitoring**: Real-time feedback on robot state

## 🔌 Communication Protocol

### WebSocket Commands
Send JSON commands to control the robot:

```json
{
  "type": "servo",
  "servo_id": 1,
  "start": 0,
  "end": 90,
  "speed": 50
}
```

### Command Types
- **servo**: Control servo motors
- **linear**: Move linear rail
- **base**: Rotate base
- **stop**: Emergency stop
- **pause**: Pause movements
- **resume**: Resume movements

### Response Format
```json
{
  "type": "status",
  "data": {
    "servos": [...],
    "linearRail": {...},
    "baseRotation": {...}
  }
}
```

## 🎨 UI Components

### Robot Arm Visualization
- **Real-time Animation**: Shows current robot state
- **Interactive Display**: Visual feedback for movements
- **Status Indicators**: Connection and movement status

### Control Widgets
- **Servo Sliders**: Precise angle control with speed adjustment
- **Linear Rail Control**: Position and speed management
- **Base Rotation**: Degree-based rotation control
- **Quick Actions**: Preset position buttons

### Status Displays
- **Connection Status**: Visual connection indicators
- **Movement Status**: Real-time operation feedback
- **Error Messages**: Clear error reporting

## 🛠️ Development

### State Management
- **BLoC Pattern**: Reactive state management
- **Dependency Injection**: GetIt service locator
- **Clean Architecture**: Separated layers and responsibilities

### Key Dependencies
- `flutter_bloc`: State management
- `get_it`: Dependency injection
- `web_socket_channel`: WebSocket communication
- `shared_preferences`: Local storage
- `equatable`: Value equality

### Code Structure
- **Entities**: Business objects
- **Use Cases**: Application logic
- **Repositories**: Data access abstraction
- **Data Sources**: Network and local storage

## 🎨 Customization

### Adding New Features
1. **Create Entity**: Define business object in domain layer
2. **Implement Use Case**: Add application logic
3. **Add Repository**: Define data access interface
4. **Create UI**: Build presentation layer components
5. **Wire Dependencies**: Configure dependency injection

### Styling
- **Theme Configuration**: Modify `ThemeData` in main.dart
- **Color Scheme**: Update constants in `app_constants.dart`
- **Component Styles**: Modify individual widget styles

## 🐛 Troubleshooting

### Common Issues
- **Connection Failed**: Check WebSocket URL and network connectivity
- **Movement Not Responding**: Verify robot is powered and connected
- **App Crashes**: Check Flutter logs for error details

### Debug Mode
Enable debug logging:
```dart
Logger.debug('Debug message', 'Tag');
```

### Performance Optimization
- Use `const` constructors where possible
- Implement proper widget lifecycle management
- Optimize rebuild cycles with BLoC patterns

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For support and questions:
- **Documentation**: Check this README and code comments
- **Issues**: Report bugs via GitHub Issues
- **Features**: Request enhancements via GitHub Discussions

---

**Built with ❤️ using Flutter and Clean Architecture**
