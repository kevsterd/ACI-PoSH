###################################################################################################################
##
## ACI-Services.psml
##
###################################################################################################################
##
## A set of service functions to manipulate Cisco ACI from PowerShell
##
## This set of modules do CRUD functions.	They were tested against ACI -3.0/3.1/3.2 and may be
## subject to change, depending on what Cisco may do in the future.
##
## To do:
##
##	- Add	validation on inputs to make sure no escape	
##	- Add	try/catch conditioning better than existing method (C U only at the moment)
##	- Add	validation of some input - should check	tenant exists etc
##					
###################################################################################################################
# 2.3 - 2019-02-03 - KPI - Better output and validation.  Pipeline input support and more.  Removed format-table on some outputs
#                        - as was causing pipeline parse issues.  You can of course use in on outputs :)
# 2.2 - 2019-01-22 - KPI - More methods and user mgmt
# 2.1 - 2019-01-10 - KPI - Added more create methods and help text finally
# 2.0 - 2019-01-03 - KPI - Initial GitHub Release
# 1.4 - 2018-11-05 - KPI - Code Tidy
# 1.3 - 2018-11-01 - KPI - Added further methods to create fabric interface associations - inc VPC
# 1.2 - 2018-10-30 - KPI - Added further methods to add fabric configuration (L2/L3)
# 1.1 - 2018-10-12 - KPI - Added further methods to view fabric (L2)
# 1.0 - 2018-02-23 - KPI - Initial Version
###################################################################################################################

###################################################################################################################
## Read functions
###################################################################################################################

