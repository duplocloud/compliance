You can use this cloudformation template to create a new elastic search which can be used as both Auditor for Duplo and WAF Dashboard
1. This will automatically create the Duplo Auditor ES mappings 
2. This will automatically import the ES Dashboard, Create Kinesis streams, and mappings for the waf logs

Steps to setup WAF Dashboard and Auditor
1. Run this cloudformation script
2. Once its complete, Go to WAF edit logging and select the already created kinesis stream "aws-waf-logs-elasticsearch"
3. Configure the ES endpoint in the Master and Auth config files

Migrate old ES to new ES
1. Go to any host where you can run a docker container. The host should have access to the ES Endpoints, but confirm using "curl -XGET ES-ENDPOINT" 
2. Run  docker run --rm -ti elasticdump/elasticsearch-dump   --input=SOURCE-ES-ENDPOINT/auth --output=DEST-ES-ENDPOINT/auth   --type=data --limit=10000 --sourceOnly=true
3. Run  docker run --rm -ti elasticdump/elasticsearch-dump   --input=SOURCE-ES-ENDPOINT/tenant --output=DEST-ES-ENDPOINT/tenant   --type=data --limit=10000 --sourceOnly=true
4. Create index pattern for both tenant and auth in Kibana