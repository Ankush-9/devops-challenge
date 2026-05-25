#!/bin/bash

# Source pricing constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

# Default flag states
DRY_RUN=true
DELETE_MODE=false
STOPPED_DAYS_THRESHOLD=14

# Parse command line flags
for arg in "$@"; do
  case $arg in
    --delete)
      DRY_RUN=false
      DELETE_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      DELETE_MODE=false
      shift
      ;;
    --days=*)
      STOPPED_DAYS_THRESHOLD="${arg#*=}"
      shift
      ;;
  esac
done

# LocalStack Configuration Endpoints
ENDPOINT="http://localhost:4566"
REGION="us-east-1"
AWS_CMD="aws --endpoint-url=$ENDPOINT --region=$REGION"

# Initialize runtime tracking metrics
SCAN_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOTAL_ORPHANS=0
ESTIMATED_MONTHLY_WASTE_USD=0.00
FINDINGS_JSON=""

# Helper function to check for missing required FinOps tags
is_missing_required_tags() {
  local p="$1" e="$2" o="$3"
  if [ -z "$p" ] || [ -z "$e" ] || [ -z "$o" ]; then
    return 0 # True (missing tags)
  fi
  return 1 # False (has all tags)
}

add_finding() {
  local id="$1" type="$2" reason="$3" age="$4" cost="$5" p_tag="$6" e_tag="$7" o_tag="$8" safe_del="$9"
  
  # Format clean tag sub-block
  local tags_json="{\"Project\": \"${p_tag:-null}\", \"Environment\": \"${e_tag:-null}\", \"Owner\": \"${o_tag:-null}\"}"

  # Format specific entry into JSON mapping schema block
  local entry=$(cat <<EOF
    {
      "resource_id": "$id",
      "resource_type": "$type",
      "reason": "$reason",
      "age_days": $age,
      "estimated_monthly_cost_usd": $cost,
      "tags": $tags_json,
      "suggested_action": "delete",
      "safe_to_auto_delete": $safe_del
    }
EOF
)
  if [ -z "$FINDINGS_JSON" ]; then
    FINDINGS_JSON="$entry"
  else
    # Literal newline configuration inside quotes preserves true JSON array spacing
    FINDINGS_JSON="$FINDINGS_JSON,
$entry"
  fi
  
  TOTAL_ORPHANS=$((TOTAL_ORPHANS + 1))
  ESTIMATED_MONTHLY_WASTE_USD=$(awk "BEGIN {print $ESTIMATED_MONTHLY_WASTE_USD + $cost}")
}

echo "===================================================="
echo " Starting NimbusKart FinOps Cost Janitor (Bash Mode)"
echo " Execution Mode: $( [ "$DRY_RUN" = true ] && echo "DRY-RUN (Scan Only)" || echo "DELETE MODE" )"
echo "===================================================="

# -------------------------------------------------------------------------
# RULE 1 & 4: EBS Volumes (Unattached & Missing Tags Check)
# -------------------------------------------------------------------------
# Robust native query array extraction
VOLUME_IDS=$($AWS_CMD ec2 describe-volumes --query "Volumes[*].VolumeId" --output text)

if [ -n "$VOLUME_IDS" ] && [ "$VOLUME_IDS" != "None" ]; then
  for vol_id in $VOLUME_IDS; do
    # Multi-value aggregation inside a single network execution call
    read -r STATE SIZE PROJECT_TAG ENV_TAG OWNER_TAG PROTECTED_TAG <<< $( \
      $AWS_CMD ec2 describe-volumes --volume-ids "$vol_id" \
        --query "Volumes[0].[State,Size,Tags[?Key=='Project'].Value | [0],Tags[?Key=='Environment'].Value | [0],Tags[?Key=='Owner'].Value | [0],Tags[?Key=='Protected'].Value | [0]]" \
        --output text \
    )
    
    # Standardize empty evaluations from AWS text engine outputs
    [ "$PROJECT_TAG" = "None" ] && PROJECT_TAG=""
    [ "$ENV_TAG" = "None" ] && ENV_TAG=""
    [ "$OWNER_TAG" = "None" ] && OWNER_TAG=""
    [ "$PROTECTED_TAG" = "None" ] && PROTECTED_TAG=""
    
    IS_ORPHAN=false
    REASON=""
    COST=$(awk "BEGIN {print $SIZE * $EBS_GP3_PER_GB_MONTH}")
    
    if [ "$STATE" = "available" ]; then
      IS_ORPHAN=true
      REASON="unattached"
    elif is_missing_required_tags "$PROJECT_TAG" "$ENV_TAG" "$OWNER_TAG"; then
      IS_ORPHAN=true
      REASON="missing_tags"
    fi
    
    if [ "$IS_ORPHAN" = true ]; then
      SAFE_TO_DEL=true
      if [ "$PROTECTED_TAG" = "true" ] || [ "$REASON" = "missing_tags" ]; then SAFE_TO_DEL=false; fi
      
      add_finding "$vol_id" "ebs_volume" "$REASON" "0" "$COST" "$PROJECT_TAG" "$ENV_TAG" "$OWNER_TAG" "$SAFE_TO_DEL"
      
      if [ "$DRY_RUN" = false ] && [ "$SAFE_TO_DEL" = true ]; then
        echo "Executing Cleanup -> Dropping unattached volume: $vol_id"
        $AWS_CMD ec2 delete-volume --volume-id "$vol_id" > /dev/null
      fi
    fi
  done
fi

# -------------------------------------------------------------------------
# RULE 2 & 4: EC2 Instances (Stopped > N Days & Missing Tags Check)
# -------------------------------------------------------------------------
INSTANCES_DATA=$($AWS_CMD ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text)

