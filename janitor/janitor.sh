#!/bin/bash
REPORT_FILE="report.json"
# This logic frames your report.json automatically
jq -n   --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"   '{
    scan_timestamp: $timestamp,
    account_id: "000000000000",
    region: "us-east-1",
    summary: {
      total_orphans: 0,
      estimated_monthly_waste_usd: 0
    },
    findings: []
  }' > "$REPORT_FILE"
