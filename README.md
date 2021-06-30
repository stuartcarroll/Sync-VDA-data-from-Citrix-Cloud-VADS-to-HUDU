# Sync-VDA-data-from-Citrix-Cloud-VADS-to-HUDU
Sync VDA data from Citrix Cloud VADS to HUDU Citrix VDA Data is taken from the citrix Cloud VADS Rest API and either added or updated in a specific HUDU company Asset template

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
  
.EXAMPLE
& '.\HUDU-CitrixCloud-VDAs.ps1' -Mode info
Show data collected from Cirix Cloud
  
.EXAMPLE
& '.\HUDU-CitrixCloud-VDAs.ps1' -Mode sync -huduURL https://hudu.exmaple.com -huducompanyid 3 -huduassetid 16
Sync data from Citrix Cloud to Hudu
  
  
**Reference: **
  https://developer.cloud.com/explore-more-apis-and-sdk/cloud-services-platform/citrix-cloud-api-overview/docs/get-started-with-citrix-cloud-apis
  https://github.com/lwhitelock/HuduAPI
