$Tenant = 'AA-Hosting'
$dName = 'DEV'
$pName = 'PROD'
#
#Derived
$pFeAp =  $pName + '_FE'
$pBeAp =  $pName + '_BE'
$pFeWeb = $pFeAp + '-WEB'
$pFeLB =  $pFeAp + '-LB'
#


If (!(Get-ACI-Tenant | Where-Object {$_.Name -like $Tenant }))
    {New-ACI-Tenant -Tenant $Tenant -Description 'Top Tier Tenant'}

New-ACI-VRF -Tenant $Tenant -VRF $dName -Description ($Tenant + $dName)
New-ACI-VRF -Tenant $Tenant -VRF $pName -Description ($Tenant + $pName)

New-ACI-AppProfile -Tenant $Tenant -AP $pFeAp
New-ACI-AppProfile -Tenant $Tenant -AP $pBeAp

New-ACI-L3out -Tenant $Tenant -VRF $pName -L3out external_a
New-ACI-L3out -Tenant $Tenant -VRF $pName -L3out external_b

New-ACI-BD -Tenant $Tenant -VRF $pName -BD 1000-PROD-FE-WEB-DATA -L3out external_a -SVI 172.16.32.0/22 -SVIscope public
New-ACI-BD -Tenant $Tenant -VRF $pName -BD 1010-PROD-FE-LB-DATA -L3out external_a -SVI 172.16.64.0/22 -SVIscope public

New-ACI-EPG -Tenant $Tenant -AP $pFeAp -EPG $pFeWeb -BD 1000-PROD-FE-WEB-DATA
New-ACI-EPG -Tenant $Tenant -AP $pFeAp -EPG $pFeLB  -BD 1010-PROD-FE-LB-DATA

Update-ACI-EPG -Tenant $Tenant -AP $pFeAp -EPG $pFeWeb -ContractType Provided -Contract external.web.l3.contract -Domain phys
Update-ACI-EPG -Tenant $Tenant -AP $pFeAp -EPG $pFeWeb -ContractType Consumed -Contract external.lb.contract -Domain phys

Update-ACI-EPG-PortBinding -Tenant $Tenant -AP $pFeAp -EPG $pFeWeb -VLAN 1000 -PortType untagged -Switch A101 -Port 20-29
Update-ACI-EPG-PortBinding -Tenant $Tenant -AP $pFeAp -EPG $pFeWeb -VLAN 1000 -PortType untagged -Switch A102 -Port 20-29