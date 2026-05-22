#!/bin/bash

echo "Starting FinOps health scan..."

# Use the full path to the healthy AWS CLI
/usr/local/bin/aws ec2 describe-volumes \
    --endpoint-url=http://localhost:4566 \
    --filters Name=status,Values=available \
    --query 'Volumes[*].{ID:VolumeId,Size:Size,AZ:AvailabilityZone}' \
    --output json > report.json

echo "Scan complete. Report generated in report.json"
cat report.json
