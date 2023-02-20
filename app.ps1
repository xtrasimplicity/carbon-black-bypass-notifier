[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$orgId = ""
$apiSecret = ""
$apiClientID = ""
$states = @("BYPASS", "BYPASS_ON")
$apiEndpoint = "defense-prod05.conferdeploy.net"
$senderAddress = ""
$recipientAddress = ""
$smtpServer = ""


###############
#  Main Code  #
###############
$scriptOutput = "";

function WriteToVarAndConsole([ref]$targetVar, [string]$message) {
   $targetVar.Value = -Join($targetVar.Value, "<br />", $message);

   Write-Host $message;
}

function sendMail
{
   param($to, $from, $subject, $message)

   # Build anonymous credentials, otherwise it uses Windows authentication details. :/
   $anonUsername = "anonymous"
   $anonPassword = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
   $anonCredentials = New-Object System.Management.Automation.PSCredential($anonUsername,$anonPassword)

   Send-MailMessage -To $to -From $from -Subject "$subject" -Body "$message" -BodyAsHtml -SmtpServer $smtpServer -credential $anonCredentials
}

function Fetch-Sensors-With-States {
    param(
        [string]$endpoint,
        [string]$organisationId,
        [string]$apiSecret,
        [string]$apiClientId,
        [string[]]$states
    )


   $headers = @{
    "X-Auth-Token" = "$($apiSecret)/$($apiClientID)"
    "Content-Type" = "application/json"
   }

   $url = "https://$($endpoint)/appservices/v6/orgs/$($organisationId)/devices/_search"
   $requestBody = '{"criteria": { "deployment_type": ["ENDPOINT"], "status": ' + ($states | ConvertTo-Json) + '}}'

   try {
    $result = Invoke-WebRequest -UseBasicParsing $url -Method POST -Body $requestBody -Headers $headers -ErrorAction Continue -WarningAction Continue

       if (! $result.StatusCode -eq 200) {
        Write-Host "Something went wrong! Server responded with HTTP code $($result.StatusCode) - $($result.Content)."
        return
       }
   } catch {
        Write-Host "Something went wrong! Server responded with $($_)."
        return
   }

   $parsedResult = $result.Content | ConvertFrom-Json

   WriteToVarAndConsole ([ref]$scriptOutput) "Carbon Black reports that $($parsedResult.num_found) devices are set to bypass mode."

   return $parsedResult.results
}


WriteToVarAndConsole ([ref]$scriptOutput) "Checking Carbon Black for devices in bypassed state..."
$sensors = Fetch-Sensors-With-States $apiEndpoint $orgId $apiSecret $apiClientID $states

WriteToVarAndConsole ([ref]$scriptOutput) "Found $($sensors.Count) devices in API response`n`n"

writeToVarAndConsole ([ref]$scriptOutput) ($sensors | Format-Table -Property name,last_reported_time,os,os_version | Out-String)

WriteToVarAndConsole ([ref]$scriptOutput) "`n`nGood Bye!`nFYI this Script is running on $(hostname)"

sendMail -to $recipientAddress -from $senderAddress -subject "Carbon Black Sensor bypass status" -message $scriptOutput
