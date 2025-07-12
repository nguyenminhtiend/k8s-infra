#!/bin/bash

# LocalStack initialization script
# This script sets up initial resources and configurations for local testing

echo "🔧 Initializing LocalStack for Terraform testing..."

# Set AWS CLI to use LocalStack endpoint
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=ap-southeast-1

# Wait for LocalStack to be ready
echo "⏳ Waiting for LocalStack to be ready..."
until curl -s http://localhost:4566/_localstack/health | grep -q "running"; do
  echo "Waiting for LocalStack..."
  sleep 2
done

echo "✅ LocalStack is ready!"

# Create S3 bucket for Terraform state (if needed)
echo "📦 Creating S3 bucket for Terraform state..."
aws --endpoint-url=http://localhost:4566 s3 mb s3://terraform-state-local || echo "Bucket may already exist"

# Enable versioning on the state bucket
aws --endpoint-url=http://localhost:4566 s3api put-bucket-versioning \
  --bucket terraform-state-local \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking (optional)
echo "🔒 Creating DynamoDB table for state locking..."
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions \
    AttributeName=LockID,AttributeType=S \
  --key-schema \
    AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput \
    ReadCapacityUnits=5,WriteCapacityUnits=5 \
  || echo "Table may already exist"

echo "🎉 LocalStack initialization complete!"
echo "💡 LocalStack is running at: http://localhost:4566"
echo "📊 LocalStack dashboard: http://localhost:4566/_localstack/cockpit"