
<#
Sync VDA data from Citrix Cloud VADS to HUDU

Stu Carroll - Coffee Cup Solutions (stu.carroll@coffeecupsolutions.com) 2020
#>

<#
.SYNOPSIS
Collect VDA data from Citrix Cloud VADS and add to Hudu Assets

To avoid hard coding or passing sensitive custome rdata this script requires the following environment variables to be set: 

    $Env:CLIENT_ID = <Citrix Cloud API ID>
    $Env:CLIENT_SECRET = <Citrix Cloud API Secret>
    $Env:CUSTOMER_ID = <Citrix Cloud Customer ID>
    $Env:HuduAPI = <Hudu API Key>

.DESCRIPTION
.PARAMETER mode
Select mode of script to detemine the script actions:
 	info - Show data collected from Cirix Cloud
	sync - Sync data from Citrix Cloud to Hudu
.PARAMETER huduURL
The URL of your HUDU server
.PARAMETER huducompanyid
The company ID you wish to update
.PARAMETER huduassetid
The ID of the Hudu asset template
.PARAMETER hududebug
Enable Hudu debug info 

.EXAMPLE
& '.\CitrixVADService-VDAs-To-Hudu.ps1' -Mode info
Show data collected from Cirix Cloud

.EXAMPLE
& '.\CitrixVADService-VDAs-To-Hudu.ps1' -Mode sync -huduURL https://hudu.exmaple.com -huducompanyid 3 -huduassetid 16
Sync data from Citrix Cloud to Hudu

.EXAMPLE
& '.\CitrixVADService-VDAs-To-Hudu.ps1' -Mode sync -huduURL https://hudu.exmaple.com -huducompanyid 3 -huduassetid 16 -hududebug on
Sync data from Citrix Cloud to Hudu with hudu debug info 

#>

#Decalre parameters
param(  
    #Script mode:
    # info - Output machine 
    # sync - Sync to Hudu
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet('info', 'sync')]
    [String]$Mode = "info",
    #Hudu Company ID
    [Parameter(Position = 1, Mandatory = $false)]
    [String]$huducompanyid = "",
    #Hudu Asset Template ID
    [Parameter(Position = 2, Mandatory = $false)]
    [String]$huduassetid = "",
    [Parameter(Position = 3, Mandatory = $false)]
    [String]$hududebug = "",
    #HUDU URL
    [Parameter(Position = 4, Mandatory = $false)]
    [String]$HuduURL = ""
)


#Authenticate to Citrix Cloud Rest API
$tokenUrl = 'https://api-eu.cloud.com/cctrustoauth2/root/tokens/clients'
$response = Invoke-WebRequest $tokenUrl -Method POST -Body @{
  grant_type = "client_credentials"
  client_id = $env:CLIENT_ID
  client_secret = $env:CLIENT_SECRET
}
$token = $response.Content | ConvertFrom-Json
$headers = @{
    Authorization = "CwsAuth Bearer=$($token.access_token)"
    'Citrix-CustomerId' = $customerId
    Accept = 'application/json'
  }

