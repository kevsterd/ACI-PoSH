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
# 2.0 - 2019-01-03 - KPI - Initial GitHub Release
# 1.4 - 2018-11-05 - KPI - Code Tidy
# 1.3 - 2018-11-01 - KPI - Added further methods to create fabric interface associations - inc VPC
# 1.2 - 2018-10-30 - KPI - Added further methods to add fabric configuration (L2/L3)
# 1.1 - 2018-10-12 - KPI - Added further methods to view fabric (L2)
# 1.0 - 2018-02-23 - KPI - Initial Version
###################################################################################################################

##Read functions
function Get-ACI-Tenant
{
    ##
    ## Get ACI Tenants
    ##
    #Define URL to pool
    $PollURL = 'api/node/class/fvTenant.json'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $TenRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output ...
    $TenRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvTenant | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-AppProfile-All ([string]$Tenant)
    {
    #
    # Get All ACI App Profiles
    if (!($Tenant))
        {
        Write-Host "No Tenant specified" -ForegroundColor Red
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '.json?query-target=children&target-subtree-class=fvAp'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $ApRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $ApRawJson  | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvAp | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-AppProfile ([string]$Tenant,[string]$AP)
    {
    # Get ACI App Profile
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
    $ApRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvAEPg | Select-Object -ExpandProperty attributes | Select-Object name, prio, descr, dn
    }
function Get-ACI-EPG ([string]$Tenant,[string]$AP,[string]$EPG)
    {
    # Get ACI EPG
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
    #Define URL sets to pool
    #Base URL
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '/ap-' + $Ap + '/epg-' + $EPG + '.json'
    #Domain
    $PollURLDom	= $PollURL + '?query-target=children&target-subtree-class=fvRsDomAtt'
    #Static Paths
    $PollURLSPath = $PollURL + '?query-target=children&target-subtree-class=fvRsPathAtt' 
    #Contracts
    $PollURLContract = $PollURL + '?query-target=children&target-subtree-class=fvRsCons'
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
    $DomRawJson | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty fvRsDomAtt | Select-Object -ExpandProperty attributes | Select-Object tDn
    write-host ""
    write-host "Static Path Binding"
    write-host "-------------------"	
    $SPathRawJson | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty fvRsPathAtt | Select-Object -ExpandProperty attributes | Select-Object tDn , encap , mode
    write-host ""
    write-host "Contracts"	
    write-host "---------"		
    $ContractRawJson | Select-Object -ExpandProperty imdata | Select-Object -ExpandProperty fvRsCons | Select-Object -ExpandProperty attributes	
    }	

function Get-ACI-EPG-All ([string]$Tenant,[string]$AP)	
    {	
    # Get ACI EPG	
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
    $ApRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvAEPg | Select-Object -ExpandProperty attributes | Select-Object name, prio, descr, dn
    }

function Get-ACI-BD-All ([string]$Tenant)
    {
    # Get all ACI Bridge Domains for a given Tenant
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
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvBd | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-BD ([string]$Tenant,[string]$BD)
    {
    # Get all Bridge Domain policies for a given Tenant
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
    $OutRawJson	| Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvBd | Select-Object -ExpandProperty attributes | Select-Object name , descr, mtu, limitIpLearnToSubnets, arpFlood, dn
    Write-Host ""
    Write-Host "L3 Out Interfaces"
    Write-Host "-----------------"
    $OutRawJsonL3 | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvRsBDToOut | Select-Object -ExpandProperty attributes | Select-Object tnL3extOutName
    Write-Host ""
    Write-Host "Subnet Address"
    Write-Host "--------------"
    $OutRawJsonSub | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvSubnet	| Select-Object -ExpandProperty attributes | Select-Object ip, scope
    }

function Get-ACI-VRF ([string]$Tenant)
    {
    # Get VRF's for a given tenant
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant +'.json?query-target=children&target-subtree-class=fvCtx'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvCtx | Select-Object -ExpandProperty attributes | Select-Object name, descr, bdEnforcedEnable, pcEnfDir, pcEnfPref, dn | Format-Table
 }

function Get-ACI-L3out-All ([string]$Tenant)
    {
    # Get specific L3out for a given tenant
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
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty l3extOut | Select-Object -ExpandProperty attributes | Select-Object name, enforceRtctrl, descr, dn
    }
function Get-ACI-L3out ([string]$Tenant,[string]$L3out)
    {
    # Get specific L3out for a given tenant
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/tn-' + $Tenant + '/out-' + '.json?query-target=children&target-subtree-class=l3extRsEctx'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty l3extRsEctx | Select-Object -ExpandProperty attributes | Select-Object tRn, tnFvCtxName, descr, dn
    }
function Get-ACI-Fabric-AEEP
    {
    # Get AEEP's for Fabric

    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAttEntityP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraAttEntityP | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-Fabric-Port-LinkLevel
    {
    # Get Link Level Policies
    
    #Define URL to pool
    $PollURL = 'api/node/class/fabricHIfPol.json?query-target-filter=not(wcard(fabricHIfPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$pollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData  | Select-Object -ExpandProperty fabricHIfPol | Select-Object -ExpandProperty attributes | Select-Object name, speed, autoNeg, descr, dn | Format-Table
    }
 function Get-ACI-Fabric-Port-CDP
    {
    # Get CDP Policies
    #Define URL to pool
    $PollURL = 'api/node/class/cdpIfPol.json?query-target-filter=not(wcard(cdpIfPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output	
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty cdpIfPol | Select-Object -ExpandProperty attributes | Select-Object name, adminSt, descr, dn
    }	
function Get-ACI-Fabric-Port-LLDP	
    {	
    # Get LLDP Policies	
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=children&target-subtree-class=lldpIfPol&query-target-filter=not(wcard(lldpIfPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty lldpIfPol | Select-Object -ExpandProperty attributes | Select-Object name, adminRxSt, adminTxSt, descr, dn | Format-table
    }
function Get-ACI-Fabric-Port-LACP
    {
    # Get LACP Policies

    #Define URL to pool
    $PollURL = '/api/node/class/lacpLagPol.json?query-target-filter=not(wcard(lacpLagPol.dn,"__ui"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty lacpLagPol | Select-Object -ExpandProperty attributes | Select-Object name, mode, ctrl, minLinks, maxLinks, descr, dn | Format-Table
    }
function Get-ACI-Fabric-Switch-Leaf
    {
    # Get Leaf Switches and VPC's
    
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraNodeP&query-target-filter=not(wcard(infraNodeP.name,"__ui_"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraNodeP | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn
    }
function Get-ACI-Fabric-VLANPool-All
    {
    # Get VLAN Pools
    #Define URL to pool
    $PollURL = 'api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=fvnsVlanInstP'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvnsVlanInstP | Select-Object -ExpandProperty attributes | Select-Object name, allocMode, descr, dn | format-table
    }

function Get-ACI-Fabric-LeafAccessPolicy-All
    {
    # Get All Leaf Access Polcies
    
    #URL to pool
    $PollURL = 'api/node/mo/uni/infra/funcprof.json?query-target=subtree&target-subtree-class=infraAccPortGrp&query-target-filter=not(wcard(infraAccPortGrp.dn,"__ui_"))'
    #Munge URL
    $PollRaw = New-ACI-Api-Call -method GET -url https://$global:ACIPoSHAPIC/$PollURL
    #Poll the URL via HTTP then convert to PoSH objects from JSON 
    $OutRawJson = $PollRaw.httpResponse | ConvertFrom-Json
    #Output
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraAccPortGrp | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn | format-table
    }

function Get-ACI-Fabric-LeafAccessPolicy ([string]$LeafAccessPolicy)
    {
    #Get Leaf Access Polcies
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
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty infraAccPortGrp | Select-Object -ExpandProperty attributes | Select-Object name, descr, dn | format-table
    }

 function Get-ACI-Fabric-VLANPool ([string]$VLANPool,[string]$AllocMode)
    {
    # Get VLAN Pool
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
    $OutRawJson | Select-Object -ExpandProperty imData | Select-Object -ExpandProperty fvnsEncapBlk | Select-Object -ExpandProperty attributes | Select-Object name, allocMode, from, to, dn | Format-Table
    }

#
#---- Create functions
#

# Create new Tenant (L1)
function New-ACI-Tenant ([string]$Tenant,[string]$Description)
    {
    if (!($Tenant))
        {
        Write-Host "No Tenant specified"
        Break
        }
    #Define URL to pool
    $PollURL	= 'api/node/mo/uni/tn-' + $Tenant + '.json'
    $PollBody = '{"fvTenant":{"attributes":{"dn":"uni/tn-' + $Tenant + '","name":"' + $Tenant + '","descr":"' + $Description + '","rn":"' + $Tenant + '","status":"created"},"children":[]}}}'
    write-host $PollBody


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
        Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

#
# Create new VRF (L2)
#
function New-ACI-VRF ([string]$Tenant,[string]$VRF,[string]$Description)
    {
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
        #Poll the URL via HTTP then Convert to POSH objects from JSQN
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        write-host $APIRawJson
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

#
# Create new Layer 3 Out (L3)
#
function New-ACI-L3out ([string]$Tenant,[string]$L3out,[string]$VRF,[string]$Description)
    {
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
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then Convert to POSH objects from JSQN
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        write-host $APIRawJson
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

# Create new Bridge Domain BD (L2)
function New-ACI-BD ([string]$Tenant,[string]$VRF,[string]$BD,[string]$L3out,[string]$SVI,[string]$SVIscope)
    {
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
        #Munge URL
        $PollRaw	= New-ACI-Api-Call -method POST -url https://$global:ACIPoSHAPIC/$PollURL -postData $PollBody
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson
        }
    Catch
        {
        Write-Host 'An error occured whilst calling the API. Exception:$($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }

# Create new Application Profile (L3)
function New-ACI-AppProfile ([string]$Tenant,[string]$AP,[string]$Description)
{
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
    #Poll the URL via HTTP then convert to PoSH objects from JSON
    $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
    #Needs output validation here.  For now echo API return
    Write-Host $APIRawJson
    }

Catch
    {
    Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
    Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
    }
}

# Create new EPG (L4)
function New-ACI-EPG ([string]$Tenant,[string]$AP,[string]$EPG,[string]$BD,[string]$Description)
{
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
        #Poll the URL via HTTP then convert to PoSH objects from JSON
        $APIRawJson	= $PollRaw.httpResponse	| ConvertFrom-Json
        #Needs output validation here.  For now echo API return
        Write-Host $APIRawJson
    }
    Catch
    {
        Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
    }
}

##
## Update/Modify functions
##

# Update an existing EPG (L3)
function Update-ACI-EPG ([string]$Tenant,[string]$AP,[string]$EPG,[string]$Domain,[string]$Contract,[string]$ContractType)
{
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
            Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
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
            Write-Host 'An error occured whilst calling the API. Exception: $($.Exception.Message)' -ForegroundColor Red
            Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
        }
    }
}

# Update an existing EPG to add port binding (L4)
function Update-ACI-EPG-PortBinding ([string]$Tenant,[string]$AP,[string]$EPG,[string]$VIAN,[string]$PortType,[string]$Switch,[string]$Port)
{
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
        Write-Host 'An error occured whilst calling the API. Exception: $($_.Exception.Message)' -ForegroundColor Red
        Write-Host ' --- This is usually a typo or case issue, if you are sure you have the correct entries' -ForegroundColor Red
    }
}
