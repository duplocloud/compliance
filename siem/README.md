# SIEM Deployment

Hi! This explains the deployment of SIEM for new customers and upgrade of SIEM for existing customers


## New customers
There are multiple changes in Compliance Manager, Now compliance manager will reconcile continuously and update the config itself. No manual intervention is needed except for **PUSH URL**

1. Create Tenant with name **compliance**
2. Deploy compliance control plane: Add **siem_setup.svd** reference in this tenant.
	> Change certificate ARN and TenantID in the SVD
	    This SVD also has rules for 10.0.0.0/8(wazuh agents) to connect to wazuh master
    	This will also has WAZUH AMI, dummy:latest service deployed for the LB 

3. Add Reverse proxy configuration
	a. **/duplosiem/**  to compliance ALB and forward proxy **/proxy/duplosiem/**

4. Add SIEM Push URL:
	a. Create a new **PUSH Test**  in status cake, get the push URL
	b. Call Duplo API and update the PUSH url in config
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
4. **Upgrade docker-compose**: the new docker-compose.yml needs the lastest docker-compose. SSH into host and run the below commands
	> a. curl -L "https://github.com/docker/compose/releases/download/1.28.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	b. chmod +x /usr/local/bin/docker-compose
	c. sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	d. docker-compose --version (output: docker-compose version 1.28.3)

5. **Flush Wazuh data**: Due to some bugs in the previous versions of wazuh, there are some unnecessary data files still present in the system. Restarting the wazuh-manager will clean all of them.
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
	
7. **Restore ES Data**: _cat/snapshots and restore the manual snapshot we have taken previously.
8. **Update Compliance config**: For the new compliance manager, update the config 
	>  \<add key="WAZUHCREDENTIALS" value="d2F6dWg6d2F6dWg=" /> 
	
