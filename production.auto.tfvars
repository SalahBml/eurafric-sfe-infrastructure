tenant_name  = "boa"
env_name     = "by"
project_code = "web"
os_image     = "file://C:/ubuntu/ubuntu-24.04-server-cloudimg-amd64.img" 

vms = {
  "0000" = { 
      flavor = "silver"
      tags = {
      "Environment"  = "Dev"
      "BackupPolicy" = "Bronze-Daily"
      "Owner"        = "Dev-Team"
	  }
}
