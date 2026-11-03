# Civic Voice (CVI) - Agent Knowledge and Hackathon Operations Guide

## Hackathon Context: AWS Zero to Shipped
- **Event**: AWS Zero to Shipped Hackathon (September 18 - October 2, 2026)
- **Target Category**: `#social-good` (Focus: Digital equity, health and education schemes for underserved citizens in Bharat, eligible for AWS Social Impact Credits)
- **Target Lane**: `#community` (Civic empowerment for communities, open welfare discovery)
- **Ship Gate (Pass/Fail)**: Must have a live, publicly reachable application on AWS and documented proof of coding agent connecting to AWS.

## AWS Cloud Architecture
- **Primary AWS Region**: `ap-south-1` (Mumbai)
- **AI / Bedrock Region**: `us-east-1` (N. Virginia)
- **AWS Account ID**: `742435394268`
- **Amplify App ID**: `d2o5i1x3ygcmoz`
- **Hosting URL**: `https://main.d2o5i1x3ygcmoz.amplifyapp.com`
- **Cognito User Pool ID**: `ap-south-1_jXuQiKf9L`
- **Cognito Identity Pool ID**: `ap-south-1:b2b7786b-f8e2-47b9-b246-e87480016a8d`
- **Cognito Unauthenticated Role ARN**: `arn:aws:iam::742435394268:role/amplify-civicvoice-dev-71deb-unauthRole`
- **AppSync GraphQL Endpoint**: `https://672nmbmz2zgntmteqh7tpew4i4.appsync-api.ap-south-1.amazonaws.com/graphql`
- **S3 Document Vault Bucket**: `civicvoicestorage71deb-dev`

## Amazon Bedrock Foundation Models
- **Amazon Nova Micro** (`amazon.nova-micro-v1:0`): Ultra-low cost, sub-second latency for text conversation.
- **Amazon Nova Lite** (`amazon.nova-lite-v1:0`): Multimodal vision for document inspection and form auto-completion.
- **Meta Llama 3 8B Instruct** (`meta.llama3-8b-instruct-v1:0`): In-depth civic reasoning and multilingual analysis.

## Build and Deployment Runbook
1. **Target Platform**: Android Only (`android/`)
2. **Analyze Code**:
   ```powershell
   flutter analyze
   ```
3. **Build Android Release APK**:
   ```powershell
   flutter build apk --release
   ```
4. **CI/CD and Releases (GitHub Actions)**:
   - APK releases are automated via GitHub Actions (`.github/workflows/release.yml`) on git tag pushes. Release artifacts include `civicvoice-<tag>.apk` and `civicvoice-checksums.txt`.
   - Backend deployments are automated via GitHub Actions (`.github/workflows/amplify-backend.yml`) running headless `amplify push --yes` on backend changes or manual workflow dispatch.
