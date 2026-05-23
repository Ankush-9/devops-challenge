#!/bin/bash

# Fetch volumes
VOLUMES=$(aws ec2 describe-volumes --endpoint-url=http://localhost:4566 --filters Name=status,Values=available --output json)

# Use jq to map the AWS response to your required schema
echo "$VOLUMES" | jq -n \
  --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson volumes "$VOLUMES" \
  '{
    scan_timestamp: $timestamp,
    account_id: "000000000000",
    region: "us-east-1",
    summary: {
      total_orphans: ($volumes.Volumes | length),
      estimated_monthly_waste_usd: ($volumes.Volumes | map(.Size * 0.08) | add)
    },
    findings: ($volumes.Volumes | map({
      resource_id: .VolumeId,
      resource_type: "ebs_volume",
      reason: "unattached",
      age_days: 0,
      estimated_monthly_cost_usd: (.Size * 0.08),
      tags: .Tags,
      suggested_action: "delete",
      safe_to_auto_delete: false
    }))
  }' > report.json
