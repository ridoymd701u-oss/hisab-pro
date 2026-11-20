# HISAB PRO — Flutter Starter

A runnable starter project for a Bangla-first personal finance calendar.

## Included in this starter
- Dark premium dashboard
- Income and expense entry
- Local persistence on the device (`shared_preferences`)
- Calendar date selection and per-date transaction view
- Basic calculator
- Manual currency-to-BDT converter (enter a verified rate yourself)
- Phone and WhatsApp support links

## Run
1. Install Flutter SDK and Android Studio.
2. Extract this ZIP.
3. Open a terminal in this folder.
4. Run:

```bash
flutter doctor
flutter pub get
flutter run
```

To build an Android APK:

```bash
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Open in GitHub
Create a new GitHub repository, then upload the extracted project folder, or run:

```bash
git init
git add .
git commit -m "Initial HISAB PRO app"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

## Important notes
- This is a working starter, not the complete feature list described in the product plan.
- Bengali and Hijri calendar conversion, debt/credit ledgers, cloud sync, authentication, PDF/Excel export, stock management, recurring bills, AI assistant, and live exchange-rate API are not implemented yet.
- Currency conversion is manual by design; verify rates with your bank or exchange provider.
- Data is stored locally on the device. Uninstalling the app or clearing app data can remove it. Add a tested backup system before using it for important financial records.
- Contact and WhatsApp numbers are configured in `lib/main.dart`.
