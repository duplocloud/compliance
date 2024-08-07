# SIEM Deployment

Hi! This explains the deployment of SIEM for new customers and upgrade of SIEM for existing customers


## New customers
There are multiple changes in Compliance Manager, Now compliance manager will reconcile continuously and update the config itself. No manual intervention is needed except for **PUSH URL**


1. Create Tenant with name **compliance** in default plan
2. Deploy compliance control plane: Add [siem_setup.svd](./siem_setup.svd) reference in this tenant.
	> Change all the attributes that are referenced with **##...##** in the SVD, refer to wazuh credentials in the 1Password for the passwords.
	    This SVD also has rules for 10.0.0.0/8(wazuh agents) to connect to wazuh master
    	This will also has WAZUH AMI, dummy:latest service deployed for the LB 

3. Add Reverse proxy configuration from DuploCloud UI (Administrator > System Settings > Reverse Proxy)

	a. **/duplosiem/**  to compliance ALB and forward proxy **/proxy/duplosiem/**

4. Add SIEM Push URL:
	a. Create a new **PUSH Test**  in status cake, get the push URL
	b. Call DuploCloud API and update the PUSH url in config
	> POST /compliance/UpdateComplianceConfig
		{
		"SIEMPUSHURL": "https://push.statuscake.com?PK=719ea****&amp;TestID=550****&amp;time=0"
		}
5. If customer has windows vm, we need to add command on DuploCloud to trust all the hosts.
	> winrm set winrm/config/client @{TrustedHosts="*"}`
	
	That will mostly fix the issue if the winrm commands still fails then run 	
	> `winrm quickconfig -q
	> 
	> winrm set winrm/config/service '@{AllowUnencrypted="true"}'
	> 
	> winrm set winrm/config/service/auth '@{Basic="true"}'
	> 
	> Start-Service WinRM
	>
	> set-service WinRM -StartupType Automatic	
	>
	> Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false



## Existing customers with new Compliance Onboarding
1. Update Auth service and Create compliance service with latest binaries
2. Open config file for ComplianceManager and keep only the below properties, all the other will be populate automatically
	> \<add key="AUTOREPAIRCOUNT" value="10" />
	<add key="WAZUHCREDENTIALS" value="d2F6dWg6d2F6dWg=" />
	<add key="WAZUHUIURL" value="/proxy/duplosiem/app/wazuh" />
	<add key="RESETCONFIG" value="true" />
3. Open config file for Authservice and add the line 
	> \ <add key="COMPLIANCEENDPOINT" value="http://127.0.0.1:40030" />
4. Start both Auth and compliance service
5. Create Tenant with name **compliance** in default plan
6. Deploy compliance control plane: Add **siem_setup.svd** reference in this tenant.
	> Change certificate ARN and TenantID in the SVD
	    This SVD also has rules for 10.0.0.0/8(wazuh agents) to connect to wazuh master
    	This will also has WAZUH AMI, dummy:latest service deployed for the LB 

7. Add Reverse proxy configuration
	a. **/duplosiem/**  to compliance ALB and forward proxy **/proxy/duplosiem/**
	
8. Add SIEM Push URL:
	a. Create a new **PUSH Test**  in status cake, get the push URL
	b. Call DuploCloud API and update the PUSH url in config
	> POST /compliance/UpdateComplianceConfig
		{
		"SIEMPUSHURL": "https://push.statuscake.com?PK=719ea****&amp;TestID=550****&amp;time=0"
		}

## Existing customers

For existing customers Wazuh needs to be upgraded to new version, all the data should be migrated to new version. Below steps explain in detail how to handle the upgrade.

1. **Stop Compliance**: Stop compliance manager before doing the upgrade.
2. **Backup VM**: Take snapshot of the existing wazuh VM and wait for the snapshot to be complete
3. **Backup ES Data**: We have automatic backup enabled in ES which takes a backup nightly, for the data created after the nightly backup. Take a manual backup 
	> PUT /_snapshot/s3-repository/wazuh-upgrade-20210906?wait_for_completion=true

	Verify the status of the snapshot in kibana
4. **Download Agents***: Go to the existing kibana and agents and download all the agents. This we will use later for verification. 	
5. **Upgrade docker-compose**: the new docker-compose.yml needs the lastest docker-compose. SSH into host and run the below commands
	> a. curl -L "https://github.com/docker/compose/releases/download/1.28.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	> b. chmod +x /usr/local/bin/docker-compose
	> c. sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	> d. docker-compose --version (output: docker-compose version 1.28.3)

6. **Flush Wazuh data**: Due to some bugs in the previous versions of wazuh, there are some unnecessary data files still present in the system. Restarting the wazuh-manager will clean all of them.
	> /var/ossec/bin/ossec-control restart
	
	If the wazuh-db process is not killed then do a force stop and start
	> /var/ossec/bin/ossec-control stop
		/var/ossec/bin/ossec-control start

	Check the wazuh queue size, size should be approx 200MB anything more than that the DB thread is not properly killed previously, force stop it again and delete all the ***.db-wal** files from queue
	> du -sh /wazuh-data/
		/var/ossec/bin/ossec-control stop
		rm -f /wazuh-data/queue/db/*.db-wal

6. **Upgrade Wazuh**: Follow the link https://documentation.wazuh.com/4.1/docker/upgrade-guide.html
	>  a. Create volume
		b. Attach volume to existing containers
		c. copy data to the new migration volume
		d. get new docker-compose.yml from this repo 
		e. start the containers and verify the agents ids with the ones from downloaded csv	
		f. verify everything in kibana	
7. **Update Wazuh config**: update wazuh configuration to listen on tcp port 1514 instead of udp 1514	
	
8. **Update Compliance config**: For the new compliance manager, update the config 
	>  \<add key="WAZUHCREDENTIALS" value="d2F6dWg6d2F6dWg=" /> 
9. **Create LB**: Include wazuh master host to Linux docker and stop proxy host. Create a service with dummy:latest and lb
	Create Reverseproxy config for the same	
10. **Restore ES Data**: 
	> GET _snapshot/s3-repository/_all will show the list of all the repositories
	> POST _snapshot/s3-repository/<<MANUAL_SNAPSHOT_NAME>>/_restore
	  {
	  	"indices": "security-alerts-3.x-*"
	  }	

**Found SIEM Installation Issue**

An issue was found where customers using Docker Linux Hosts are not successfully installing the **AmazonAgentLinux2** for the SIEM. Therefore, they remain in a disconnected state. Repair attempts have been tested.

The example error below is what displays in the Duplo Portal under **Security → Agents → 3 dots on Select agent → Agent Details**:

```
"DuploRepairResult": "CheckAndRepairAgent: Tenant_ID xxxx-xxxxx-xxxxx-xxx Failed to repair agent duploservices-name-of-host with exception Renci.SshNet.Common.SshAuthenticationException: Permission denied (publickey).\r\n
```

The log above explains that there is an SSH authentication issue with the installation, specifically with the **KeyPair** from the selected user.

## Remediation

The issue is that Duplo did not recognize the **ec2-user** key/pair associated with the host to install the network agent. You can manually add the **ec2-user** and image to the tenant to resolve issue.

Follow the steps below:

1. Go to **Administrator → Select Plans → Select the plan that contains the Tenant with your Host → Select Images → Select Add**.

2. Fill out the following fields:
   - **Name**: Name of Host
   - **Image ID**: AMI
   - **Username**: Example: ec2-user/root
   - **Operating System**: Linux/Windows/Etc
```
