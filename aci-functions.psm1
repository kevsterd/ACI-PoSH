###################################################################################################################
##
## ACI-Functions.psml
##
###################################################################################################################

#
# Part of ACI-PoSH, a set of functions to manipulate Cisco ACI from PowerShell  
#
# Origin were once from https://github.com/smitmartijn/public-powershell/blob/master/Cisco/aci-functions.ps1 a GitHub project by Martijn Smit
#
#   2018-12-31      KPI   Initial External Release
#

#	Declarations

# This is where we save the cookies !
 $global:ACIPoSHCookieJar = New-Object System.Net.CookieContainer
 $global:ACIPoSHAPIC = '' 
 $global:ACIPoSHLoggedIn  = $False
 $global:ACIPoSHLoggingIn = $False

##
## Function to call APIC REST API calls from other scripts
##
Function New-ACI-Api-Call  
	([string]$method, 
	 [string]$encoding, 
	 [string]$url, 
	 $headers, 
	 [string]$postData)
{
<#
.SYNOPSIS
A module to make a RESTful API call to the Cisco ACI APIC infrastucture

.DESCRIPTION
A module to make a RESTful API call to the Cisco ACI APIC infrastucture

.PARAMETER method
The HTTP method you wish to use, such as GET, POST, DELETE etc.  Not all are supported by APIC

.PARAMETER encoding
The encoding method used to communicate with the APIC

.PARAMETER url
The specific URL to connect to

.PARAMETER headers
HTTP headers for the session

.PARAMETER postdata
A blob of data (usually JSON) typically for a POST

.EXAMPLE
To be added

.NOTES
General notes
#>
	$return_value = New-Object PsObject -Property @{httpCode =""; httpResponse =""} 
		Try
		{
			## Create the request
			[System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($url)
			#
			# Ignore SSL certificate errors
			[System.Net.ServicePointManager]::ServerCertificateValidationCallback ={$true}
			[System.Net.ServicePointManager]::SecurityProtocol = 3072 # <-- ACI NEEDS THIS

			# We want cookies!
			$request.CookieContainer = $global:ACIPoSHCookieJar
		}
		Catch
		{
			Write-Host "An error occured with the initial connection to the APIC. Exception: $($_.Exception.Message)"
			Write-Host "Please try again." -ForegroundColor Red
			Break
		}
		
		## Add the method (GET, POST, etc.)
		$request.Method = $method
		
		## Add an headers to the request
		ForEach($key in $headers.keys)
		{
			$request.Headers.Add($key, $headers[$key])
		}
		
		## If we're logged in, add the saved cookies to this request
		If ($global:ACIPoSHLoggedIn -eq $True)
			{
			$request.CookieContainer = $global:ACIPoSHCookieJar
			$global:ACIPoSHLoggingIn = $False
			}
		else
			{
			## We're not logged in to the APIC, start login first
			if($global:ACIPoSHLoggingIn -eq $False)
				{
				$global:ACIPoSHLoggingIn = $True
				Write-Host ""
				Write-Host "Not currently logged into APIC. Re-authenticate using the New-ACI-Login commandlet " -ForegroundColor Yellow
				Break
				}
			}
		
		## We are using $encoding for the request as well as the expected response
		 $request.Accept = $encoding
		## Send a custom user agent to ACI
		 $request.UserAgent = "ACIPoSH Script"
		## Create the request body if the verb accepts it (NOTE: utf-8 is assumed here) 
		if ($method -eq "POST" -or $method -eq "PUT")
			{
			$bytes = [System.Text.Encoding]::UTF8.GetBytes($postData)
			$request.ContentType = $encoding
			$request.ContentLength = $bytes.Length
		
			try
				{
				[System.IO.Stream] $outputStream =
				[System.IO.Stream]$request.GetRequestStream()
				$outputStream.Write($bytes,0,$bytes.Length)
				$outputStream.Close()
				}
			catch
				{
				Write-Host "An error occured creating the stream connection. Please try again" -ForegroundColor Red
				Break
				}
			}
		
		##	This is where we actually make the call.
		try
			{
			[System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()

			foreach($cookie in $response.Cookies)
			{
				## We've found the APIC cookie and can conclude our login business
				if($cookie.Name -eq "APIC-cookie")
					{
					$global:ACIPoSHLoggedIn = $True 
					$global:ACIPoSHLoggingIn = $False
					}	
			}	
		
		$sr = New-Object System.IO.StreamReader($response.GetResponseStream())
		$txt = $sr.ReadToEnd()
		#Write-Debug "CONTENT-TYPE: " $response.ContentType
		#Write-Debug "RAW RESPONSE DATA:" . $txt
		## Return the response body to the caller
		$return_value.httpResponse = $txt
		$return_value.httpCode = [int]$response.StatusCode
		return $return_value
		}

		## This catches errors from the server (404, 500, 501, etc.)
		catch [Net.WebException] {
			[System.Net.HttpWebResponse] $resp = [System.Net.HttpWebResponse] $_.Exception.Response
		#Write-Debug $resp.StatusCode -ForegroundColor Red -BackgroundColor Yellow
		#Write-Debug $resp.StatusDescription -ForegroundColor. Red -BackgroundColor Yellow
		## Return the error to the caller
		## If the APIC returns a 403, the session most likely has been expired. Login again and rerun the API call
		if($resp.StatusCode -eq 403)
			{
			# We do this by resetting the global login variables and simply call the ACI-API-Call function again
			$global:ACIPoSHLoggedIn = $False
			$global:ACIPoSHLoggingIn = $False
			New-ACI-Api-Call $method $encoding $url $headers $postData
			}
		$return_value.httpResponse = $resp.StatusDescription
		$return_value.httpCode = [int]$resp.StatusCode
		return $return_value
		}
	}
	
## Function to login to ACI and store credentials in cookies (method used by APIC authentication)
Function New-ACI-Login
	([string]$Apic, 
	 [String]$Username, 
	 [String]$Password,
	 [String]$StoreLocation)
{
<#
.SYNOPSIS
A module to authenticate to Cisco ACI APIC infrastucture

.DESCRIPTION
A module to authenticate to Cisco ACI APIC infrastucture

.PARAMETER Apic
The APIC you wish to connect to.  Can be a hostname, FQDN or even IP address.   HTTPS is always assumed.

.PARAMETER Username
The username to connect to the APIC with.   Must be defined in ACI or downstream AAA as a valid user AND have access.

.PARAMETER Password
The password for the username specified.

.PARAMETER StoreLocation
(Optional) A location a hashed password is stored.  This can be useful for automation tasks.

.EXAMPLE
New-Aci-Login -Apic MyAPIC -Username MyUsername -Password MyPassword

.NOTES
General notes
#>
	##Check if an APIC was specified.
	if (!($Apic))
		{
		# No pipeline APIC specified so check for global varible
		If (!($global:ACIPoSHAPIC))
			{
			#No global APIC defined so prompt
			#$Apic = Read-Host -Prompt "No APIC was specified.	Please enter either hostname or IP address "
			Write-Host "No APIC specified. Trying APIC"
			$Apic = "apic"
			}
		}
	
	## Save the APIC name as a global var for the session
	$global:ACIPoSHAPIC = $apic
	
	if (!($UserName))
		{
		## Assume no username specified so extract from Windows which should be the same credential
		$UserName = $env:USERNAME
		}
	if (!($StoreLocation))
		{
		## No credentail store location specified so check for password
		if (!($Password))
			{
			## No password specified thus prompt
			$Password = Read-Host -Prompt "No password or credential file was specified as an argument. Please enter your password "
			## Clear screen just to remove from console view
			Clear-Host
			}
		}
	else
		{
		## Credential Stored file specified, so extract the password. This is not a straightforward operation !
		## Import the encrpted password and convert to a Secure String
		try
			{
			$SecPass = (ConvertTo-SecureString (Get-Content $StoreLocation))
			} 
		catch
			{
			write-host "Password file access failed. It may be missing. Please try again" -ForegroundColor Red
			Break
			}
	
		## Instansiate a new PS credential object.	This is the only way to extract the PT
		try
			{
			$SecCred = New-Object system.management.automation.pscredential -ArgumentList $UserName,$SecPass
			}
		catch
			{
			write-host "Extraction of credential failed. Its contents are probably not valid. Please try again" -ForegroundColor Red
			Break
			}
		## Extract the PT password from the credential
		try
			{
			$Password = $SecCred.GetNetworkCredential().Password
			}
		catch
			{
			write-host "Extraction of password failed. Please try again" -ForegroundColor Red
			Break
			}
		}
	
		## Set the logging in flag
		$global:ACIPoSHLoggingIn = $True
		## This is the URL we're going to be logging in to
		$loginurl = "https://" + $apic + "/api/aaaLogin.xml"
		## Format the XML body for a login
		$creds = '<aaaUser name="' + $UserName + '" pwd="' + $Password + '"/>'
		## Execute the API Call
		$result = New-ACI-Api-Call "POST" "application/xml" $loginUrl "" $creds
		if($result.httpResponse.Contains("Unauthorized"))
			{
			Write-Host "Authentication to APIC failed! Please check your credentials." -ForegroundColor Red
			}
		else
			{
			Write-Host "Authenticated!" -ForegroundColor Green
			}
		}