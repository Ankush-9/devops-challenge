#!/bin/bash
# FinOps Cost Constants for NimbusKart Janitor Evaluation.
# Region Baseline: us-east-1

# 1. EBS gp3 Volume Pricing
# Source: AWS EBS Pricing Page (https://aws.amazon.com/ebs/pricing/)
# Standard price for General Purpose SSD (gp3) volumes is $0.08 per GB-month.
EBS_GP3_PER_GB_MONTH="0.08"

# 2. EC2 t3.micro Compute Pricing
# Source: AWS EC2 On-Demand Pricing (https://aws.amazon.com/ec2/pricing/on-demand/)
# Linux t3.micro costs $0.0104 per hour. Monthly cost = $0.0104 * 730 hours.
EC2_T3_MICRO_MONTHLY="7.59"

# 3. Unattached Elastic IP (EIP) Pricing
# Source: AWS VPC Pricing (https://aws.amazon.com/vpc/pricing/)
# AWS charges $0.005 per hour for an allocated Elastic IP address that is not 
# associated with a running instance. Monthly cost = $0.005 * 730 hours.
UNATTACHED_EIP_MONTHLY="3.65"
