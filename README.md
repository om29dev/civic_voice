# Civic Voice

Civic Voice is a modern, premium flutter application designed to empower citizens by providing a centralized platform for accessing government services, schemes, and a groundbreaking AI-powered assistant (CVI). Built with a focus on accessibility and user experience, Civic Voice bridges the gap between citizens and essential services through an intuitive, bilingual interface.

## 🌟 Key Features

*   **Premium, Responsive UI**: A meticulously crafted interface featuring glassmorphism, dynamic gradients, elegant animations, and a rich color palette inspired by Indian aesthetics.
*   **CVI - Your AI Assistant**: A completely custom, intelligent voice and text assistant that can answer questions about government schemes, services, and procedures in multiple languages.
*   **Bilingual Support**: Full support for both English and Hindi, allowing users to seamlessly switch languages at any point for enhanced accessibility.
*   **Government Services Hub**: A comprehensive directory of public services (Aadhaar, PAN, Passport, etc.) with detailed guides, prerequisites, timelines, and application links.
*   **Citizen Profile**: A centralized digital profile to manage personal information and track application statuses.
*   **AWS Cloud Backend**: Robust and scalable backend architecture powered by AWS Amplify, incorporating Cognito for secure authentication and DynamoDB for reliable data storage.

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (stable channel)
*   Dart SDK
*   Android Studio / Xcode (for emulation and building)
*   AWS CLI and Amplify CLI (for backend configuration)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/civic_voice.git
    cd civic_voice
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## 🛠️ Technology Stack

*   **Frontend**: Flutter, Dart
*   **State Management**: Provider
*   **Routing**: GoRouter
*   **Styling & UI**: Google Fonts, Flutter Animate
*   **Backend & Auth**: AWS Amplify, Amazon Cognito
*   **Database**: Amazon DynamoDB
*   **AI Integration**: Amazon Bedrock (via API Gateway/Lambda)

## 📁 Project Structure

The project follows a feature-first architectural pattern:

*   `lib/core/`: Application-wide constants, networking, routing, and theme definitions.
*   `lib/features/`: Individual feature modules (auth, dashboard, services, voice, profile).
*   `lib/models/`: Data structures representing application entities.
*   `lib/providers/`: State management controllers handling business logic.
*   `lib/widgets/`: Reusable, custom UI components.

## 🤝 Contributing

We welcome contributions to make Civic Voice even better! Please feel free to submit pull requests or open issues to suggest improvements or report bugs.
