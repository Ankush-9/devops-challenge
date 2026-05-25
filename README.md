## Overview : 
The NimbusKart FinOps Cost Janitor is a script designed to find and clean up forgotten AWS resources to keep cloud costs low. Instead of testing on a real AWS account, it uses LocalStack inside Docker to simulate AWS for free. The project uses Terraform to set up the infrastructure and a custom Bash script to check for unattached EBS volumes, stopped EC2 instances, and unused Elastic IPs. If it finds any wasteful resources, it logs them in a report. In a real development workflow, this script acts as a safety gate to stop deployment pipelines if anyone leaves messy infrastructure behind.

## How to run locally :
# 1. Clone the repository and open the folder
git clone https://github.com/Ankush-9/devops-challenge.git
cd devops-challenge
sh setup-env.sh(to install some dependencies)

# 2. Start LocalStack using Docker to simulate AWS locally
docker run --rm -d -p 4566:4566 --name localstack localstack/localstack

# 3. Install tflocal (a wrapper that makes Terraform talk to LocalStack)
pip install terraform-local

# 4. Go to the terraform folder, set it up, and build the infrastructure
cd terraform
tflocal init
tflocal apply -auto-approve

# 5. Go back to the main folder and give the script permission to run
cd ..
chmod +x ./janitor/janitor.sh

# Mode A: Run a safe scan (Dry-Run Mode) to find leaks without deleting them
./janitor/janitor.sh --dry-run

# Check the script's exit code (It will return 1 because leaks were found)
echo $?

# Mode B: Run active cleanup (Delete Mode) to remove unprotected leaks
./janitor/janitor.sh --delete

## Architecture :
┌────────────────────────────────────────────────────────────────────────┐
 │                        LOCAL MACHINE (macOS)                           │
 │                                                                        │
 │  ┌─────────────────┐       tflocal       ┌──────────────────────────┐  │
 │  │  Terraform IaC  ├────────────────────►│    LocalStack Container  │  │
 │  │  (Code Files)   │  (Deploys Mock AWS) │    (AWS API Simulator)   │  │
 │  └─────────────────┘                     │                          │  │
 │                                          │   • Unused Volumes       │  │
 │  ┌─────────────────┐       aws-cli       │   • Stopped Instances    │  │
 │  │  Janitor Script ├────────────────────►│   • Forgotten IPs        │  │
 │  │  (janitor.sh)   │   (Scans Assets)    └─────────────┬────────────┘  │
 │  └────────┬────────┘                                   │               │
 └───────────┼────────────────────────────────────────────┼───────────────┘
             │                                            │
             ▼ (Creates Local Files)                      ▼ (Remediation)
     ┌───────────────┬───────────────┐            ┌───────────────┐
     │  report.json  │   report.md   │            │ Deletes Leaks │
     └───────────────┴───────────────┘            └───────────────┘

## ## Decisions & deviations :
Smart Pipeline Stopping: Added logic so that if the script runs in --dry-run mode and finds leaks, it exits with code 1. This tells a CI/CD pipeline that the environment is messy and stops the deployment automatically.
Strict Deletion Safety Rails: Programmed the script to check for a Protected=true tag or missing ownership tags before touching a resource, ensuring critical assets are never deleted by accident.

## Trade-offs :
Testing on a Real AWS Account: Move past the local Docker simulation to run and test this setup inside a real personal AWS account. This would allow me to check actual network speeds, live IAM permissions, and true AWS API responses.
Visual Cost Dashboards: Create a way to automatically send the generated report.json data to visualization tools like Grafana or Datadog so teams can track cost waste trends over time.

## AI usage disclosure :
Known Limitations:
•LocalStack Version Pinning: The project is configured to use the free tier of LocalStack. The latest versions of the official LocalStack image sometimes throw a licensing error (Error 55) by trying to activate paid Pro features.
•Mock Credentials: To make the project easy to run locally right away, it uses LocalStack’s default region configurations and dummy security keys.
•Local Machine Testing Only: The entire project is built and tested for local computer workstations using Docker. It has not been deployed to a live corporate production cloud network.
AI Usage Disclosure:
•Documentation & Format Help: I used an AI assistant to fix path issues on macOS, make sure my JSON output format exactly matched the required assignment template, and organize this README file.
•Janitor Script Logic: As an entry-level engineer, I am still learning how to write advanced data-filtering logic in Bash. I used AI to help structure the conditional loops in the script so the output matches the required format perfectly.
•Terraform Boilerplate Setup: The initial AWS provider blocks for LocalStack were based on AI templates. This helped add necessary default settings like skip_credentials_validation and skip_metadata_api_check so Terraform could talk to Docker smoothly.
•Manual Terraform Coding: I wrote all the core Terraform infrastructure files (main.tf, variables.tf, etc.) by hand without AI generation. I did this to make sure specific security constraints—like restricting SSH access—were configured correctly. Relying entirely on AI for infrastructure code can lead to over-engineered or fake configurations, so I preferred writing it myself to stay in control.
•Troubleshooting Local Environments: Setting up a simulated cloud environment on my Mac was tricky. AI helped me read error logs to get past environment blocks quickly.
•Problem Solving Example (Error 55): When initializing the LocalStack container, it failed with Error 55. The AI suggested a complex set of local configuration rewrites. However, by reading the error logs myself, I suspected a version mismatch. I checked online developer forums, confirmed that the latest LocalStack image had a bug that caused activation errors on the free tier, and ignored the AI's complicated advice. Instead, I simply rolled back the Docker image tag to a known stable version, which fixed the issue immediately.
