resource "ibm_resource_instance" "restoreCOSInstance" {
  name              = "restorecosinstance"
  resource_group_id = ibm_resource_group.resource_group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "restoreBucket" {
  bucket_name          = "restorebucket"
  resource_instance_id = ibm_resource_instance.restoreCOSInstance.id
  region_location      = var.region
  storage_class        = "standard"
}

resource "ibm_resource_key" "resourceKey" {
  name                 = "restore-bucket-key"
  resource_instance_id = ibm_resource_instance.restoreCOSInstance.id
  parameters           = {"HMAC":true}
  role                 = "Manager"
}

output "bucket_credentials" {
  value = ibm_resource_key.resourceKey.credentials
  sensitive = true
  
}

output "bucket_name" {
  value = ibm_cos_bucket.restoreBucket.bucket_name
}