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
    - Navigate to `Docker` tab.
    - Select `services`.
    - Add new service with configuration as follows:
       - Name : opensearch
       - DockerImage: duplocloud/wazuh-indexer:4.7.2-ssl
       - DockerNetwork : Host Network
       - AllocationTag : siem
       - EnvironementVariables : "OPENSEARCH_JAVA_OPTS":"-Xms3g -Xmx3g"
       - Volumes : "/data/es:/var/lib/wazuh-indexer"
     
  - Siem Service Deployment:
  - - Navigate to `Docker` tab.
    - Select `services`.
    - Add new service with configuration as follows:
    -  - Name : siem
       - DockerImage: duplocloud/wazuh-manager:4.7.2-ssl
       - DockerNetwork : Host Network
       - AllocationTag : siem
       - EnvironementVariables :  "INDEXER_URL":"https://localhost:9200", "INDEXER_USERNAME":"admin", "INDEXER_PASSWORD":"VyTeLYbHb@t9ayg", "FILEBEAT_SSL_VERIFICATION_MODE" : "none", "API_USERNAME" : "wazuh-wui", "API_PASSWORD" : "UTim*Ppu9MXyQ6hm"
       - Volumes : "/data/ossec_api_configuration:/var/ossec/api/configuration","/data/ossec_etc:/var/ossec/etc"

  - Dashboard Service Deployment:
  - - Navigate to `Docker` tab.
    - Select `services`.
    - Add new service with configuration as follows:
    -  - Name : dashboard
       - DockerImage: duplocloud/wazuh-dashboard:4.7.2-ssl
       - DockerNetwork : Host Network
       - AllocationTag : siem
       - EnvironementVariables : "OPENSEARCH_HOSTS" : "https://localhost:9200" , "WAZUH_API_URL" : "https://localhost" , "API_PORT" : 55000, "RUN_AS": false, "INDEXER_USERNAME" : "admin" , "INDEXER_PASSWORD" : "VyTeLYbHb@t9ayg", "API_USERNAME" : "wazuh-wui", "API_PASSWORD" : "UTim*Ppu9MXyQ6hm" , "DASHBOARD_USERNAME" : "kibanaserver" , "DASHBOARD_PASSWORD" : "L8JrB47!GNW3Zvx"

4. Expose dashboard service internally using load-balancer to establish communication between SIEM & OPENSEARCH services.
5. Create application load-balancers with following configurations :
   - LB - 1
     - Type : Application Loadbalancer
     - Container Port : 5601
     - External Port : 443
     - Visibility : Internal Only
     - Application Mode : Native App
     - Health Check : "/proxy/duplosiem/translations/en.json"
     - Backend Protocol : "https"
     - Certificates : <As per Portal>

   - LB - 2
      - Type : Application Loadbalancer
      - Container Port : 55000
      - External Port : 55000
      - Visibility : Internal Only
      - Application Mode : Native App
      - Health Check : "/"
      - Backend Protocol : "https"
      - Certificates : <As per Portal>
      - Additional config = HTTP success code : 200-499
        
  6. Update Security Firewall to enable communications
     - Navigate to `tenants`.
     - Locate `compliance` tenant.
     - Update security with following configuration:
       - Rule : 1
         - SourceType : IP address
         - IP CIDR : Custom
         - CIDR Range : 10.0.0.0/8
         - Protocol : TCP
         - Port-Range : 1514 - 1514
       - Rule : 2
         - SourceType : IP address
         - IP CIDR : Custom
         - CIDR Range : 10.0.0.0/8
         - Protocol : TCP
         - Port-Range : 55000-55000
