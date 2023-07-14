$name = 'mydemo01'
$env = 'dev'
$location = 'westus'
$ip = (Invoke-WebRequest ifconfig.me/ip).Content 

$spname = "sp-"+$name+$env
Write-Host "`n`n"
Write-Host "Creating service principal $spname"
Write-Host "az ad sp create-for-rbac -n $spname --output json > sp.env.json"
az ad sp create-for-rbac -n $spname --output json > sp.env.json
Write-Host "Service principal Created"

$spAppId = (Get-Content .\sp.env.json -Raw | ConvertFrom-Json).appId
$spAppSecret = (Get-Content .\sp.env.json -Raw | ConvertFrom-Json).password
$spObjectId = (az ad sp list --display-name $spname --query "[].objectId" --output tsv )


$deployName = "deploy"+$name+$env

Write-Host "`n`n"
Write-Host "Running deployment $deployName"
Write-Host "az deployment sub create --name $deployName --template-file infrastructure/main.bicep  --location $location --parameters env=$env userPublicIp=$ip name=$name spAppId=$spAppId spAppSecret=$spAppSecret --query properties.outputs --output json > env.json "
az deployment sub create --name $deployName --template-file infrastructure/main.bicep  --location $location --parameters env=$env userPublicIp=$ip name=$name spAppId=$spAppId spAppSecret=$spAppSecret --query properties.outputs --output json > env.json 
Write-Host "Deployment finished."


# role assignment
$subid = (Get-Content .\env.json -Raw | ConvertFrom-Json).subscriptionId.value
$rg = (Get-Content .\env.json -Raw | ConvertFrom-Json).resourceGroup.value
$kv = (Get-Content .\env.json -Raw | ConvertFrom-Json).keyVault.value
$scope = '/subscriptions/'+$subid+'/resourceGroups/'+$rg

Write-Host "`n`n"
Write-Host "Executing role assignments"
# Az role assignment uses appId (clientId)
Write-Host "az role assignment create --assignee $spAppId --role Contributor --scope $scope"
az role assignment create --assignee $spAppId --role Contributor --scope $scope
# keyvault uses objectId
Write-Host "az keyvault set-policy --name $kv --object-id $spObjectId --secret-permissions get list" 
az keyvault set-policy --name $kv --object-id $spObjectId --secret-permissions get list
Write-Host "Role assignments done."

# Python setup
$has_env = Test-Path venv/
if ($has_env -eq $false){
    Write-Host "`n`n"
    Write-Host "Craeting new python env"
    python -m venv venv 
    venv/Scripts/pip install -r requirements.txt
}

Write-Host "`n`n"
Write-Host "Executing python scripts"
venv/Scripts/python make_env.py
venv/Scripts/python sql/publish.py