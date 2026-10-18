# Deploy Civic Voice Web build to AWS Amplify Hosting
$APP_ID = "d2o5i1x3ygcmoz"
$BRANCH = "main"
$REGION = "ap-south-1"
$ZIP_PATH = "build\artifacts.zip"

Write-Host "Creating Amplify Deployment for App: $APP_ID, Branch: $BRANCH..." -ForegroundColor Cyan
$rawJson = (aws amplify create-deployment --app-id $APP_ID --branch-name $BRANCH --region $REGION) | Out-String
$deploy = $rawJson | ConvertFrom-Json

$jobId = $deploy.jobId
$uploadUrl = $deploy.zipUploadUrl

Write-Host "Deployment Job ID: $jobId" -ForegroundColor Yellow
Write-Host "Uploading artifacts ($ZIP_PATH) to S3 via curl..." -ForegroundColor Cyan

& curl.exe -s -S -X PUT -T $ZIP_PATH -H "Content-Type: application/zip" $uploadUrl

Write-Host "Starting Amplify Deployment..." -ForegroundColor Cyan
aws amplify start-deployment --app-id $APP_ID --branch-name $BRANCH --job-id $jobId --region $REGION

Write-Host "Monitoring deployment status..." -ForegroundColor Green
for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Seconds 5
    $jobInfo = (aws amplify get-job --app-id $APP_ID --branch-name $BRANCH --job-id $jobId --region $REGION | Out-String | ConvertFrom-Json)
    $status = $jobInfo.job.summary.status
    Write-Host "Current Status ($i): $status"
    if ($status -eq "SUCCEED") {
        Write-Host "Deployment SUCCEEDED! Live URL: https://$BRANCH.$APP_ID.amplifyapp.com" -ForegroundColor Green
        break
    }
    if ($status -eq "FAILED" -or $status -eq "CANCELLED") {
        Write-Host "Deployment $status!" -ForegroundColor Red
        break
    }
}
