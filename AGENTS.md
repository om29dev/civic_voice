# Civic Voice (CVI) — Agent Knowledge & Hackathon Operations Guide

## 🏆 Hackathon Context: AWS Zero to Shipped
- **Event**: AWS Zero to Shipped Hackathon (September 18 – October 2, 2026)
- **Target Category**: `#social-good` (Focus: Digital equity, health & education schemes for underserved citizens in Bharat, eligible for AWS Social Impact Credits)
- **Target Lane**: `#community` (Civic empowerment for communities, open welfare discovery)
- **Ship Gate (Pass/Fail)**: Must have a live, publicly reachable application on AWS and documented proof of coding agent connecting to AWS.

## ☁️ AWS Cloud Architecture
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

## 🧠 Amazon Bedrock Foundation Models
- **Amazon Nova Micro** (`amazon.nova-micro-v1:0`): Ultra-low cost, sub-second latency for text conversation.
- **Amazon Nova Lite** (`amazon.nova-lite-v1:0`): Multimodal vision for document inspection & form auto-completion.
- **Meta Llama 3 8B Instruct** (`meta.llama3-8b-instruct-v1:0`): In-depth civic reasoning and multilingual analysis.

## 🛠️ Build & Deployment Runbook
1. **Target Platform**: Android Only (`android/`)
2. **Analyze Code**:
   ```powershell
   flutter analyze
   ```
3. **Build Android Release APK**:
   ```powershell
   flutter build apk --release
   ```
4. **Deploy APK & Showcase to AWS Distribution (Ship Gate)**:
   ```powershell
   # Upload APK to AWS S3 / Amplify distribution for judges to download and evaluate
   aws s3 cp build\app\outputs\flutter-apk\app-release.apk s3://civicvoicestorage71deb-dev/public/civicvoice.apk --acl public-read
   ```
