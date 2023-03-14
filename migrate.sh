
#create different snapshot names by adding a timestamp

timestamp=`date +%s`
snapshot_name="snapshot_${timestamp}"

#echo $snapshot_name

#get db and s3 parameters

source_username=admin
source_password=`cat config.json | jq -r .sourcePassword.value`
source_endpoint=`cat config.json | jq -r .sourceHost.value`
source_port=`cat config.json | jq -r .sourcePort.value`
#echo $source_password
#echo $source_endpoint
#echo $source_port

target_username=admin
target_password=`cat config.json | jq -r .targetPassword.value`
target_endpoint=`cat config.json | jq -r .targetHost.value`
target_port=`cat config.json | jq -r .targetPort.value`
#echo $target_password
#echo $target_endpoint
#echo $target_port

storage_service_endpoint=s3.eu-gb.cloud-object-storage.appdomain.cloud
bucket_name=`cat config.json | jq -r .bucket_name.value`
access_key=`cat config.json | jq -r '.bucket_credentials.value["cos_hmac_keys.access_key_id"]'`
secret_key=`cat config.json | jq -r '.bucket_credentials.value["cos_hmac_keys.secret_access_key"]'`
path_to_snapshot_folder=elastic_search/deployment-1/migration
#echo $bucket_name
#echo $access_key
#echo $secret_key


# Mount S3/COS bucket on source deployment 

echo "\n setting up bucket on source elastic"

curl -kH 'Content-Type: application/json' -sS -XPOST \
"https://${source_username}:${source_password}@${source_endpoint}:${source_port}/_snapshot/migration" \
-d '{
  "type": "s3",
  "settings": {
    "bucket": "'"${bucket_name}"'",
    "endpoint": "'"${storage_service_endpoint}"'",
    "base_path": "'"${path_to_snapshot_folder}"'",
    "access_key": "'"${access_key}"'",
    "secret_key": "'"${secret_key}"'"
  }
}'


# Mount S3/COS bucket on Databases for Elasticsearch

echo "\n setting up bucket on target elastic"

#export CURL_CA_BUNDLE=target.cert
curl -kH 'Content-Type: application/json' -sS -XPOST \
"https://${target_username}:${target_password}@${target_endpoint}:${target_port}/_snapshot/migration" \
-d '{
  "type": "s3",
  "settings": {
    "readonly": true,
    "endpoint": "'"${storage_service_endpoint}"'",
    "bucket": "'"${bucket_name}"'",
    "base_path": "'"${path_to_snapshot_folder}"'",
    "access_key": "'"${access_key}"'",
    "secret_key": "'"${secret_key}"'"
  }
}'

echo "\n Perform 1st snapshot on source deployment"
curl -ksS -XPUT \
 "https://${source_username}:${source_password}@${source_endpoint}:${source_port}/_snapshot/migration/${snapshot_name}?wait_for_completion=true"

echo "\n Close indices on target"
# # Close all indices on target so we can perform the restore on top of it, without touching the icd-auth index, which is protected by ICD

curl -ksS "https://${target_username}:${target_password}@${target_endpoint}:${target_port}/_cat/indices/?h=index" | \
grep -v -e '^icd-auth$' | \
while read index; do
  echo "closing index $index"
  curl -ksS -XPOST "https://${target_username}:${target_password}@${target_endpoint}:${target_port}/$index/_close"
done

echo "\n Do first restore on target"

curl -H 'Content-Type: application/json' -ksS -XPOST \
"https://${target_username}:${target_password}@${target_endpoint}:${target_port}/_snapshot/migration/${snapshot_name}/_restore?wait_for_completion=true" \
-d '{"include_global_state": false, "indices":["-icd-auth"]}'


echo "\n Re-open all indices in target just in case some were not re-opened during the latest restore"
curl -ksS "https://${target_username}:${target_password}@${target_endpoint}:${target_port}/_cat/indices/?h=index" | \
grep -v -e '^icd-auth$' | \
while read index; do
  echo "reopening index $index"
  curl -ksS -XPOST "https://${target_username}:${target_password}@${target_endpoint}:${target_port}/$index/_open"
done

# You can run this script as many times as required.
# Snapsshots are incremental
# Finally, stop writes to the source, take a final snapshot and restore it to the target
# All your data is now in the target and you can point your applications to the target db