•Multi-cloud reality : Right now, our script only talks to AWS. If NimbusKart wants to add GCP next quarter, we don't want to rewrite our whole project.
		       The Fetchers (Adapters): These are small helper scripts. aws-fetch.sh runs AWS commands to get a list of volumes. Next quarter, we just write a gcp-fetch.sh to get a list of GCP disks.			      The Core Engine (janitor.sh): This script doesn't care about AWS or GCP. It just takes the list from the fetcher, checks if things are missing tags, checks if they are Protected=true, and writes the final report.json.

•Permissions : For --dry-run Mode (Read-Only / Safe)
	       Search for and attach this single policy:AmazonEC2ReadOnlyAccess
	       For --delete Mode (Destructive / Active Cleanup)
	       Search for and attach this policy:AmazonEC2FullAccess (To let it find and delete the unattached volumes)	

•Safety net : If you let a script automatically delete things without a safety net, it will eventually cause an outage. Here are two real ways that could happen and how we prevent it:
	      The Maintenance Trap: A developer might temporarily detach a hard drive (volume) to do a manual backup or fix a bug. If the script runs at that exact second, it sees it as "unattached" and deletes it, destroying real data.A 14-Day Waiting Period. The script shouldn't delete a volume the first time it sees it unattached. It must wait until the volume has been sitting lonely for 14 days straight.
	      The Weekend Shut Down: A developer might turn off an EC2 server over the weekend to save money, leaving the database drive unattached. The script might think it's junk and delete it.The Protected Tag. If a developer adds the tag Protected=true to their resource, the script completely skips it and will never delete it

•Observability : To prove to the team that the Janitor is working properly, it saves 3 simple numbers (metrics) into a local log file (/var/log/janitor.log) every time it runs:
		 TotalOrphanedResources (Count): How many unused volumes did we find.Alert the team if this is over 100. It means developers are leaving too much trash behind.
		 TotalMonthlyWasteUSD (Money): How much money are these unused volumes costing us.Alert FinOps if waste goes over $1,000/month so they can authorize a cleanup.
		 JanitorExecutionStatus (Success/Fail): A 0 means the script ran perfectly. A 1 means it crashed.Alert immediately if it equals 1. If the script crashes, we are blind to cloud waste.

•What I did not build : I kept my script simple on purpose so I could focus on making the JSON report format exactly right.I intentionally kept this project focused only on local EBS volumes. I left out other resources like stopped EC2 instances, old snapshots, or unused Elastic IPs. I did this on purpose because every different cloud resource has its own tricky rules for what makes it "waste" vs "intentional". Instead of writing a massive, complicated script that might accidentally delete the wrong thing, I focused on making a simple, bulletproof foundation for one resource type first.	
