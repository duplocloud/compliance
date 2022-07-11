1. Run the Cloudformation using `duplo-auditor-waf-dashboard.yaml`, provide the subnet and vpc of the DuploMaster
2. Once the Cloudformation is complete, connect to VPN, Go to Opensearch in AWS and open the Kibana in browser. Navigate to Dashboard on the left menu and select **WAFDashboard**
3. Also go to WAF -> Logging -> Enable logging and select the firehost `aws-waf-logs-elasticsearch`
4. Once data starts coming to Elasticsearch, you can select the filters. Select WAF in the dropdown. Copy the URL from browser
5. Add the WAF to Plan along with DashboardUrl: URL
