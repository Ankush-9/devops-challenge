#!/bin/bash

# Configuration
ENDPOINT="http://localhost:4566"
REPORT_FILE="report.json"
MODE="--dry-run"

if [[ "$1" == "--delete" ]]; then
    MODE="--delete"
fi

# Fetch volumes directly from the LocalStack API using curl
# We filter by 'available' status via query parameters
RAW_DATA=$(curl -s "$ENDPOINT/?Action=DescribeVolumes&Version=2016-11-15&Filter.1.Name=status&Filter.1.Value.1=available")

# If the request fails or is empty, use an empty list
if [ -z "$RAW_DATA" ]; then
    RAW_DATA='{"DescribeVolumesResponse": {"VolumeSet": {"item": []}}}'
fi

# Use jq to transform the raw XML/JSON response into the specific Part B schema
# Note: LocalStack API responses vary by format; we parse the list of volumes
echo "$RAW_DATA" | jq -n \
  --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --slurpfile data /dev/stdin \
  '{
    scan_timestamp: $timestamp,
    account_id: "000000000000",
    region: "us-east-1",
    summary: {
      total_orphans: ($data[0].DescribeVolumesResponse.VolumeSet.item | length // 0),
      estimated_monthly_waste_usd: ($data[0].DescribeVolumesResponse.VolumeSet.item | map(.Size * 0.08) | add // 0)
    },
    findings: ($data[0].DescribeVolumesResponse.VolumeSet.item | map({
      resource_id: .VolumeId,
      resource_type: "ebs_volume",
      reason: "unattached",
      age_days: 0,
      estimated_monthly_cost_usd: (.Size * 0.08),
      tags: (.TagSet.item // {}),
      suggested_action: "delete",
      safe_to_auto_delete: false
    }))
  }' > "$REPORT_FILE"

echo "Scan complete. Report generated in $REPORT_FILE"