function Get-ACI-Tenant
{
    <#
    .SYNOPSIS
    Fetches all defined Tenants from ACI
    
    .DESCRIPTION
    Gets all defined and system level tenants from ACI
    
    .EXAMPLE
    Get-ACI-Tenant

    name        descr dn                
    ----        ----- --                
    infra             uni/tn-infra      
    common            uni/tn-common     
    mgmt              uni/tn-mgmt       
    companyA          uni/tn-companyA   
    companyB    Co B  uni/tn-companyB   
    companyC          uni/tn-companyC   
    cloudMgmt         uni/tn-cloudMgmt  
    secretAudit       uni/tn-secretAudit
    
    .NOTES
    Probably the most simple function
    #>
    
    $PollURL = 'api/node/class/fvTenant.json'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $TenRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output ...
    Write-Output $TenRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvTenant | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-AppProfile-All ([Parameter(ValueFromPipelineByPropertyName)][string]$Tenant)
    {
    <#
    .SYNOPSIS
    Get all defined Application Profiles for a given tenant    
    
    .DESCRIPTION
    Get all defined Application Profiles for a given tenant
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .EXAMPLE
    Get-ACI-AppProfile-All -Tenant companyA

    name           descr dn                               
    ----           ----- --                               
    web.appprofile       uni/tn-companyA/ap-web.appprofile
    db.appprofile        uni/tn-companyA/ap-db.appprofile
    
    .NOTES
    
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '.json?query-target=children&target-subtree-class=fvAp'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $ApRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $ApRawJson  | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvAp | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-AppProfile ([Parameter(ValueFromPipelineByPropertyName)][string]$Tenant,
                             [Parameter(ValueFromPipelineByPropertyName)][string]$AP)
    {
    <#
    .SYNOPSIS
    Gets detail for a specific Application Profile
    
    .DESCRIPTION
    Gets detail for a specific Application Profile
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .PARAMETER AP
    Application Profile.  Can be extracted from the Get-ACI-AppProfile-All command
    
    .EXAMPLE
    Get-ACI-AppProfile -Tenant companyA -AP web.appprofile

    name    prio   descr dn                                           
    ----    ----   ----- --                                           
    web.epg level3       uni/tn-companyA/ap-web.appprofile/epg-web.epg
    
    .NOTES
    
    #>
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    if (!($Ap))
        {
        Write-Host "No Application Profile specified" -ForegroundColor Red
        Break
        }
    # Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $Ap + '.json?query-target=subtree&target-subtree-class=fvAEPg'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $ApRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $ApRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvAEPg | Select-Object -ExpandProperty attributes | Select-Object name, prio, descr, dn
    }
function Get-ACI-EPG (
    [Parameter(ValueFromPipelineByPropertyName)][string]$Tenant,
    [Parameter(ValueFromPipelineByPropertyName)][string]$AP,
    [Parameter(ValueFromPipelineByPropertyName)][string]$EPG)
    {
    <#
    .SYNOPSIS
    Gets ACI EndPoint Groups assigned to an Application Profile.  

    * THIS IS UNFINISHED AS IT RETURNS NATIVE DATA *
    
    .DESCRIPTION
    Gets ACI EndPoint Groups assigned to an Application Profile
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .PARAMETER AP
    Application Profile.  Can be extracted from the Get-ACI-AppProfile-All command
    
    .PARAMETER EPG
    EndPoint Group.  Can be extracted from the Get-ACI-AppProfile command
    
    .EXAMPLE
    Get-ACI-EPG -Tenant companyA -AP web.appprofile -EPG web.epg
    
    .NOTES
    General notes
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
    }
        if (!($Ap))
        {
        Write-Host "No Application Profile specified" -ForegroundColor Red
        Break
        }
    if (!($EPG))
        {
        Write-Host "No EPG specified"
        Break
        }
        $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $Ap + '/epg-' + $EPG + '.json'
        #Domain
        $PollURLDom	= $PollURL + '?query-target=children&target-subtree-class=fvRsDomAtt'     
        #Static Paths
        $PollURLSPath = $PollURL + '?query-target=children&target-subtree-class=fvRsPathAtt' 
        #Contracts
        $PollURLContract = $PollURL + '?query-target=children&target-subtree-class=fvRsCons&target-subtree-class=fvRsConsIf,fvRsProtBy,fvRsProv,vzConsSubjLbl,vzProvSubjLbl,vzConsLbl,vzProvLbl,fvRsIntraEpg'
        #Munge URLs
        $PollRawDom	= New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURLDom
        $PollRawSPath = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURLSPath 
        $PollRawContract = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURLContract
        
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $DomRawJson	= $PollRawDom.httpResponse	| ConvertFrom-Json
        $SPathRawJson	= $PollRawSPath.httpResponse | ConvertFrom-Json
        $ContractRawJson = $PollRawContract.httpResponse | ConvertFrom-Json
        #Output
        write-host ""
        write-host "Domain Binding"
        write-host "--------------"
        Write-Output $DomRawJson | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty fvRsDomAtt | Select-Object -ExpandProperty attributes
        write-host ""
        write-host "Static Path Binding"
        write-host "-------------------"	
        Write-Output $SPathRawJson | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty fvRsPathAtt | Select-Object -ExpandProperty attributes 
        write-host ""
        write-host "Contracts"	
        Write-Output $ContractRawJson | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty * | Select-Object -ExpandProperty attributes	
    }	

function Get-ACI-EPG-All (
    [Parameter(ValueFromPipelineByPropertyName)][string]$Tenant,
    [Parameter(ValueFromPipelineByPropertyName)][string]$AP)	
    {	
    <#
    .SYNOPSIS
    Gets all EPG's that are defined for an Application Profile (AP)
    
    .DESCRIPTION
    Gets all EPG's that are defined for an Application Profile (AP)
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .PARAMETER AP
    Application Profile.  Can be extracted from the Get-ACI-AppProfile-All command
    
    .EXAMPLE
    Get-ACI-EPG-all -Tenant companyA -AP web.appprofile

    name    prio   descr dn                                           
    ----    ----   ----- --                                           
    web.epg level3       uni/tn-companyA/ap-web.appprofile/epg-web.epg
    
    .NOTES
    
    #>
    	
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    if (!($Ap))
        {
        Write-Host "No Application Profile specified" -ForegroundColor Red Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + ,$Ap + '.json?query-target=subtree&target-subtree-class=fvAEPg'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $ApRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $ApRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvAEPg | Select-Object -ExpandProperty attributes | Select-Object name, prio, descr, dn
    }

function Get-ACI-BD-All ([Parameter(ValueFromPipelineByPropertyName)][string]$Tenant)
    {
    <#
    .SYNOPSIS
    Get all ACI Bridge Domains for a given Tenant

    .DESCRIPTION
    Get all ACI Bridge Domains for a given Tenant
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .EXAMPLE
    Get-ACI-BD-all -Tenant companyA 

    name            descr dn                                
    ----            ----- --                                
    500-DB-DATA-001       uni/tn-companyA/BD-500-DB-DATA-001
    201-WEB-BE-001        uni/tn-companyA/BD-201-WEB-BE-001 
    200-WEB-FE-001        uni/tn-companyA/BD-200-WEB-FE-001 
    
    .NOTES
    
    #>
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '.json?query-target=children&target-subtree-class=fvBD'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvBd | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-BD (
    [Parameter(ValueFromPipelineByPropertyName)][string]$Tenant,
    [Parameter(ValueFromPipelineByPropertyName)][string]$BD)
    {
    <#
    .SYNOPSIS
    Get detailed Bridge Domain detail
    
    .DESCRIPTION
    Get detailed Bridge Domain detail
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command

    .PARAMETER BD
    Bridge Domain name
    
    .EXAMPLE
    Get-ACI-BD -Tenant companyA -BD 500-DB-DATA-001

    Bridge Domain
    -------------

    name                  : 500-DB-DATA-001
    descr                 : 
    mtu                   : inherit
    limitIpLearnToSubnets : yes
    arpFlood              : no
    dn                    : uni/tn-companyA/BD-500-DB-DATA-001

    L3 Out Interfaces
    -----------------
    tnL3extOutName : GetOutA

    Subnet Address
    --------------
    ip    : 2.2.2.1/28
    scope : public
    
    .NOTES
    
    #>
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    if (!($Bd))
        {
        Write-Host "No Bridge Domain specified" -ForegroundColor Red
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/BD-' + $Bd + '.json'
    $PollURLL3 = $PollURL + '?query-target=children&target-subtree-class=fvRsBDToOut'
    $PollURLSub = $PollURL + '?query-target=children&target-subtree-class=fvSubnet'
    
    #write-host $PollURL
    #write-host $PollURLSub
    
    #Munge URLs
    $PollRaw	= New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    $PollRawL3  = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURLL3
    $PollRawSub = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURLSub
    
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $OutRawJson	=	$PollRaw.httpResponse	|	ConvertFrom-Json
    $OutRawJsonL3	=	$PollRawL3.httpResponse	|	ConvertFrom-Json
    $OutRawJsonSub	=	$PollRawSub.httpResponse	|	ConvertFrom-Json
    #Output
    Write-Host ""
    Write-Host "Bridge Domain"
    Write-Host "-------------"
    Write-Output $OutRawJson	| Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvBd | Select-Object -ExpandProperty attributes | Select-Object name , descr, mtu, limitIpLearnToSubnets, arpFlood, dn
    Write-Host ""
    Write-Host "L3 Out Interfaces"
    Write-Host "-----------------"
    Write-Output $OutRawJsonL3 | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvRsBDToOut | Select-Object -ExpandProperty attributes | Select-Object tnL3extOutName
    Write-Host ""
    Write-Host "Subnet Address"
    Write-Host "--------------"
    Write-Output $OutRawJsonSub | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvSubnet	| Select-Object -ExpandProperty attributes | Select-Object ip, scope
    }

function Get-ACI-VRF (
    [Parameter(ValueFromPipelineByPropertyName)][Alias('Name')][string]$Tenant)
    {
    <#
    .SYNOPSIS
    Get VRF's defined for a given tenant
    
    .DESCRIPTION
    Get VRF's defined for a given tenant
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .EXAMPLE
    get-aci-vrf -Tenant companyA

    name         descr bdEnforcedEnable pcEnfDir pcEnfPref dn                              
    ----         ----- ---------------- -------- --------- --                              
    companyA-vrf       no               ingress  enforced  uni/tn-companyA/ctx-companyA-vrf
    secret             no               ingress  enforced  uni/tn-companyA/ctx-secret
    
    .NOTES
    pcEnfDir indicates the point Contacts and other policy control is applied.   Usually on ingress (like ACL or Firewall ACL)
    pcEnfPref states whether contracts and other policy control are applied within this VRF.  Usually enforced. 
    #>

    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant +'.json?query-target=children&target-subtree-class=fvCtx'
    
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvCtx | Select-Object -ExpandProperty attributes | Select-Object name, descr, bdEnforcedEnable, pcEnfDir, pcEnfPref, dn 
 }

function Get-ACI-L3out-All ([Parameter(ValueFromPipelineByPropertyName)][string]$Tenant)
    {
    <#
    .SYNOPSIS
    Get specific L3out for a given tenant
    
    .DESCRIPTION
    Get specific L3out for a given tenant
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .EXAMPLE
    Get-ACI-L3out-All -Tenant companyA

    name    enforceRtctrl descr dn                         
    ----    ------------- ----- --                         
    GetOutA export              uni/tn-companyA/out-GetOutA
    GetOutB export              uni/tn-companyA/out-GetOutB
    
    .NOTES
    
    #>
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '.json?query-target=children&target-subtree-class=l3extOut'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty l3extOut | Select-Object -ExpandProperty attributes | Select-Object name, enforceRtctrl, descr, dn
    }
function Get-ACI-L3out (
    [Parameter(ValueFromPipelineByPropertyName)][string]$Tenant,
    [Parameter(ValueFromPipelineByPropertyName)][string]$L3out)
    {
    <#
    .SYNOPSIS
    Gets detail about a specific L3out interface

    * NOT COMPLETE - Expansion of results required*
    
    .DESCRIPTION
    Gets detail about a specific L3out interface
    
    .PARAMETER Tenant
    ACI tenant.   Can be extracted from the Get-ACI-Tenant command
    
    .PARAMETER L3out
    L3out interface name
    
    .EXAMPLE
    Get-ACI-L3out -Tenant companyA -L3out GetOutB
    
    .NOTES
    General notes
    #>
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '/out-' + $L3out + '.json?query-target=children&target-subtree-class=l3extRsEctx'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty l3extRsEctx | Select-Object -ExpandProperty attributes | Select-Object tRn, tnFvCtxName, descr, dn
    }

    function Get-ACI-Fabric-PhysicalDomain
    {
    <#
    .SYNOPSIS
    Get Physical Domains for the ACI Fabric
    
    .DESCRIPTION
    Get Physical Domains for the ACI Fabric. 
    
    .EXAMPLE
    Get-ACI-Fabric-PhysicalDomain

    name                nameAlias dn                          
    ----                --------- --                          
    phys                          uni/phys-phys               
    SnV_phys                      uni/phys-SnV_phys           
    Heroes_phys                   uni/phys-Heroes_phys        
    jinyetest                     uni/phys-jinyetest          
    HL-PhyDom                     uni/phys-HL-PhyDom
    
    .NOTES
    General notes
    #>

    #Define URL to pool
    $PollURL = 'api/node/mo/uni.json?query-target=subtree&target-subtree-class=physDomP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $RawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $RawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty physDomP | Select-Object -ExpandProperty attributes | Select-Object name, nameAlias, dn
    }

function Get-ACI-Fabric-AEEP
    {
    <#
    .SYNOPSIS
    Get Attatchable Access Entity Profiles for the ACI Fabric
    
    .DESCRIPTION
    Get Attatchable Access Entity Profiles for the ACI Fabric.  These bind vlan, vxlan and other pools to types of interfaces classes.
    
    .EXAMPLE
    Get-ACI-Fabric-AEEP

    name         descr dn                            
    ----         ----- --                            
    default            uni/infra/attentp-default     
    infra.aeep         uni/infra/attentp-infra.aeep  
    vcentre.aeep       uni/infra/attentp-vcentre.aeep
    storage.aeep       uni/infra/attentp-storage.aeep
    
    .NOTES
    General notes
    #>

    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAttEntityP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraAttEntityP | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-Fabric-Port-LinkLevel
    {
    <#
    .SYNOPSIS
    Get Link Level policies for the ACI Fabric.  These define speed, duplex, autoneg etc
    
    .DESCRIPTION
    Get Link Level policies for the ACI Fabric.  These define speed, duplex, autoneg etc
    
    .EXAMPLE
    Get-ACI-Fabric-Port-LinkLevel

    name             speed   autoNeg descr dn                                 
    ----             -----   ------- ----- --                                 
    default          inherit on            uni/infra/hintfpol-default         
    100G.auto.ll.pol 100G    on            uni/infra/hintfpol-100G.auto.ll.pol
    1G.noauto.ll.pol 1G      off           uni/infra/hintfpol-1G.noauto.ll.pol
    
    .NOTES
    #>
    #Define URL to pool
    $PollURL = 'api/node/class/fabricHIfPol.json?query-target-filter=not(wcard(fabricHIfPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$pollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData  | Select-Object -ExpandProperty fabricHIfPol | Select-Object -ExpandProperty attributes | Select-Object name, speed, autoNeg, descr, dn 
    }
 function Get-ACI-Fabric-Port-CDP
    {
    <#
    .SYNOPSIS
    Gets the fabric CDP policies
    
    .DESCRIPTION
    Gets the fabric CDP policies.  Cisco proprietory protocol.  L2 protocol.  Useful diagnotic aid, however has security issues.  Beware !
    
    .EXAMPLE
    Get-ACI-Fabric-Port-cdp

    name             adminSt  descr dn                               
    ----             -------  ----- --                               
    default          disabled       uni/infra/cdpIfP-default         
    enabled.cdp.pol  enabled        uni/infra/cdpIfP-enabled.cdp.pol 
    disabled.cdp.pol disabled       uni/infra/cdpIfP-disabled.cdp.pol
    
    .NOTES
    General notes
    #>
    
    #Define URL to pool
    $PollURL = 'api/node/class/cdpIfPol.json?query-target-filter=not(wcard(cdpIfPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output	
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty cdpIfPol | Select-Object -ExpandProperty attributes | Select-Object name, adminSt, descr, dn
    }	
function Get-ACI-Fabric-Port-LLDP	
    {	
    <#
    .SYNOPSIS
    Gets the fabric LLDP policies
    
    .DESCRIPTION
    Gets the fabric LLDP policies.  More standards based that CDP.  L2 protocol.   Useful diagnotic aid, however has security issues.  Beware !
    
    .EXAMPLE
    Get-ACI-Fabric-Port-LLDP

    name                adminRxSt adminTxSt descr dn                                   
    ----                --------- --------- ----- --                                   
    default             enabled   enabled         uni/infra/lldpIfP-default               
    enabled.lldp.pol    enabled   enabled         uni/infra/lldpIfP-enabled.lldp.pol   
    enabled-tx.lldp.pol disabled  enabled         uni/infra/lldpIfP-enabled-tx.lldp.pol
    disabled.lldp.pol   disabled  disabled        uni/infra/lldpIfP-disabled.lldp.pol
    
    .NOTES
    General notes
    #>
    
    $PollURL = 'api/node/mo/uni/infra.json?query-target=children&target-subtree-class=lldpIfPol&query-target-filter=not(wcard(lldpIfPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty lldpIfPol | Select-Object -ExpandProperty attributes | Select-Object name, adminRxSt, adminTxSt, descr, dn 
    }
function Get-ACI-Fabric-Port-LACP
    {
    <#
    .SYNOPSIS
    Get Fabric port channel polcies for multiple interface bundles.
    
    .DESCRIPTION
    Get Fabric port channel polcies for multiple interface bundles.
    
    .EXAMPLE
    Get-ACI-Fabric-Port-LACP

    name                      mode   ctrl                                             minLinks maxLinks descr dn                                          
    ----                      ----   ----                                             -------- -------- ----- --                                          
    default                   off    fast-sel-hot-stdby,graceful-conv,susp-individual 1        16             uni/infra/lacplagp-default                  
    active_nostandby.lacp.pol active fast-sel-hot-stdby,graceful-conv                 1        16             uni/infra/lacplagp-active_nostandby.lacp.pol
    active.lacp.pol           active fast-sel-hot-stdby,graceful-conv,susp-individual 1        16             uni/infra/lacplagp-active.lacp.pol          
    static.lacp.pol           off    fast-sel-hot-stdby,graceful-conv,susp-individual 1        16             uni/infra/lacplagp-static.lacp.pol
    
    .NOTES
    
    #>
    
    #Define URL to pool
    $PollURL = '/api/node/class/lacpLagPol.json?query-target-filter=not(wcard(lacpLagPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty lacpLagPol | Select-Object -ExpandProperty attributes | Select-Object name, mode, ctrl, minLinks, maxLinks, descr, dn 
    }
function Get-ACI-Fabric-Switch-Leaf
    {
    <#
    .SYNOPSIS
    Gets all leaf switches defined in the fabric
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    Get-ACI-Fabric-Switch-Leaf

    name               descr dn                                
    ----               ----- --                                
    LEAF_A101                uni/infra/nprof-LEAF_A101         
    LEAF_A102                uni/infra/nprof-LEAF_A102         
    LEAF_A101_A102_VPC       uni/infra/nprof-LEAF_A101_A102_VPC
    
    .NOTES
    The name is used as the main referance for policy.  These are linked to a nodeID.
    #>
       
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraNodeP&query-target-filter=not(wcard(infraNodeP.name,"__ui_"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraNodeP | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-Fabric-VLANPool-All
    {
    <#
    .SYNOPSIS
    Get all VLAN pools defined within the fabric, along with their allocation method
    
    .DESCRIPTION
    Get all VLAN pools defined within the fabric, along with their allocation method
    
    .EXAMPLE
    Get-ACI-Fabric-VLANPool-All

    name          allocMode descr dn                                     
    ----          --------- ----- --                                     
    infra.vlans   dynamic         uni/infra/vlanns-[infra.vlans]-dynamic 
    vcentre.vlans static          uni/infra/vlanns-[vcentre.vlans]-static
    storage.vlans static          uni/infra/vlanns-[storage.vlans]-static
    
    .NOTES
    
    #>
    
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=fvnsVlanInstP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvnsVlanInstP | Select-Object -ExpandProperty attributes | Select-Object name, allocMode, descr, dn 
    }

function Get-ACI-Fabric-LeafAccessPolicy-All
    {
    <#
    .SYNOPSIS
    Get all Fabric Leaf Access Policies defined within the fabric.
    
    .DESCRIPTION
    Get all Fabric Leaf Access Policies defined within the fabric.
    
    .EXAMPLE
    Get-ACI-Fabric-LeafAccessPolicy-All

    name                                   descr dn                                                                  
    ----                                   ----- --                                                                  
    web.servers.prod.AccessPortPolicyGroup       uni/infra/funcprof/accportgrp-web.servers.prod.AccessPortPolicyGroup
    
    .NOTES
    General notes
    #>
    
    
    #URL to pool
    $PollURL = 'api/node/mo/uni/infra/funcprof.json?query-target=subtree&target-subtree-class=infraAccPortGrp&query-target-filter=not(wcard(infraAccPortGrp.dn,"__ui_"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraAccPortGrp | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn 
    }

function Get-ACI-Fabric-LeafAccessPolicy ([Parameter(ValueFromPipelineByPropertyName)][string]$LeafAccessPolicy)
    {
    <#
    .SYNOPSIS
    Get a specific Leaf Access Policy detail
    
    * NOT COMPLETE - Needs expansion *

    .DESCRIPTION
    Get a specific Leaf Access Policy detail
    
    .PARAMETER LeafAccessPolicy
    Parameter description
    
    .EXAMPLE
    Get-ACI-Fabric-LeafAccessPolicy -LeafAccessPolicy web.servers.prod.AccessPortPolicyGroup

    name                                   descr dn                                                                  
    ----                                   ----- --                                                                  
    web.servers.prod.AccessPortPolicyGroup       uni/infra/funcprof/accportgrp-web.servers.prod.AccessPortPolicyGroup
    
    .NOTES
    General notes
    #>
    
    #Check a VLAN pool has been specified
    if (!($LeafAccessPolicy ))
        {
        Write-Host "No Leaf Access Policy specified" -ForegroundColor Red
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra/funcprof/accportgrp-' + $LeafAccessPolicy + '.json'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraAccPortGrp | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn 
    }

 function Get-ACI-Fabric-VLANPool (
    [Parameter(ValueFromPipelineByPropertyName)][string]$VLANPool,
    [string]$AllocMode)
    {
    <#
    .SYNOPSIS
    Get VLAN numbers attached to a VLAN Pool
    
    .DESCRIPTION
    Get VLAN numbers attached to a VLAN Pool
    
    .PARAMETER VLANPool
    Vlan Pool name
    
    .PARAMETER AllocMode
    Vlan Pool allocation mode.  Sorry its not get automatic !
    
    .EXAMPLE
    Get-ACI-Fabric-VLANPool -VLANPool vcentre.vlans -AllocMode static

    name allocMode from     to       dn                                                                   
    ---- --------- ----     --       --                                                                   
         static    vlan-200 vlan-999 uni/infra/vlanns-[vcentre.vlans]-static/from-[vlan-200]-to-[vlan-999]
    
    .NOTES
    General notes
    #>
    
    # ACI stores VLAN pools as dynamic or static pools, and then saves the object differently
    # This function caters for this, albeit manually.
    #Check a VLAN pool has been specified
    if (!($VLANPool))
        {
        Write-Host "No VLAN Pool specified" -ForegroundColor Red
        Break
        }
    #Check for VLAN allocation mode
    If ($AllocMode -like 'static')
        {
        $AllocMode = $AllocMode.ToLower()
        }
    ElseIf ($AllocMode -like 'dynamic')
        {
        $AllocMode = $AllocMode.ToLower()
        }
    Else
        {
        Write-Host "No VLAN allocation mode specified (static or dynamic)" -ForegroundColor Red
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra/vlanns-[' + $VLANPool + ']-' + $AllocMode + '.json?query-target=children&target-subtree-class=fvnsEncapBlk'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvnsEncapBlk | Select-Object -ExpandProperty attributes | Select-Object name, allocMode, from, to, dn 
    }

function Get-ACI-AAA-SecDomain
    {
    <#
    .SYNOPSIS
    Get all AAA Security Domains for the Fabric
    
    .DESCRIPTION
    Get all Fabric AAA Security Domains defined within the fabric.
    
    .EXAMPLE
    Get-ACI-AAA-SecDomain

    name   nameAlias descr dn                       
    ----   --------- ----- --                       
    all                    uni/userext/domain-all   
    common                 uni/userext/domain-common
    mgmt                   uni/userext/domain-mgt
    
    .NOTES
    General notes
    #>
    
    
    #URL to pool
    $PollURL = 'api/node/class/aaaDomain.json?order-by=aaaDomain.name|asc'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty aaaDomain | Select-Object -ExpandProperty attributes | Select-Object name, nameAlias, descr, dn        
    }

    function Get-ACI-AAA-SecRole
    {
    <#
    .SYNOPSIS
    Get all AAA Security Roles for the Fabric
    
    .DESCRIPTION
    Get all Fabric AAA Security Roles defined within the fabric.
    
    .EXAMPLE
    Get-ACI-AAA-SecRole

    name          : vmm-admin
    nameAlias     : 
    priv          : vmm-connectivity,vmm-ep,vmm-policy,vmm-protocol-ops,vmm-security
    roleIsBuiltin : yes
    descr         : 
    dn            : uni/userext/role-vmm-admin

    and more.....
    
    .NOTES
    General notes
    #>
    
    #URL to pool
    $PollURL = 'api/node/class/aaaRole.json?query-target-filter=ne(aaaRole.name,"read-only")&order-by=aaaRole.name'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty aaaRole | Select-Object -ExpandProperty attributes | Select-Object name, nameAlias, priv, roleIsBuiltin, descr, dn        
    }

    function Get-ACI-AAA-LocalUsers
    {
    <#
    .SYNOPSIS
    Get all AAA Local Users for the Fabric
    
    .DESCRIPTION
    Get all Fabric AAA Local Users defined within the fabric.
    
    .EXAMPLE
    Get-ACI-AAA-LocalUsers


    name          : admin
    nameAlias     : 
    lastName      : 
    firstName     : 
    email         : 
    phone         : 
    accountStatus : active
    expires       : no
    expiration    : never
    descr         : 
    dn            : uni/userext/user-admin

    and more.....
    
    .NOTES
    General notes
    #>
    
    #URL to pool
    $PollURL = 'api/node/class/aaaUser.json?order-by=aaaUser.name'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    Write-Output $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty aaaUser | Select-Object -ExpandProperty attributes | Select-Object name, nameAlias, lastName, firstName, email, phone, accountStatus, expires, expiration, descr, dn        

    }

    function Get-ACI-Security-Contract-All ([Parameter(ValueFromPipelineByPropertyName)][string]$Tenant)
    {
    <#
    .SYNOPSIS
    Get the ACI Security Contracts for a given Tenant
    
    .DESCRIPTION
    Get the ACI Security Contracts for a given Tenant
    
    .PARAMETER Tenant
    The ACI Fabric Tenant
    
    .EXAMPLE
    Get-ACI-Security-Contract-All -Tenant SnV

    name     nameAlias scope               dn                     
    ----     --------- -----               --                     
    web                context             uni/tn-SnV/brc-web     
    database           application-profile uni/tn-SnV/brc-database
    
    .NOTES
    General notes
    #>
    if (!($Tenant))
    {
    Write-Host "No Tenant specified" -ForegroundColor Red
    Break
    }
      
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '.json?query-target=children&target-subtree-class=vzBrCP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $RawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output ...
    Write-Output $RawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty vzBrCP | Select-Object -ExpandProperty attributes | Select-Object name, nameAlias, scope, dn
      
    }

    function Get-ACI-Security-Contract ([Parameter(ValueFromPipelineByPropertyName)][string]$Tenant, [string]$Contract)
    {
    <#
    .SYNOPSIS
    Get the ACI Security Contract detail for a given Tenant
    
    .DESCRIPTION
    Get the ACI Security Contract for a given Tenant
    
    .PARAMETER Tenant
    The ACI Fabric Tenant
    
    .PARAMETER Contract
    The contract name within the given Tenant
    

    .EXAMPLE
    
    .NOTES
    General notes
    #>
    if (!($Tenant))
    {
    Write-Host "No Tenant specified" -ForegroundColor Red
    Break
    }
    if (!($Contract))
    {
    Write-Host "No Contract specified" -ForegroundColor Red
    Break
    }
    
    
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '.json?query-target=children&target-subtree-class=vzBrCP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $RawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output ...
    Write-Output $RawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty vzBrCP | Select-Object -ExpandProperty attributes | Select-Object name, nameAlias, scope, dn
      
    }


###################################################################################################################
## Create functions
###################################################################################################################

# Create new Tenant (L1)
function New-ACI-Tenant ([string]$Tenant,[string]$Description)
    {
    <#
    .SYNOPSIS
    Create a new ACI tenant
    
    .DESCRIPTION
    Create a new ACI tenant
    
    .PARAMETER Tenant
    Tenant Name
    
    .PARAMETER Description
    Description of tenant
    
    .EXAMPLE
    New-ACI-Tenant -Tenant dejungle -Description 'Its a nightmare out there'
    
    .NOTES
    This function currently returns raw data.  This needs to be cleaned up.  However if it does not error, it has worked !
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '.json'
    $PollBody = '{"fvTenant":{"attributes":{"dn":"uni/tn-' + $Tenant + '","name":"' + $Tenant + '","descr":"' + $Description + '","rn":"' + $Tenant + '","status":"created"},"children":[]}}}'
    Try
        {
        $PollRaw = New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
      
        if(!($PollRaw.httpCode -eq 200))
            {Write-Host 'An error occured after calling the API.  Function failed.' -ForegroundColor Red
             # Needs better output here but for now output
             $PollRaw.httpCode
             $PollRaw
             Break
             }
        else {
             Get-ACI-Tenant | Where-Object {$_.Name -like $Tenant }
             }                 
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        }
    }

#
# Create new VRF (L2)
#
function New-ACI-VRF ([string]$Tenant,[string]$VRF,[string]$Description)
    {
    <#
    .SYNOPSIS
    Create a new VRF within a given tenant
    
    .DESCRIPTION
   Create a new VRF within a given tenant
    
    .PARAMETER Tenant
    Tenant Name
    
    .PARAMETER VRF
    New VRF name
    
    .PARAMETER Description
    New VRF description
    
    .EXAMPLE
    New-ACI-VRF -Tenant dejungle -VRF amazon -Description 'SA'
    
    .NOTES
    This function currently returns raw data.  This needs to be cleaned up.  However if it does not error, it has worked !
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    if (!($VRF))
        {
        Write-Host "No VRF specified"
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/ctx-' + $VRF + '.json'
    
    $PollBody = '{"fvCtx":{"attributes":{"dn":"uni/tn-' + $Tenant + '/ctx-' +$VRF + '","name":"' + $VRF + '","descr":"' + $Description + '","rn":"ctx-' +$VRF + '","status":"created"},"children":[]}}'
    Try
        {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        
        if(!($PollRaw.httpCode -eq 200))
            {Write-Host 'An error occured after calling the API.  Function failed.' -ForegroundColor Red
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Break
            }
        else {
            Get-ACI-VRF -Tenant $Tenant | Where-Object {$_.name -like $VRF }
            }           
        }
    Catch
        {
            Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        }
    }

#
# Create new Layer 3 Out (L3)
#
function New-ACI-L3out ([string]$Tenant,[string]$VRF,[string]$L3out,[string]$Description)
    {
    <#
    .SYNOPSIS
    Create a new L3out interface for a given Tenant

    * THIS FUNCTION IS INCOMPLETE - It need to add SVI info, interface binding, contracts etc.... needs a lot more work*
    
    .DESCRIPTION
    Create a new L3out interface for a given Tenant
    
    .PARAMETER Tenant
    Tenant Name

    .PARAMETER VRF
    VRF name within Tenant

    .PARAMETER L3out
    New L3out name
        
    .PARAMETER Description
    New L3out description
    
    .EXAMPLE
    New-ACI-L3out -Tenant dejungle -VRF amazon -L3out escapepod1 -Description 'its the only way out'
    
    .NOTES
    This function currently returns raw data.  This needs to be cleaned up.  However if it does not error, it has worked !
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    if (!($L3out))
        {
        Write-Host "No L3 Out Interface name specified"
        Break
        }
    if (!($VRF))
        {
        Write-Host "No VRF specified"
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/out-' + $L3out + '.json'
    
    $PollBody = '{"l3extOut":{"attributes":{"dn":"uni/tn-' + $Tenant + '/out-' + $L3out + '","name":"' + $L3out + '","rn":"out-' + $L3out + '","status":"created"},"children":[{"l3extRsEctx":{"attributes":{"tnFvCtxName":"' + $VRF + '","status":"created,modified"},"children":[]}}]}}'
    Try
        {
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        if(!($PollRaw.httpCode -eq 200))
            {Write-Host 'An error occured after calling the API.  Function failed.' -ForegroundColor Red
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Break
            }
        else {
            Get-ACI-L3out -Tenant $Tenant -L3out $L3out
            }           
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

# Create new Bridge Domain BD (L2)
function New-ACI-BD ([string]$Tenant,[string]$VRF,[string]$BD,[string]$L3out,[string]$SVI,[string]$SVIscope)
    {
    <#
    .SYNOPSIS
    Create a new Bridge Domain for a given Tenant and VRF.   Creates the SVI also
    
    .DESCRIPTION
    Create a new Bridge Domain for a given Tenant and VRF.   Creates the SVI also
    
    .PARAMETER Tenant
    The ACI Tenant name
    
    .PARAMETER VRF
    The ACI vrf within the Tenant
    
    .PARAMETER BD
    The Bridge Domain name
    
    .PARAMETER L3out
    The L3out interface to associate the BD with.  

    * NEED TO TEST MULTIPLES *
    
    .PARAMETER SVI
    The SVI interface is CIDR standard.   Such as 10.0.0.1/8 or 172.16.32.65/28
    
    .PARAMETER SVIscope
    This needs to be set to public (if you want the BD to be advertised and accessible externally) or private
    Function defaults to 'public'
    
    .EXAMPLE
    New-ACI-BD -Tenant dejungle -VRF amazon -BD 200-vcentre-drs-001 -L3out escapepod1 -SVI 3.3.3.1/28 -SVIscope public
    
    .NOTES
    
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    if (!($VRF))
        {
        Write-Host "No VRF specified"
        Break
        }
    if (!($BD))
        {
        Write-Host "No Bridge Domain (BD) name specified"
        Break
        }
    if (!($L3out))
        {
        Write-Host "No L3out specified"
        Break
        }
    if (!($SVI))
        {
        Write-Host "No SVI specified"
        Break
        }
    if (!($SVIscope))
        {
        Write-Host "Setting scope to public"
        $SVIscope = 'public'
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/BD-' + $BD + '.json'

    $PollBody = '
    {
        "fvBD": {
            "attributes": {
                "dn": "uni/tn-' +$Tenant + '/BD-' +$BD + '",
                "mac": "00:22:BD:F8:19:FF",
                "name": "' +$BD + '",
                "rn": "BD-' +$BD + '",
                "status": "created"
            },
            "children": [
                {
                    "fvSubnet": {
                        "attributes": {
                            "dn": "uni/tn-' +$Tenant + '/BD-' +$BD + '/subnet-[' +$SVI + ']",
                            "ctrl": "unspecified",
                            "ip": "' + $SVI + '",
                            "scope": "' +$SVIscope + '",
                            "rn": "subnet-[' +$SVI + ']",
                            "status": "created"
                        },
                        "children": []
                    }
                },
                {
                    "fvRsCtx": {
                        "attributes": {
                            "tnFvCtxName": "' +$VRF + '",
                            "status": "created,modified"
                        },
                        "children": []
                    }
                },
                {
                    "fvRsBDToOut": {
                        "attributes": {
                            "tnL3extOutName": "' +$L3out + '",
                            "status": "created"
                        },
                        "children": []
                    }
                }
            ]
        }
    }'
    
    Try
        {
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        
        if(!($PollRaw.httpCode -eq 200))
            {Write-Host 'An error occured after calling the API.  Function failed.' -ForegroundColor Red
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Break
            }
        else {
            Get-ACI-BD -Tenant $Tenant -BD $BD
            }
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

# Create new Application Profile (L3)
function New-ACI-AppProfile ([string]$Tenant,[string]$AP,[string]$Description)
{
    <#
    .SYNOPSIS
    Create a new ACI App Profile 
    
    .DESCRIPTION
    Create a new ACI App Profile
    
    .PARAMETER Tenant
    ACI Tenant name
    
    .PARAMETER AP
    New AppProfile name
    
    .PARAMETER Description
    New AppProfile description
    
    .EXAMPLE
    New-ACI-AppProfile -Tenant dejungle -AP LoHangingFruit 
    
    .NOTES
    
    #>
    
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    if (!($AP))
        {
        Write-Host "No Application Profile specified"
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $AP + '.json' 
    $PollBody = '{"fvAp":{"attributes":{"dn":"uni/tn-' + $Tenant + '/ap-' + $AP + '","name":"' + $AP + '","rn":"ap-' + $AP + '","descr":"' + $Description + '","status":"created"},"children":[]}}'

    Try
        {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody

        if(!($PollRaw.httpCode -eq 200))
            {Write-Host 'An error occured after calling the API.  Function failed.' -ForegroundColor Red
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Break
            }
        else {
            Get-ACI-AppProfile -Tenant $Tenant -AP $AP
            }           
        }

    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
}

# Create new EPG (L4)
function New-ACI-EPG ([string]$Tenant,[string]$AP,[string]$EPG,[string]$BD,[string]$Description)
{
    <#
    .SYNOPSIS
    Create a new ACI EPG
    
    .DESCRIPTION
    Create a new ACI EPG
    
    .PARAMETER Tenant
    ACI Tenant
    
    .PARAMETER AP
    Existing AP under Tenant
    
    .PARAMETER EPG
    New EPG name
    
    .PARAMETER BD
    Existing Bridge Domain to associate with
    
    .PARAMETER Description
    New EPG description
    
    .EXAMPLE
    New-ACI-EPG -Tenant dejungle -AP LoHangingFruit -EPG UmBongo -BD 200-vcentre-drs-001
    
    .NOTES
    General notes
    #>
    
    if (!($Tenant))
    {
        Write-Host "No Tenant specified"
        Break
    }
    if (!($AP))
    {
        Write-Host "No Application Profile specified"
        Break
    }
    if (!($EPG))
    {
        Write-Host "No EPG specified"
        Break
    }
    if (!($BD))
    {
        #No Bridge Domain specified. Use default
        $BD = "default"
    }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $AP + '/epg-' + $EPG + '.json'
    $PollBody = '{"fvAEPg":{"attributes":{"dn":"uni/tn-' + $Tenant + '/ap-' + $AP + '/epg-' + $EPG + '","name":"' + $EPG + '","rn":"epg-' + $EPG + '","descr":"' + $Description + '","status":"created"},"children":[{"fvRsBd":{"attributes":{"tnFvBDName":"' + $BD + '","status":"created,modified"},"children":[]}}]}}'
    
    Try
    {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody

        if(!($PollRaw.httpCode -eq 200))
        {   Write-Host 'An error occured after calling the API.  Function failed.' -ForegroundColor Red
            # Needs better output here but for now output
            $PollRaw.httpCode
            $PollRaw
            Break
            }
        else {
            Get-ACI-EPG -Tenant $Tenant -AP $AP -EPG $EPG 
            }           
     }
    Catch
    {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
    }
}

# Create a new VPC interface (Fabric)
# - all in one, interfaces and switch association
#
function New-ACI-Interface-VPC
    (
    [string]$hostname,
    [string]$bondname,
    [string]$minidesc,
    [string]$AEEP,
    [string]$LinkLevel,
    [string]$LACP,
    [string]$CDP,
    [string]$LLDP,
    [string]$FromPort,
    [string]$ToPort,
    [string]$Switch)
    {
    <#
    .SYNOPSIS
    Create a new VPC interface definition for a host and associate to the fabric.

    We use the hostname, bondname and minidisc to create a unique identifier.  These get stored in the format of  'hostname-bondname-minidesc'

    An example could be 'ydclwp001-bond0-azweb1'
    
    .DESCRIPTION
    Create a new VPC interface definition for a host and associate to the fabric.

    We use the hostname, bondname and minidisc to create a unique identifier.  These get stored in the format of  'hostname-bondname-minidesc'

    An example could be 'ydclwp001-bond0-azweb1'
    
    
    .PARAMETER hostname
    The device hostname
    
    .PARAMETER bondname
    The agregated interface name.  For instance you could use use 'bond0', 'gec001' or similar
    
    .PARAMETER minidesc
    This is a short interface description.  No spaces or funny chars.   Use a project/service such as POC, PROD, YDC or similar
    
    .PARAMETER AEEP
    The AEEP which you want to associate the VPC with
    
    .PARAMETER LinkLevel
    Link Level Policy to use
    
    .PARAMETER LACP
    The LACP policy to use
    
    .PARAMETER CDP
    The CDP policy to use
    
    .PARAMETER LLDP
    The LLDP policy to use
    
    .PARAMETER FromPort
    Start Port number.   Single numeric (ie 1   or   48)
    
    .PARAMETER ToPort
    End Port number.   Single numeric (ie 4   or   48)
    
    .PARAMETER Switch
    The Leaf Switch name (usually a VPC pair) to associate with
    
    .EXAMPLE
    New-ACI-Interface-VPC -hostname host099 -bondname bond0 -minidesc DevOpsLab -AEP vcentre.aeep 
     -LinkLevel default -LACP LACP_active_nostandby -CDP default -LLDP default -Switch Leaf101-102_VPC_Profile 
     -FromPort 5 -ToPort 8
    
    .NOTES
    
    #>
    
    if (!($hostname))
        {
        Write-Host "No Hostname specified" -ForegroundColor Red
        Break
        }
    if (!($bondname))
        {
        Write-Host "No bondname specified (use 'bond0' is suggested)" -ForegroundColor Red
        Break
        }
    if (!($minidesc))
        {
        Write-Host "No mini description given (use a project/service such as POC, PROD, YDC or similar)" -ForegroundColor Red
        Write-Host "This is appended to the end of the interface name" -ForegroundColor Red
        Break
        }
    # Munge the elements the name ydclwp001-bond0-azweb1
    $IntName = $hostname + '-' + $bondname + '-' + $minidesc
    #Write-Host $IntName

    #Phase 1 - Create the Fabric Interface Policy Group
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/infra/funcprof/accbundle-' + $IntName + '.vpc.json'
    #Body left as fully spaced to make easier to read
    $PollBody = '
        {
        "infraAccBndlGrp": {
        "attributes": {
        "dn": "uni/infra/funcprof/accbundle-' + $IntName + '.vpc",
        "lagT": "node",
        "name": "' + $IntName + '.vpc",
        "rn": "accbundle-' + $IntName + '.vpc",
        "status": "created"
        },
        "children": []
        }},
        {
        "infraRsAttEntP": {
        "attributes": {
        "tDn": "uni/infra/attentp-' + $AEEP + '",
        "status": "created,modified"
        },
        "children": []
        }},
        "infraRsHIfPol": {
        "attributes'': {
        "tnFabricHIfPolName": "' + $LinkLevel + '",
        "status": "created,modified"
        },
        "children": []
        }},
        "infraRsLacpPol": {
        "attributes": {
        "tnLacpLagPolName": "' + $LACP + '",
        "status": "created,modified"
        },
        "children": []
        }},
        "infraRsCdpIfPol": {
        "attributes": {
        "tnCdplfPolName": "' + $CDP + '",
        "status": "created,modified"
        },
        "children": []
        }},
        "infraRsLldpIfPol": I
        "attributes": {
        "tnLldplfPolName": "' + $LLDP + '",
        "status": "created,modified"
        },
        "children": []
        }}]}}'
    Write-Host '-P1'
    Try
        {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson
    }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    
    # Phase 2 - Create the Fabric Interface Profile and Interface Selector
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/infra/accportprof-' + $IntName + '.ifprofile.json'
    # Body left, as fully spaced to make easier to read
    $PollBody = '
        {
        "infraAccPortP": {
        "attributes": {
        "dn": "uni/infra/accportprof-' + $IntName + '.ifprofile",
        "name": "' + $IntName + '.ifprofile",
        "rn": "accportprof-' + $IntName + '.ifprofile",
        "status": "created,modified"
        },
        "children": [
        {
        "infraHPortS": {
        "attributes": {
        "dn": "uni/infra/accportprof-' + $IntName + '.ifprofile/hports-' + $IntName + '.ifselector-typ-range",
        "name": "' + $IntName + '.ifselector",
        "rn": "hports-' + $IntName + '.ifselector-typ-range",
        "status": "created,modified"
        },
        "children": [
        {
        "infraPortBlk": {
        "attributes": {
        "dn": "uni/infra/accportprof-' + $IntName + '.ifprofile/hports-' + $IntName + '.ifselector-typ-range/portblk-block2",
        "fromPort": "' + $FromPort + '",
        "toPort": "' + $ToPort + '",
        "name": "block2",
        "rn": "portblk-block2",
        "status": "created, modified"
        },
        "children": []
        }
        },
        {
        "infraRsAccBaseGrp": {
        "attributes": {
        "tDn": "uni/infra/funcprof/accbundle-' + $IntName + '.vpc", 
        "status": "created,modified"
        },
        "children": []
        }
        }
        ]}}]}}'
    Write-host '-P2'
    Try
        {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    
    #Phase 3 - Create the Switch Profile association
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/infra/nprof-' + $Switch + '.json'
    # Body left as fully spaced to make easier to read
    $PollBody = '
        {
        "infraRsAccPortP": {
        "attributes": {
        "tDn": "uni/infra/accportprof-' + $IntName + '.ifprofile",
        "status": "created,modified"
        },
        "children": []
        }}'
    Write-host '-P3'
    Try
        {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then convert to	POSH objects from JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson
        }	
    Catch	
        {	
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

#Create new Interface Profile (Fabric)
function New-ACI-Interface (
    [string]$Switch,
    [string]$ProfileName,
    [string]$LeafAccessPolicy,    
    [string]$FromPort,
    [string]$ToPort
    )

{
    <#
    .SYNOPSIS
    Function to add standard devices to individial switches
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Switch
    The switch object name to define the interfaces for.   This can be found by using Get-ACI-Fabric-Switch-Leaf
    
    .PARAMETER ProfileName
    The specfic Leaf Interface Policy that has been already assigned to a leaf switch.  Typically only one per switch is defined.  This can be found using the 
    Get-ACI-Fabric-Switch-Leaf-IntProfiles
    
    .PARAMETER LeafAccessPolicy
    The name you want to call the group of interfaces.  
    
    .PARAMETER FromPort
    Switch Port Start number (1-48 ?)
    
    .PARAMETER ToPort
    Switch Port End number (1-48 ?)
    
    .EXAMPLE
    New-ACI-Interface -ProfileName Leaf102_InterfacePolicy -FromPort 39 -ToPort 41 -Switch LEAF_A102 -LeafAccessPolicy db.servers.fe.AccessPortSelector

    This adds port 39 - 41 to Leaf 102's interface selection policy and names it db.servers.fe.AccessPortSelector
    
    .NOTES
    Usually used for non multihomed servers, non LACP/VPC interfaces or managment ilo/cimc/drac connections
    #>
        
    if (!($ProfileName))
    {
        Write-Host "No Leaf Interface Profile Name specified"
        Break
    }
    ##########################
    #Phase 1 - Create and define the profiles
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/infra/accportprof-' + $ProfileName + '/hports-' + $LeafAccessPolicy + '-typ-range.json' 
    $PollBody ='
        {
            "infraHPortS": {
                "attributes": {
                    "dn": "uni/infra/accportprof-' + $ProfileName + '/hports-' + $LeafAccessPolicy + '-typ-range",
                    "name": "' + $LeafAccessPolicy + '",
                    "rn": "hports-' + $LeafAccessPolicy + '-typ-range",
                    "status": "created,modified"
                },
                "children": [
                    {
                        "infraPortBlk": {
                            "attributes": {
                                "dn": "uni/infra/accportprof-' + $ProfileName + '/hports-' + $LeafAccessPolicy + '-typ-range/portblk-block2",
                                "fromPort": "' + $FromPort + '",
                                "toPort": "' + $ToPort + '",
                                "name": "block2",
                                "rn": "portblk-block2",
                                "status": "created,modified"
                            },
                            "children": []
                        }
                    },
                    {
                        "infraRsAccBaseGrp": {
                            "attributes": {
                                "tDn": "uni/infra/funcprof/accportgrp-' + $LeafAccessPolicy + '",
                                "status": "created,modified"
                            },
                            "children": []
                        }
                    }
                ]
            }
        }
        '
    try {
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then convert to PoSH objects from, JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson    
    }
    Catch
    {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host 'This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
    }    
}

function New-ACI-AAA-LocalUser 
    (
    [string]$Username,
    [string]$FirstName,
    [string]$LastName,
    [string]$Password,
    [string]$email,
    [string]$phone,
    [string]$SecDomain,
    [string]$SecRole,
    [string]$SecPriv,
    [string]$Description)
    {
    <#
    .SYNOPSIS
    Module for adding an AAA local user to ACI Fabric
    
    .DESCRIPTION
    Module for adding an AAA local user to ACI Fabric
    
    .PARAMETER Username
    Username in legal format
    
    .PARAMETER FirstName
    First/Given Name
    
    .PARAMETER LastName
    Surname
    
    .PARAMETER Password
    Password in plain text form.  Remember ACI complexity may be set !
    
    .PARAMETER email
    email address
    
    .PARAMETER phone
    Phone Number
    
    .PARAMETER SecDomain
    Security Domain to add to.  Usually something like 'all'
    
    .PARAMETER SecRole
    Security Role to grant.  Usually 'admin'
    
    .PARAMETER SecPriv
    Security Privilage to grant.   Usually 'writePriv' or 'readPriv'
    
    .PARAMETER Description
    Description
    
    .EXAMPLE
    New-ACI-AAA-LocalUser -Username admin2 -Password Rh0n3!R1vrzz -SecDomain all -SecRole admin -SecPriv writePriv
    
    .NOTES
    General notes
    #>
        
    if (!($Username))
        {
        Write-Host "No Username specified"
        Break
        }
    if (!($Password))
        {
        Write-Host "No User Password specified"
        Break
        }
    if (!($SecDomain))
        {
        Write-Host "No User Security Domain specified.    all suggested"
        Break
        }
    if (!($SecRole))
        {
        Write-Host "No User Security Role specified.    admin suggested"
        Break
        }
    if (!($SecPriv))
        {
        Write-Host "No User Security Privilage specified.   writePriv suggested"
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/userext/user-' + $Username + '.json'
    $PollBody = '
    {
        "aaaUser": {
            "attributes": {
                "dn": "uni/userext/user-' + $Username + '",
                "name": "' + $Username + '",
                "rn": "user-' + $Username + '",
                "status": "created",
                "pwd": "' + $Password + '"
            },
            "children": [
                {
                    "aaaUserDomain": {
                        "attributes": {
                            "dn": "uni/userext/user-' + $Username + '/userdomain-' + $SecDomain + '",
                            "name": "' + $SecDomain + '",
                            "status": "created,modified"
                        },
                        "children": [
                            {
                                "aaaUserRole": {
                                    "attributes": {
                                        "dn": "uni/userext/user-' + $Username + '/userdomain-' + $SecDomain + '/role-' + $SecRole + '",
                                        "name": "' + $SecRole + '",
                                        "privType": "' + $SecPriv + '",
                                        "status": "created,modified"
                                    },
                                    "children": []
                                }
                            }
                        ]
                    }
                }
            ]
        }
    }
    '
    Try
        {
        #Munge URL
        $PollRaw = New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson 
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }




###################################################################################################################
## Update/Modify functions
###################################################################################################################

# Update an existing EPG (L3)
function Update-ACI-EPG ([string]$Tenant,[string]$AP,[string]$EPG,[string]$Domain,[string]$Contract,[string]$ContractType)
{
    <#
    .SYNOPSIS
    Update an existing ACI EPG
    
    .DESCRIPTION
    Update an existing ACI EPG
    
    .PARAMETER Tenant
    Existing ACI Tenant
    
    .PARAMETER AP
    Existing AppProfile within Tenant
    
    .PARAMETER EPG
    Existing EPG within AppProfile.  The one you want to update.
    
    .PARAMETER Domain
    An ACI Physical Domain you wish to assocate the EPG with.  These link the AEEP with Vlan Pools and are usually created at Fabric creation.
    
    .PARAMETER Contract
    An ACI contract you wish to assocate to the EPG
    
    .PARAMETER ContractType
    The method of contract application.   'p' is provided and 'c' is consumed.
    
    .EXAMPLE
    
    
    .NOTES
    
    #>
    
    if (!($Tenant))
    {
        Write-Host "No Tenant specified"
        Break
    }
    if (!($AP))
    {
        Write-Host "No Application Profile specified"
        Break
    }
    if (!($EPG))
    {
        Write-Host "No EPG specified"
        Break
    }
    if ($Domain)
    {
        # Add domain binding
        
        #Define URL to pool
        $PollURL  = 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $AP + '/epg-' + $EPG + '.json'
        $PollBody = '{"fvRsDomAtt":{"attributes":{"resImedcy":"immediate","tDn":"uni/phys-' + $Domain + '.domain","status":"created"},"children":[]}}'
        Try
            {
            #Munge URL
            $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
            #Poll the URL via HTTP then convert to PoSH objects from JSON
            $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
            #Needs output validation here.  For now echo API return
            Write-Host $APIRawJson
            }
        Catch
            {
            Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
            Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
            }
        #Exit at this point
        Break
    }
    if ($Contract)
    {
        # Add contract to EPG
        # First check contract type etc
        if (!($ContractType))
        {
            Write-Host "No contract type specified. Must be P/p (Provided) or C/c (Consumed)"
            Break
        }
        
        if ( (!($ContractType.ToLower()) -like 'c') -or (!($ContractType.ToLower()) -like 'p') )
        {
            Write-Host "No contract type specified. Must be P/p (Provided) or C/c (Consumed)"
            Break
        }
        
        if ($ContractType -like 'c') {$ContractMethod = 'fvRsCons'} 
        if ($ContractType -like 'p') {$ContractMethod = 'fvRsProv'}
        
        #Add the contact, in the relevant direction/mode
        #Define URL to pool
        $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $AP + '/epg-' + $EPG + '.json'
        $PollBody = '{"' + $ContractMethod + '":{"attributes":("tnYzBrCPName":"' + $Contract + '","status":"created,modified"},"children":[]}}'
        Try
        {
            #Munge URL
            $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
            #Poll the URL via HTTP then convert to PoSH objects from JSON
            $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        }
        Catch
        {
            Write-Host 'An error occured whilst calling the API. Exception: ($.Exception.Message)' -ForegroundColor Red
            Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }
}

# Update an existing EPG to add port binding (L4)
function Update-ACI-EPG-PortBinding ([string]$Tenant,[string]$AP,[string]$EPG,[string]$VLAN,[string]$PortType,[string]$Switch,[string]$Port)
{
    <#
    .SYNOPSIS
    Update an EPG to add port binding.   This is used to associate fabric interface configuration with tenant's.

    This is repetative task in ACI so can assist greatly with automation.  Yay.
    
    .DESCRIPTION
    Update an EPG to add port binding.   This is used to associate fabric interface configuration with tenant's.

    This is repetative task in ACI so can assist greatly with automation.  Yay.
    
    .PARAMETER Tenant
    Existing ACI Tenant
    
    .PARAMETER AP
    Existing AP
    
    .PARAMETER EPG
    Existing EPG - the target of this configuration update
    
    .PARAMETER VLAN
    The vlan number to add
    
    .PARAMETER PortType
    The type of interface association you want.  Should be 'untagged', '802.1p' or 'vpc'
    
    .PARAMETER Switch
    The ACI switch node ID to assocate with.  Should be numeric (ie 107) or VPC range (107-108)
    
    .PARAMETER Port
    The ACI switch port number/s.  Should be numeric (ie 1/43 or 1/45-48) or VPC interface name (107-108)
    
    .EXAMPLE
        
    .NOTES
    
    #>
    
    if (!($Tenant))
    {
        Write-Host "No Tenant specified"
        Break
    }
    if (!($AP))
    {
        Write-Host "No Application Profile specified"
        Break
    }
    if (!($EPG))
    {
        Write-Host "No EPG specified"
        Break
    }
    if (!($VLAN))
    {
        Write-Host "No VLAN specified"
        Break
    }
    if (!($PortType))
    {
        Write-Host "No Port Type specified - Should be untagged, 802.1p or vpc"
        Break
    }
    if (!($Switch))
    {
        Write-Host "No switch ID specified - Should be numeric (ie 107) or VPC range (107-108)"
        Break
    }
    if (!($Port))
    {
        Write-Host "No port specified - Should be numeric (ie 1/43 or 1/45-48) or VPC interface name (107-108)"
        Break
    }
    
    #Just in case, munge the port type
    $PortType = $PortType.ToLower()
    
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $AP + '/epg-' + $EPG + '.json'
    
    If ($PortType -eq 'untagged')
    {
        # Add static port binding
        $PollBody = '{"fvRsPathAtt":{"attributes":("encap":"vlan-' + $VLAN + ',"mode":"untagged","tDn":"topology/pod-l/paths-' + $Switch + '/pathep-[eth' + $Port + ']","status":"created"),"children":[]}}'
    }
    ElseIf ($PortType -eq '802.1p')
    {
        # Add 802.1p/native vlan port binding
        $PollBody = '{"fvRsPathAtt":{"attributes":{"encap":"vlan-' + $VLAN + ',"mode":"native","tDn":"topology/pod-l/paths-' + $Switch + '/pathep-[eth' + $Port + ']","status":"created"},"children":[]}}'
    }
    ElseIf ($PortType -eq 'vpc')
    {
        # Add VPC port binding
        $PollBody = '{"fvRsPathAtt":("attributes":{"encap":"vlan-' + $VLAN + '","tDn":"topology/pod-l/protpaths-' + $Switch + '/pathep-[' + $Port + '.vpc]","status":"created"),"children":[]}}'	
    }	
    Else	
    {	
        # No port group method found	
        Write-Host "No correct port type." -ForegroundColor Red	
        Break	
    }	
    
    Try	
    {	
        #Munge URL	
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody	
        #Poll the URL via HTTP then convert to PoSH	objects from JSON ConvertFrom-Json
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson
    }	
    Catch	
    {	
        Write-Host 'An error occured whilst calling the API. Exception: ($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
    }
}
