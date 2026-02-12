# Facebook Integration Keys

We removed the Facebook SDK integration to simplify the initial Google Play and App Store review process and avoid data safety/ATT compliance delays.

When you are ready to implement Facebook App Install Ads, restore the `facebook_app_events` plugin and use these keys.

## Configuration Keys

- **Facebook App ID**: `1597052071716440`
- **Facebook Client Token**: `e29fe860a25ecbc30f24b24670e8429b`
- **Facebook Display Name**: `Airmass Xpress`

## Integration Steps

1. Add `facebook_app_events` to `pubspec.yaml`.
2. Add the following to `android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="facebook_app_id">1597052071716440</string>
   <string name="facebook_client_token">e29fe860a25ecbc30f24b24670e8429b</string>
   ```
3. Add the following to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
   <meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>
   ```
4. Add the following to `ios/Runner/Info.plist`:
   ```xml
   <key>FacebookAppID</key>
   <string>1597052071716440</string>
   <key>FacebookClientToken</key>
   <string>e29fe860a25ecbc30f24b24670e8429b</string>
   <key>FacebookDisplayName</key>
   <string>Airmass Xpress</string>
   ```
5. Ensure compliance with App Tracking Transparency (iOS) and Data Safety (Android).
