# SIEM Deployment - docker native way

Hi! This explains the deployment of SIEM to our customers

Follow steps bellow to deploy siem:

1. Create compliance tenant within duplo plan.
Go through documentation to create tenant (https://docs.duplocloud.com/docs/aws-user-guide/quick-start/step-2-tenant)

2. Create host with following configuration:
Name :             SIEM
AZ :               Automatic
Instance Type :    t3a.xlarge
Allocation Tag :   siem
Image ID :         docker-duplo-ohio-ubuntu22
Disc Size :        100

3. Once SIEM host is up and running, deploy services
 - opensearch
 - siem
 - dashboard
 
 as follow
  - Opensearch Service Deployment : 
