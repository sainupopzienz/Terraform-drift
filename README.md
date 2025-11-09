# Terraform Drift Detection Demo

This repository demonstrates Infrastructure as Code with drift detection using Terraform and GitHub Actions.

## 🏗️ Infrastructure Components

- **VPC**: Custom VPC with public/private subnets
- **S3**: Encrypted bucket with versioning
- **EC2**: Web server instance with security group

## 🔄 Workflows

### 1. Terraform Deploy (`terraform.yml`)
- Triggers on push to `main` branch
- Checks for drift before deployment
- Blocks deployment if drift detected

### 2. Daily Drift Check (`drift-check.yml`)
- Runs daily at 9 AM
- Detects infrastructure drift
- Fails if manual changes detected

## 🚨 Monitoring Setup

- **Real-time alerts** for manual AWS Console/CLI changes
- **Email notifications** with user details and timestamps
- **Drift prevention** in deployment pipeline

## 🧪 Testing Drift Detection

### Step 1: Initial Deployment
```bash
# Push to main branch to trigger deployment
git add .
git commit -m "Initial infrastructure deployment"
git push origin main
```

### Step 2: Make Manual Changes
1. Go to AWS Console
2. Modify any resource (e.g., add tags to EC2 instance)
3. Check email for immediate drift alert

### Step 3: Test Drift Prevention
```bash
# Try to deploy - should fail due to drift
git add .
git commit -m "New changes"
git push origin main
```

### Step 4: Fix Drift
1. Update Terraform code to match manual changes
2. Deploy again - should succeed

## 📋 Setup Instructions

### 1. GitHub Secrets
Add these secrets to your repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 2. Update Variables
Edit `variables.tf`:
- Change `s3_bucket_name` to unique value
- Update `key_name` to your EC2 key pair

### 3. Deploy
Push to main branch to trigger deployment

## 🔍 Drift Detection Examples

**Manual changes that trigger alerts:**
- Adding/removing tags
- Changing security group rules
- Modifying instance types
- Creating/deleting resources

**Alert format:**
```
🚨 TERRAFORM DRIFT ALERT 🚨

⚠️ Manual change detected outside Terraform!

User: john.doe
Action: CreateTags
Service: ec2.amazonaws.com
Resource: i-1234567890abcdef0
Time: 2024-01-15T10:30:00Z
Region: us-east-1
Source IP: 203.0.113.12

❗ This change may cause Terraform drift.
💡 Please update your Terraform code to match this change.
```

## 🛠️ Troubleshooting

### Drift Detected
1. Check email alerts for specific changes
2. Update Terraform code to match reality
3. Run `terraform plan` to verify
4. Commit and push changes

### Workflow Failures
1. Check GitHub Actions logs
2. Verify AWS credentials
3. Ensure unique S3 bucket name
4. Check EC2 key pair exists

## 📁 Project Structure

```
├── .github/workflows/
│   ├── terraform.yml      # Main deployment workflow
│   └── drift-check.yml    # Daily drift detection
├── modules/
│   ├── vpc/              # VPC module
│   ├── s3/               # S3 module
│   └── ec2/              # EC2 module
├── main.tf               # Root module
├── variables.tf          # Input variables
├── outputs.tf            # Output values
└── backend.tf            # State backend config
```
