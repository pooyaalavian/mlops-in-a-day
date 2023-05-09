$name = 'mlopsiad01'
$env = 'dev'
$location = 'westus'
$ip = (Invoke-WebRequest ifconfig.me/ip).Content 

$spname = "sp-"+$name+$env
az ad sp create-for-rbac -n $spname --output json > sp.env.json

$spAppId = (Get-Content .\sp.env.json -Raw | ConvertFrom-Json).appId
$spAppSecret = (Get-Content .\sp.env.json -Raw | ConvertFrom-Json).password
# $spObjId = (az ad sp list --display-name "$spname" --output tsv --query [].id)


$deployName = "deploy"+$name+$env
az deployment sub create --name $deployName --template-file infrastructure/main.bicep  --location $location --parameters env=$env userPublicIp=$ip name=$name spAppId=$spAppId spAppSecret=$spAppSecret --query properties.outputs --output json > env.json 


# role assignment
$subid = (Get-Content .\env.json -Raw | ConvertFrom-Json).subid.value
$rg = (Get-Content .\env.json -Raw | ConvertFrom-Json).rg.value
$kv = (Get-Content .\env.json -Raw | ConvertFrom-Json).key_vault.value
$scope = '/subscriptions/'+$subid+'/resourceGroups/'+$rg

az role assignment create --assignee $spAppId --role Contributor --scope $scope
az keyvault set-policy --name $kv --object-id $spAppId --secret-permissions get list 
# az keyvault set-policy --name $kv --object-id $spObjId --secret-permissions get list 

# Python setup
$has_env = Test-Path venv/
if ($has_env -eq $false){
    Write-Host "Craeting new python env"
    python -m venv venv 
    venv/Scripts/pip install -r requirements.txt
}

venv/Scripts/python make_env.py
venv/Scripts/python sql/publish.py