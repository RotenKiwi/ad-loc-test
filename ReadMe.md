# Location Tracker (Flutter Assignment)

## Overview
### **Requirements**

1. **Obtain Device Location**
    - The app must request and handle appropriate permissions (location access) on both iOS and Android.
    - Ensure accurate location acquisition in the foreground (active state).
2. **Background & Terminated State Tracking**
    - Configure the app so that location tracking continues when the application is in the background.
    - Implement a solution that persists location updates even after the app is terminated (i.e., removed from recent apps).
3. **Data Handling**
    - Record or log the location information (latitude and longitude) at regular intervals.
    - Display the information with a persisting notification.
4. **User Interface**
    - Provide a simple UI to display the current/last known location.
    - Include an option to enable/disable background tracking for testing purposes.
---

### Android

- ✔ Background service using `flutter_background_service`
- ✔ Persistent foreground notification
- ✔ Continuous tracking even when app is minimized
- ✔ Works even after app is terminated

---

### iOS

- ✔ Foreground location tracking
- ✔ Background tracking (when app is minimized)
- ✔ Permission handling with "Always" access requirement

Important limitations exist (explained below)

---

## Architecture Overview

The app follows a layered architecture:

### 1. Presentation Layer
- UI components (widgets)
- Uses Provider for state consumption. The project was small enough to not opt for wither Riverpod or BLoC.

### 2. Provider Layer
- Centralized state management (`LocationProvider`)
- Handles Permissions, Tracking, Location Updates and Error

### 3. Service Layer
- Platform-specific logic
- Handles Location APIs, BG Execution, Notifications

### 4. Model Layer
- `LocationEntry` represents structured location data

---

## Permissions Handling

### Android
- Foreground + Background permissions requested programmatically
- Notification permission (Android 13+) handled at runtime

### iOS
- Requires:
    - “While Using” → initial
    - Manual upgrade to “Always” via Settings

---

## iOS Limitations (Important)

Due to Apple’s platform restrictions, full parity with Android is not possible.

---

### 1. No Tracking After App Termination

If the user force closes (swipes away) the app:

> iOS will NOT restart it for location updates

- Background tracking stops completely
- No location updates are recorded

Potential Solution could PushNotification based location logging. Apple wakes up the app whenever it receives a push notification (depends on the severity of the notification), this can be used to run a small function that gives us the location.

---

### 2. No Persistent Notification System

Unlike Android:

- iOS does NOT support foreground service notifications
- Notifications cannot be Persistent and Continuously updated

Potential solution to this is using Apple's Live Actions notification service.

---

### 3. Permission Upgrade Limitation

On iOS:

> You cannot programmatically upgrade from “While Using” → “Always”

User must manually enable it:

Settings → App → Location → Always

---

### 3. Background Execution Restrictions

Even with background modes enabled:

- iOS suspends app after inactivity
- Limits execution time
- May stop updates unpredictably

Potential Solution "AND IMPLEMENTED" is subscribe to apple's location update stream which in turn informs the app whenever there is a change in the location based on defined radius. in this case 10m.

---

## How This Was Handled

To accommodate iOS:

- UI prompts user to manually enable "Always" permission
- Background tracking works only when app is minimized
- Notifications are not relied upon for continuous updates
- System behavior is handled gracefully

---

## Testing Notes

### Android
- Fully functional across:
    - Foreground
    - Background
    - Terminated state

### iOS
- Works in:
    - Foreground
    - Background (limited)

- Does NOT work in:
    - Terminated state (expected behavior)
    -
---

## Key Design Decisions

- Platform-aware implementation (Android vs iOS)
- Clean separation of UI and logic
- Minimal duplication across platforms
- Graceful handling of OS limitations

---

## Future Improvements

- Implement Live Activities (iOS)
- Add backend sync for location persistence
- Improve battery optimization
- Add map visualization

---

## Final Note

This implementation achieves the maximum possible functionality within iOS constraints, while delivering full feature support on Android.