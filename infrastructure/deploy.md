# MLOps In A Day
## Infrastructure-as-Code

In this folder you find the `bicep` templates for creating the resources needed.
These resources include:

- A resource group to host all resources
- A storage account, used by Azure ML workspace and Azure Functions
- A key vault, used by multiple services to store secrets
- A container registry, used to host deployment images
- An application insights, to monitor and study the logs from Azure ML and Azure functions
- An Azure ML workspace
- An app service plan to host the Azure function
- An Azure function app
- A SQL server
- A SQL database in the SQL server
- Some firewall rules for your SQL Server (allow your IP and allow all Azure internal IPs to connect to this server)

To deploy all of the above to your subscription, run the following Az CLI command:
```sh
# In powershell use:
$ip = (Invoke-WebRequest ifconfig.me/ip).Content 
# or in linux shell use: 
# ip =$(curl ifconfig.me/ip)
az deployment sub create --name myDeployment --template-file infrastructure/main.bicep  --location eastus --parameters env=dev userPublicIp=$ip name=pooya101 --query properties.outputs --output json > env.json 
```

This command (`az deployment`) acts at the subscription (`sub`) level, to create (`create`) the resources. Deployment name is `--name myDeployment`. The resources are explained in `--template-file main.bicep`. The location is `--location eastus`. 

If you closely look at `main.bicep`, you will notice it receives multiple inputs (`param`s), many of which have default values. You can specify values for all params after the `--parameters` flag. In the above code, I am setting `env` to `dev` and `name` to `pooya101`.

It is usually a good practice to keep parameters in `params.json` file. You may want to create `params-dev.json`, `params-prod.json`, etc. to make the entire IaC seamless.

