resource "ibm_database" "esSource" {
  resource_group_id = ibm_resource_group.resource_group.id
  name                                 = "elastic-source"
  service                              = "databases-for-elasticsearch"
  plan                                 = "standard"
  location                             = "eu-gb"
  tags                                 = []
  adminpassword = var.elastic_password
}

resource "ibm_database" "esTarget" {
  resource_group_id = ibm_resource_group.resource_group.id
  name                                 = "elastic-target"
  service                              = "databases-for-elasticsearch"
  plan                                 = "standard"
  location                             = "eu-gb"
  tags                                 = []
  adminpassword = var.elastic_password
}

output "sourceUrl" {
  value = ibm_database.esSource.connectionstrings[0].composed
}

output "sourcePassword" {
  value = var.elastic_password
}

output "sourceCert" {
  value = ibm_database.esSource.connectionstrings[0].certbase64
}

output "targetUrl" {
  value = ibm_database.esTarget.connectionstrings[0].composed
}

output "targetPassword" {
  value = var.elastic_password
}

output "targetCert" {
  value = ibm_database.esTarget.connectionstrings[0].certbase64
}

output "sourceHost" {
  value = ibm_database.esSource.connectionstrings[0].hosts[0].hostname
}

output "sourcePort" {
  value = ibm_database.esSource.connectionstrings[0].hosts[0].port
}

output "targetHost" {
  value = ibm_database.esTarget.connectionstrings[0].hosts[0].hostname
}

output "targetPort" {
  value = ibm_database.esTarget.connectionstrings[0].hosts[0].port
}