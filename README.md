# Commuto 🚗🌱

<p align="center">
  <b>Smart, Secure, and Eco-Friendly Carpooling.</b><br>
  <i>Built with Flutter & Firebase.</i>
</p>

## 📖 Overview

Commuto is a modern ride-sharing application designed to connect drivers with empty seats to commuters heading the same way. Built specifically with students and corporate professionals in mind, Commuto tackles high transit costs, traffic congestion, and carbon emissions by providing a secure and cost-effective carpooling platform.

## ✨ Key Features

*   **🔒 Secure Authentication:** Phone-based OTP login via Firebase Auth.
*   **🤖 AI Document Verification:** Uses **Google ML Kit OCR** to scan and extract details from College/Company IDs locally on the device.
*   **📍 Smart Ride Matching:** Search for rides based on source, destination, and date using Google Maps and Places API integration.
*   **🛡️ Secure OTP Boarding:** Fare transactions are securely executed via **Firebase Cloud Functions** only after the passenger provides the driver with a unique 4-digit boarding OTP.
*   **👩 Women-Only Mode:** Enhanced safety feature allowing female users to host and search exclusively for female-only rides.
*   **🗺️ Live Navigation:** Real-time driver location tracking for waiting passengers.
*   **💬 In-App Chat:** Real-time messaging between drivers and passengers.
*   **🚨 SOS Alerts:** Built-in emergency button that alerts pre-configured contacts with your live location.
*   **🌍 Eco-Tracking:** Gamified profile statistics showing total money saved and CO2 emissions reduced.

## 🛠️ Tech Stack

*   **Frontend:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend:** [Firebase](https://firebase.google.com/) (Firestore, Authentication, Cloud Functions, Cloud Messaging)
*   **AI/ML:** [Google ML Kit](https://developers.google.com/ml-kit) (Text Recognition OCR)
*   **Maps:** Google Maps Platform (Maps SDK, Places API)

## 🏗️ Architecture

1.  **Client (Flutter):** Handles UI, local state, Maps rendering, and on-device OCR.
2.  **Database (Firestore):** Stores Users, Rides, Bookings, and Chats. Strict Security Rules ensure data privacy.
3.  **Serverless (Cloud Functions):** Handles secure operations like OTP generation, OTP verification (fare transfer), and push notifications, preventing client-side tampering.

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (^3.11.1)
*   Firebase Project (with Auth, Firestore, and Functions enabled)
*   Google Maps API Key (with Maps SDK and Places API enabled)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/commuto.git
    cd commuto
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Environment Variables:**
    Create a `.env` file in the root directory and add your API keys:
    ```env
    GOOGLE_MAPS_API_KEY_ANDROID=your_android_key
    GOOGLE_MAPS_API_KEY_IOS=your_ios_key
    GOOGLE_MAPS_API_KEY_WEB=your_web_key
    RAZORPAY_KEY_ID=your_razorpay_key
    RAZORPAY_KEY_SECRET=your_razorpay_secret
    ```

4.  **Firebase Configuration:**
    Ensure you have added your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

5.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

```text
lib/
├── models/         # Data models (UserModel, RideModel, BookingModel)
├── screens/        # UI Views (HomeScreen, FindRideScreen, ActiveRideScreen...)
├── services/       # Business logic & APIs (AuthService, FirestoreService...)
├── utils/          # Helpers (FareCalculator, Theme...)
├── widgets/        # Reusable UI components
└── main.dart       # App entry point
functions/          # Firebase Cloud Functions (Node.js)
```

## 🔮 Future Scope

*   Integration with real payment gateways (Razorpay/Stripe) for wallet top-ups.
*   Integration with Gemini AI for dynamic pricing and route optimization.
*   B2B Enterprise dashboards for universities to track campus-wide carbon emission reductions.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License.