#Get Site ID
$siteURL = Invoke-WebRequest "https://api-us.cloud.com/cvadapis/me" `
-Headers $headers
$SiteID = ($siteURL | ConvertFrom-Json).Customers.Sites.Id

# Get a Machine JSON Data
$response = Invoke-WebRequest "https://api.cloud.com/cvadapis/$SiteID/Machines" -Headers $Headers
$machines = ($response | convertFrom-Json).Items

#If Machine JSON Data is NULL exit
if ($null -eq $machines) {
    Write-Error "No data retreieved from Citrix Cloud - ABANDON SHIP!"
    Exit 
}

#Create Machine Table
$Table = New-Object System.Data.DataTable
$Table.Columns.Add("DNSName", "string") | Out-Null
$Table.Columns.Add("IPAddress", "string") | Out-Null
$Table.Columns.Add("AgentVersion", "string") | Out-Null
$Table.Columns.Add("DeliveryGroup", "string") | Out-Null
$Table.Columns.Add("MachineCatalog", "string") | Out-Null
$Table.Columns.Add("InMaintenanceMode", "string") | Out-Null
$Table.Columns.Add("OSVersion", "string") | Out-Null
$Table.Columns.Add("PowerState", "string") | Out-Null
$Table.Columns.Add("ProvisioningType", "string") | Out-Null
$Table.Columns.Add("HostingConnection", "string") | Out-Null
$Table.Columns.Add("Zone", "string") | Out-Null


foreach($machine in $machines){
    #Create a new row in table
    $r = $Table.NewRow()
    $r.DNSName = $machine.DNSName
    $r.IPAddress = $machine.IPAddress
    $r.AgentVersion = $machine.AgentVersion
    $r.DeliveryGroup = $machine.DeliveryGroup.Name
    $r.MachineCatalog = $machine.MachineCatalog.Name
    $r.InMaintenanceMode = $machine.InMaintenanceMode
    $r.OSVersion = $machine.OSVersion
    $r.PowerState = $machine.PowerState
    $r.ProvisioningType = $machine.ProvisioningType
    $r.HostingConnection = $machine.Hosting.HypervisorConnection.Name
    $r.Zone = $machine.zone.Name
    $Table.Rows.Add($r)
}

#Script result:
switch ($Mode) {
    "info" {
        #Output information 
        Write-Host "Citrix Cloud VADS data output:"
        $Table 
    }
    "sync" {
        Write-Host "Syncing assets to Hudu:"

        if($hududebug -eq "on"){
        Write-Host "API Key:"$ENV:HuduAPI
        Write-Host "Hudu URL:"$HuduURL
        Write-Host "Company ID:" $huducompanyid
        Write-Host "Compeny Name:"(Get-HuduCompanies -id $huducompanyid).company.name
        Write-Host "Asset Template ID:"$huduassetid
        Write-Host "Asset Template Name:"(Get-HuduAssetLayouts -layoutid $huduassetid).Name
        }

        #Add data to Hudu
        #Install HuduAPI module
        if (Get-Module -ListAvailable -Name HuduAPI) {
            Import-Module HuduAPI 
        } else {
            Install-Module HuduAPI -Force
            Import-Module HuduAPI
        }
        #Set API Key
        if($ENV:HuduAPI){
            New-HuduAPIKey $ENV:HuduAPI
        }else{
            Write-Error "No Hudu API Key"
            Exit 
        }
        #Set BaseURL
        if($HuduURL){
            New-HuduBaseURL $HuduURL
        }else{
            Write-Error "No Hudu Base URL Set"
            Exit 
        }
        foreach ($vda in $Table) {
            #Check if asset exists	
		    $Asset = Get-HuduAssets -name $vda.DNSName -company_id $huducompanyid -asset_layout_id $huduassetid

            $Fields	= @{
                'DNSName' = $vda.DNSName
                'IPAddress' = $vda.IPAddress
                'AgentVersion' = $vda.AgentVersion
                'DeliveryGroup' = $vda.DeliveryGroup
                'MachineCatalog' = $vda.MachineCatalog
                'InMaintenanceMode' = $vda.InMaintenanceMode
                'OSVersion' = $vda.OSVersion
                'PowerState' = $vda.PowerState
                'ProvisioningType' = $vda.ProvisioningType
                'HostingConnection' = $vda.HostingConnection
                'Zone' = $vda.Zone
            }

            if (!$Asset) {
                #If asset doesnt exist create it
                Write-Host -ForegroundColor Green "Creating new Asset "$vda.DNSName 
                $Asset = New-HuduAsset -name $vda.DNSName -company_id $huducompanyid -asset_layout_id $huduassetid -fields $Fields	
            }
            else {
                #If asset exists update it
                Write-Host -ForegroundColor Yellow "Updating Asset "$vda.DNSName 
                $Asset = Set-HuduAsset -asset_id $Asset.id -name $vda.DNSName -company_id $huducompanyid -asset_layout_id $huduassetid -fields $Fields	
            }

        }
    }
}



    