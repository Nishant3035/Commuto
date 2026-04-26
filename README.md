# Commuto

Commuto is a modern ride-sharing application built with Flutter and Firebase. It allows users to offer rides, find rides, and travel together securely and efficiently.

## Features

* **Authentication:** Secure phone number authentication using Firebase Auth with OTP verification.
* **Ride Offering:** Drivers can offer rides by specifying start and end locations, seats available, and fare.
* **Find a Ride:** Passengers can search for available rides based on their source and destination.
* **Real-time Navigation:** Integration with Google Maps and Places API for seamless location selection and route tracking.
* **Active Ride Dashboard:** Drivers have a dedicated dashboard to manage their active rides, track passengers, and update ride status.
* **Safety First:** Built-in SOS feature and emergency contacts management.
* **User Profiles:** Manage personal information, gender, and profile details.
* **Web & Mobile Support:** Cross-platform functionality, ensuring a smooth experience on both mobile devices and web browsers.

## Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Firestore, Authentication, Functions, Hosting)
* **Maps:** Google Maps Platform (Maps SDK, Places API)

## Setup Instructions

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Ensure you have your Firebase project configured and the necessary configuration files (`google-services.json` for Android, etc.) added.
4. Add your Google Maps API key in the appropriate configuration files (`AndroidManifest.xml`, `index.html`, etc.).
5. Run the app using `flutter run`.