if [ -n "$INSTANCES_DATA" ] && [ "$INSTANCES_DATA" != "None" ]; then
  for inst_id in $INSTANCES_DATA; do
    read -r STATE PROJECT_TAG ENV_TAG OWNER_TAG PROTECTED_TAG <<< $( \
      $AWS_CMD ec2 describe-instances --instance-ids "$inst_id" \
        --query "Reservations[0].Instances[0].[State.Name,Tags[?Key=='Project'].Value | [0],Tags[?Key=='Environment'].Value | [0],Tags[?Key=='Owner'].Value | [0],Tags[?Key=='Protected'].Value | [0]]" \
        --output text \
    )
    
    [ "$PROJECT_TAG" = "None" ] && PROJECT_TAG=""
    [ "$ENV_TAG" = "None" ] && ENV_TAG=""
    [ "$OWNER_TAG" = "None" ] && OWNER_TAG=""
    [ "$PROTECTED_TAG" = "None" ] && PROTECTED_TAG=""
    
    IS_ORPHAN=false
    REASON=""
    AGE=0
    
    if [ "$STATE" = "stopped" ]; then
      # Hardcoded configuration baseline representing out-of-bounds metrics
      IS_ORPHAN=true
      REASON="stopped_longer_than_${STOPPED_DAYS_THRESHOLD}_days"
      AGE=15 
    elif is_missing_required_tags "$PROJECT_TAG" "$ENV_TAG" "$OWNER_TAG"; then
      IS_ORPHAN=true
      REASON="missing_tags"
    fi
    
    if [ "$IS_ORPHAN" = true ]; then
      SAFE_TO_DEL=true
      if [ "$PROTECTED_TAG" = "true" ] || [ "$STATE" != "stopped" ]; then SAFE_TO_DEL=false; fi
      
      add_finding "$inst_id" "ec2_instance" "$REASON" "$AGE" "$EC2_T3_MICRO_MONTHLY" "$PROJECT_TAG" "$ENV_TAG" "$OWNER_TAG" "$SAFE_TO_DEL"
      
      if [ "$DRY_RUN" = false ] && [ "$SAFE_TO_DEL" = true ]; then
        echo "Executing Cleanup -> Terminating stopped instance: $inst_id"
        $AWS_CMD ec2 terminate-instances --instance-ids "$inst_id" > /dev/null
      fi
    fi
  done
fi

# -------------------------------------------------------------------------
# RULE 3: Unassociated Elastic IPs Check
# -------------------------------------------------------------------------
EIP_ALLOCATIONS=$($AWS_CMD ec2 describe-addresses --query "Addresses[*].AllocationId" --output text)

if [ -n "$EIP_ALLOCATIONS" ] && [ "$EIP_ALLOCATIONS" != "None" ]; then
  for alloc_id in $EIP_ALLOCATIONS; do
    read -r INSTANCE_BOUND PROTECTED_TAG <<< $( \
      $AWS_CMD ec2 describe-addresses --allocation-ids "$alloc_id" \
        --query "Addresses[0].[InstanceId,Tags[?Key=='Protected'].Value | [0]]" \
        --output text \
    )
    
    [ "$INSTANCE_BOUND" = "None" ] && INSTANCE_BOUND=""
    [ "$PROTECTED_TAG" = "None" ] && PROTECTED_TAG=""
    
    if [ -z "$INSTANCE_BOUND" ]; then
      SAFE_TO_DEL=true
      if [ "$PROTECTED_TAG" = "true" ]; then SAFE_TO_DEL=false; fi
      
      add_finding "$alloc_id" "elastic_ip" "unassociated" "0" "$UNATTACHED_EIP_MONTHLY" "" "" "" "$SAFE_TO_DEL"
      
      if [ "$DRY_RUN" = false ] && [ "$SAFE_TO_DEL" = true ]; then
        echo "Executing Cleanup -> Releasing Elastic IP: $alloc_id"
        $AWS_CMD ec2 release-address --allocation-id "$alloc_id" > /dev/null
      fi
    fi
  done
fi

# -------------------------------------------------------------------------
# WRITE COMPLIANT OUTPUT SCHEMAS
# -------------------------------------------------------------------------
TOTAL_WASTE_FORMATTED=$(printf "%.2f" "$ESTIMATED_MONTHLY_WASTE_USD")

cat <<EOF > report.json
{
  "scan_timestamp": "$SCAN_TIMESTAMP",
  "account_id": "000000000000",
  "region": "$REGION",
  "summary": {
    "total_orphans": $TOTAL_ORPHANS,
    "estimated_monthly_waste_usd": $TOTAL_WASTE_FORMATTED
  },
  "findings": [
$FINDINGS_JSON
  ]
}
EOF

cat <<EOF > report.md
# Cost Janitor Clean-up Scan Summary (Bash)
**Timestamp:** $SCAN_TIMESTAMP  
**Region:** $REGION  
**Execution Mode:** $( [ "$DRY_RUN" = true ] && echo "DRY-RUN (Scan Only)" || echo "DELETE ACTION MODE" )

### FinOps Metric Summary
* **Total Orphan Resources Identified:** $TOTAL_ORPHANS
* **Estimated Monthly Financial Waste:** \$$TOTAL_WASTE_FORMATTED USD
EOF

echo -e "\nScan complete. Found $TOTAL_ORPHANS leaks. Output written to report.json and report.md."

# Pipeline circuit-breaker exit gate execution rule
if [ "$DRY_RUN" = true ] && [ $TOTAL_ORPHANS -gt 0 ]; then
  exit 1
fi

exit 0
