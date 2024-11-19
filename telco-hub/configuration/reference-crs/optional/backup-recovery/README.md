# Backup and Recovery process CR are documented here

● In the environment an S3 bucket was created on the passive ACM
cluster dtibhub.
● Ideally you want an s3 endpoint that is external to both clusters or to
cross replicate the bucket between clusters, but for a lab test this is
suitable.
● The purpose of this s3 bucket is to be used as a backup storage location
for the multicluster-engine deployment of OADP
● Once created the bucket, access key, and secret key need to be
recorded.
● The s3 route will also be needed which can be retrieved with the step
below:
