# Security Policy

Civic Voice takes the security and privacy of citizen data seriously. We welcome responsible disclosure of any security vulnerabilities found in our codebase, infrastructure, or dependent packages.

---

## Supported Versions

Only the latest release on the primary development branch is actively supported with security patches:

| Version | Supported |
| :--- | :--- |
| 1.x (main) | Yes |
| < 1.0.0 | No |

---

## Reporting a Vulnerability

If you discover a security vulnerability, please do NOT create a public GitHub issue.

Instead, report vulnerabilities privately by emailing the maintainer:
- **Contact**: `ombharambe29@gmail.com` (or open a confidential security advisory on GitHub via the **Security** tab -> **Advisories** -> **Report a vulnerability**)
- **Response Time**: You will receive an initial response within 48 hours acknowledging receipt of your report.
- **Resolution**: Maintainers will investigate and provide regular status updates until a patch is released.

### What to Include in Your Report
Please provide:
1. Detailed description of the vulnerability.
2. Steps to reproduce the issue (proof-of-concept scripts or steps).
3. The affected components (Flutter client, AppSync API, Bedrock inference, authentication).
4. Potential impact on citizen privacy, confidentiality, or system availability.

---

## Security Architecture and Guarantees

Civic Voice is built following zero-trust principles:

1. **Authentication and IAM**:
   - Authentication is managed through Amazon Cognito User Pools.
   - The application does not store, transmit, or log citizen passwords.
   - API interactions with Amazon Bedrock and AWS AppSync utilize short-lived IAM credentials obtained via Cognito Identity Pools.

2. **Zero Hardcoded Secrets**:
   - The codebase contains zero long-lived AWS secret access keys, private keys, or API tokens.
   - Public client metadata (Cognito Pool IDs, AppSync endpoint URLs) in `lib/amplifyconfiguration.dart` are restricted by AWS IAM and Cognito auth policies.

3. **Citizen Data Protection**:
   - Citizen identity documents (Aadhaar, PAN, Voter ID) are scoped strictly to the authenticated user.
   - Local document caches and prompt identifiers are hashed to prevent cleartext exposure.
   - Guest sessions are restricted from invoking generative AI models or accessing user documents.

4. **Continuous Automated Scanning**:
   - **GitHub CodeQL**: Automated static analysis scans every push and pull request for code vulnerabilities in Java/Kotlin native code and GitHub Actions workflows.
   - **Dependabot**: Automated weekly dependency checks for Flutter packages (`pub`), Android Gradle dependencies (`gradle`), and GitHub Actions.
