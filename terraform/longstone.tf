provider "rancher" {
  api_url = "http://{{ longstone_IP }}:8080"
}

resource "rancher_environment" "longstone" {
  name = "longstone"
  description = "EPIC.Longstone game server"
  orchestration = "cattle"
}

resource "rancher_registration_token" "longstone-node" {
  environment_id = "${rancher_environment.longstone.id}"
  name = "longstone-node"
  description = "longstone game server"
}

output "rancher_agent_command" {
  value = "${rancher_registration_token.longstone-node.command}"
}

resource "null_resource" "longstone-node-slave" {
  connection {
    host = "{{ longstone_IP }}"
    user = "mohero"
    agent = "true"
    timeout = "3m"
  }
  provisioner "remote-exec" {
    inline = "${replace(rancher_registration_token.longstone-node.command, "/sudo/", "")}"
  }
}


resource "rancher_stack" "KillingFloor2" {
  name = "KillingFloor2"
  description = "Killing Floor 2 dedicated server"
  environment_id = "${rancher_environment.longstone.id}"
  docker_compose = "${file("GameServers/KF2/docker-compose.yml")}"
  start_on_create = true
}

