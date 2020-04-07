# Automated Installation of PTFE within a TLZ shared services account

This repo is based upon Hashicorp's own https://github.com/hashicorp/private-terraform-enterprise but has been changed extensively to fit Eventbrite needs and to be part of the broader Terraform Landing Zone project.

It contains Terraform configurations that can do [automated installations](https://www.terraform.io/docs/enterprise/private/automating-the-installer.html) of [Private Terraform Enterprise](https://www.terraform.io/docs/enterprise/private/index.html) (PTFE) in an AWS Terraform Landing Zone shared services account.

## Preliminary steps
Before you can proceed with the installation of PTFE you must have bootstrapped your TLZ shared services account with a VPC and at least one private and one public subnets.

## Explanation of the Two Stage Deployment Model
PTFE is deployed in two stages, each of which uses the open source flavor of Terraform:
1. Will instantiate a private S3 bucket to which the PTFE software, license, and settings files can be uploaded and a KMS key used to encrypt the bucket.
2. Will then deploy the external PostgreSQL database and S3 bucket used in the [Production - External Services](https://www.terraform.io/docs/enterprise/private/preflight-installer.html#operational-mode-decision) operational mode of PTFE along with the primary and optional secondary EC2 instances that will run PTFE, an Application Load Balancer and associated resources, and some required IAM resources.
de in stage 2.

## Description of the User Data Script that Installs PTFE
During stage 2, a user data script generated from [user-data-ubuntu-online.tpl](./examples/aws/user-data-ubuntu-online.tpl) is run on each instance to install PTFE on it and to initialize the PostgreSQL database and S3 bucket if that has not already been done. The online scripts also install Docker. Since the user data script is templated, all relevant PTFE settings, whether entered in the terraform.tfvars file or computed by Terraform, are passed into it before it is run when the instances are deployed.

The script does the following things:
1. It determines the private IP, private DNS, and public IP (in public networks) of each EC2 instance being deployed to run PTFE.
2. It writes out the replicated.conf, ptfe-settings.json, and create_schemas.sql files.

At this point given that we are performing an [online](https://www.terraform.io/docs/enterprise/private/install-installer.html#run-the-installer-online) installation, the script does the following:
1. It installs the aws CLI and uses it to retrieve the PTFE license file from the PTFE source bucket.
2. It sets SELinux to permissive mode (except on RHEL).
3. It installs the psql utility and connects to the PostgreSQL database in order to create the three schemas needed by PTFE.
4. It downloads the PTFE installer using curl and then runs it to install both Docker and PTFE.

The installer uses the replicated.conf, ptfe-settings.json, create_schemas.sql, and ptfe-license.rli files that the script previously wrote to disk.

The script then enters a loop, testing the availability of the PTFE app with a curl command until it is ready. Finally, the script uses the TFE API to create the first site admin user, a TFE API token for this user, and the first organization. This leverages the [Initial Admin Creation Token](https://www.terraform.io/docs/enterprise/private/automating-initial-user.html) (IACT). At this point, the generated API token could be used to automate additional PTFE configuration if desired.



WORK IN PROGRESS