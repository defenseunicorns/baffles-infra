# Rename this file to <filename>.tfvars and fill in the values
# Run terraform command to specify using the tfvars file `terraform plan -var-file tf-state-backend.tfvars`
# Variables can also be set via environment variables

###########################################################
################## Global Settings ########################

region              = "us-east-1"    # target AWS region
region2             = "us-east-2"    # RDS backup target AWS region
account             = "950698127059" # target AWS account
name                = "baffles"      # project name
aws_profile         = "default"      # local AWS profile to be used for deployment
aws_admin_usernames = [""]           # list of users to be added to the AWS admin group
