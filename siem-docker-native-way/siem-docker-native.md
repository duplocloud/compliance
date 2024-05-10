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

   7. In order to setup reverse proxy we need to provide the credentials to the service. By default, kibana user credentials are configured with the service. We need to update to use `wazuh` credentials.
   8. With encode we can use these `d2F6dWgtd3VpOlVUaW0qUHB1OU1YeVE2aG0=` credential to update the service.
      - Steps:
      - - SSM to master instance
        - Navigate to `services` & locate `Duplo.ComplianceService`.
        - Stop the service.
        - Navigate to FOLDER section.
        - Search `Duplo.ComplianceCore.exe.config` file under `Duplo.ComplianceService` folder.
        - Open with Notepad ++
        - Under "appSettings" section locate `WAZUHCREDENTIALS` and update with above credential.
        - Save file & navigate to services to start `Duplo.ComplianceService`.
       
   9. Go to Duplo portal nad navigate to `SECURITY` tab. "SIEM" will be available by now.
   10. Last part is to setup reverse proxy to access `DASHBOARD`.
   11. Use following command to setup proxy. The command can be hit from local machine as well. **NOTE** that openvpn is connected before running command.
curl --location 'https://<change>.duplocloud.net/admin/UpdateReverseProxyConfig' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer <token>' \
--data '{
    "ProxyPath": "/duplosiem",
    "BackendHostUrl": "https://<give-dashboard-service-url>",
    "ForwardingPrefix": "/proxy/duplosiem",
    "AllowedRoles": [
        "Administrator",
        "SecurityAdmin"
    ],
    "Authorization": "Basic d2F6dWhfdXNlcjpKZ0ZEUS5ZVEFaNEM3czk="
}'
