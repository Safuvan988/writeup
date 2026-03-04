# Troubleshooting MissingPluginException (image_picker)

The `MissingPluginException` for `image_picker` occurs when the native platform code is not correctly registered with the Flutter engine. This is common when adding plugins while the app is running.

## Resolution Steps

1.  **Terminate the current run**: Stop the app completely in your IDE or terminal.
2.  **Clean dependencies (Optional)**:
    ```bash
    flutter clean
    ```
3.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Full Rebuild**: Start the app again (`F5` in VS Code or `flutter run`).

## Platform Specifics

### Android
Ensure `android/app/src/main/AndroidManifest.xml` doesn't have conflicting configurations. `image_picker` usually works out of the box for basic use, but for camera access or older API levels, you might need:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS
Add usage descriptions to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Allow access to photo library to upload blog images</string>
<key>NSCameraUsageDescription</key>
<string>Allow access to camera to take blog photos</string>
```

### Windows
If running as a Windows Desktop app, ensure you have the latest `image_picker_windows` dependency (usually included automatically by `image_picker`). Re-running `flutter run -d windows` will trigger the CMake build required to link the plugin.
