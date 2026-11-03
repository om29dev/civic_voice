# Contributing to Civic Voice

Thank you for your interest in contributing to Civic Voice. This project aims to empower citizens across Bharat by providing open access to welfare schemes and government services through a voice-first, AI-assisted interface.

Please review this guide before submitting contributions.

---

## Code of Conduct

All contributors and maintainers are expected to abide by our [Code of Conduct](file:///d:/proj/civic_voice/CODE_OF_CONDUCT.md). Please treat all members of the community with respect.

---

## Development Prerequisites

Ensure your development environment meets the following minimum requirements:

- Flutter SDK: version 3.27.0 or higher
- Dart SDK: version 3.6.0 or higher
- Android SDK: compileSdkVersion 34, targetSdkVersion 34, minSdkVersion 24
- Java Development Kit (JDK): JDK 17
- PowerShell (on Windows) or standard terminal
- Git

---

## Local Development Setup

1. Fork the repository and clone your fork:
   ```powershell
   git clone https://github.com/<your-username>/civic_voice.git
   cd civic_voice
   ```

2. Install Flutter package dependencies:
   ```powershell
   flutter pub get
   ```

3. Run static analysis to verify your workspace:
   ```powershell
   flutter analyze
   ```

4. Run the automated test suite:
   ```powershell
   flutter test
   ```

5. Run on an Android emulator or connected device:
   ```powershell
   flutter run
   ```

---

## Branching and Commit Guidelines

### Branch Naming Conventions
Create branches from `main` using descriptive prefixes:
- `feat/feature-name` (new functionality)
- `fix/bug-description` (bug fixes)
- `docs/documentation-update` (documentation improvements)
- `refactor/code-improvement` (refactoring without behavioral change)
- `test/test-suite` (adding or updating tests)

### Commit Message Format
We follow the Conventional Commits specification:
```text
<type>(<scope>): <short description>
```
Examples:
- `feat(schemes): add state filter to dynamodb discovery service`
- `fix(auth): handle cognito session expiration on token refresh`
- `docs(readme): update build and installation instructions`

Commit rules:
- Strictly no emojis in commit messages or code comments.
- Strictly no em-dashes or en-dashes; use standard hyphens or colons.
- Keep the subject line concise (under 72 characters).

---

## Code Standards

- **Dart Style**: Adhere to official Dart guidelines enforced by `analysis_options.yaml`.
- **Clean Architecture**: Separate business logic into services and providers; keep UI widgets focused on presentation.
- **Zero Hardcoded Secrets**: Never commit AWS credentials, API keys, private certificates, or local configuration files (`local.properties`, `local-*.json`).
- **Data Minimization**: Never commit raw citizen identification numbers, personally identifiable datasets, or real test PII.
- **Test Coverage**: Write unit or widget tests under `test/` for all new services, models, and provider states.

---

## Submitting a Pull Request

1. Ensure your local branch is up to date with `upstream/main`.
2. Verify all quality checks pass locally:
   ```powershell
   flutter analyze
   flutter test
   ```
3. Push your branch to your GitHub fork:
   ```powershell
   git push origin feat/your-feature-name
   ```
4. Open a Pull Request against the `main` branch.
5. Fill out the Pull Request template completely, linking relevant issue tickets.
6. Ensure all automated CI checks (Static Analysis, Unit Tests, CodeQL Security Scan) pass.
7. Address any code review feedback from maintainers. Once approved, maintainers will squash and merge your PR.

