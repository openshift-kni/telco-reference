#
# Run this script on the Management (Hub) cluster that
# is performing ZTP of workload cluster, and where Kafka
# is installed.
#
# The script is being used to copy kafka secrets to the
# ztp-workload-policy namespace, since right now ACM is
# having issues to apply policies to the local cluster.
# Once the ACM issue is finxed, this script will be replaced
# with an ACM policy (pg-copy-local-secret.yaml). That policy
# still needs work.
#

# Create tmp directory
mkdir /tmp/kafka

# Extract the existing kafka certs
oc -n kafka-cluster get secret mgmt-kafka-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/kafka/ca-bundle.crt
oc -n kafka-cluster get secret mgmt-kafka-clients-ca -o jsonpath='{.data.ca\.key}' | base64 -d > /tmp/kafka/tls.key
oc -n kafka-cluster get secret mgmt-kafka-clients-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/kafka/tls.crt

# Create the secret in the ztp-workload-policy namespace
# Once its in that namespace an ACM policy can be used
# to copy it to the workload clusters
oc -n ztp-core-policies delete secret kafka-secret
oc -n ztp-core-policies create secret generic kafka-secret --from-file=/tmp/kafka/

# Delete tmp directory
rm -rf /tmp/kafka
