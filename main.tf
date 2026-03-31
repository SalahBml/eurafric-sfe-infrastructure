terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

provider "null" {}

resource "null_resource" "multipass_cluster" {
  # 1. Iterate over the dictionary
  for_each = var.vms

  triggers = {
    # 2. Build the name using the dictionary key
    vm_name = "${var.tenant_name}-${lower(var.env_name)}-${var.project_code}-${each.key}"
    vm_flavor = "${each.value.flavor}"
  }

  provisioner "local-exec" {
    # 3. Look up the hardware specs dynamically based on the requested flavor
    command = "multipass.exe launch ${var.os_image} --name ${self.triggers.vm_name} --cpus ${var.flavor_map[each.value.flavor].cpu} --memory ${var.flavor_map[each.value.flavor].ram} --disk ${var.flavor_map[each.value.flavor].disk} > /dev/null 2>&1"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "multipass.exe delete ${self.triggers.vm_name} && multipass.exe purge"
  }

  provisioner "local-exec" {
    command = "multipass.exe exec ${self.triggers.vm_name} -- bash -c \"grep -q 'salah@SaLaH' /home/ubuntu/.ssh/authorized_keys || echo '${var.ssh_public_key}' >> /home/ubuntu/.ssh/authorized_keys\""
  }
}
	
resource "local_file" "mock_vsphere_tags" {
  filename = "${path.module}/mock_vcenter_tags.json"
  content  = jsonencode({
    for key, vm in var.vms : "${var.tenant_name}-${lower(var.env_name)}-${var.project_code}-${key}" => vm.tags
  })
}

output "vm_names" {
  value = [for vm in null_resource.multipass_cluster : vm.triggers.vm_name]
}
