# Submission — DevOps Engineer Assignment

**Candidate name:Ankush Walia**

**Email:waliaankush0420@gmail.com**

**Date submitted:24-05-2026**

**Hours spent (approximate):4-5(over a span of 2-3 days)**

## Deliverables checklist
- [1] Part A: Terraform code under /terraform applies cleanly on LocalStack
- [1] Part A: `terraform validate` and `terraform fmt -check` both pass
- [1] Part B: Janitor script runs in --dry-run mode and produces report.json
- [ ] Part B: GitHub Actions workflow runs green on a fresh PR
- [1] Part B: --delete mode respects Protected=true tag
- [1] Part C: DESIGN.md is present and within 2 pages
- [1] Walkthrough video link below is accessible (unlisted is fine)

## Walkthrough video
Link (Loom): https://www.loom.com/share/f03c2d141c974d24822c8f9651d58100
Length: max 5 minutes

## Sample report
Path to a sample report.json produced by your script:samples/report.example.json

## Known limitations
• LocalStack Version Pinning: The script and infrastructure are designed to run on the free, open-source community tier of LocalStack. The latest versions of the LocalStack image occasionally throw an activation error (Error 55) by trying to pull Pro features
•Hardcoded Region & Mock Credentials: To ensure ease of running locally, the project relies on LocalStack’s default region (ap-south-1) and mock credentials.
•Local Machine Scope Only: The entire project is configured and tested exclusively for a local workstation environment using LocalStack and Docker. It has not been deployed to, or tested against, a live production AWS cloud environment.

## AI usage disclosure
I utilized an AI assistant to help debug macOS library path errors, ensure the JSON output structure strictly adhered to the assignment schema, and structure the repository documentation
Being a fresher,I am not as proficient enough to design the janitor(health check setup)using the bash,I have used Ai tools to design and implement the janitor in such a way that it yields to the required output format.
Next up,the boilerplate code has been taken from Gemini,The boilerplate gave fields like skip_credentials_validation,skip_metadata_api_check,skip_requesting_account_id and so on which are to be configured as default parameters.
I manually authored all Terraform configuration files (main.tf, variables.tf, modules/) without AI generation. I chose to do this because the infrastructure requirements had specific security constraints (like the SSH rule restrictions) that I needed to be 100% certain were implemented correctly. Relying on AI to generate infrastructure-as-code often results in "hallucinated" or over-engineered resources that create unnecessary complexity; I preferred to write this layer manually to maintain full control over the cloud environment.
Logic Refinement: Developing the complex jq filters within janitor.sh to transform raw API output into the required JSON schema.
Ai has also helped me in achieving the required directory structure for the project.
Being a fresher i was unaware about the janitor logic and how bash can be used to experience such complex healthcheck models,Using Ai tools it was made achievable to implement such complex logic.
I have hands on experience with AWS resources,jenkins and so on which was gained using services virtuially on my machine i.e. using VM like Amazon Linux,ubuntu,etc. So,I had to setup the mock environment on my local machine which was a bit tidious task for me but using Ai tools it was made so easy and smooth to implement the work-space here itself on my mac.
During the setup phase, I encountered 'Error 55' while initializing LocalStack container. I used AI to analyze the error logs, which suggested several potential causes. While the AI initially proposed a complex configuration change, my analysis of the logs suggested a version mismatch. I verified this by cross-referencing the error with community forums and the LocalStack container changelog, confirming that the latest version introduced a breaking change. I opted to ignore the AI's complex configuration suggestion and instead rolled back to a stable version, demonstrating the importance of validating AI suggestions against official documentation.
