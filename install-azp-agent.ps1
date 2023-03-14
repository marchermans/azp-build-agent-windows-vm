[CmdletBinding()]
Param
(
  [Parameter(Mandatory = $true)]
  [string]$AzpAccount,

  [Parameter(Mandatory = $true)]
  [string]$PersonalAccessToken,

  [Parameter(Mandatory = $false)]
  [string]$PoolName = "Default",

  [Parameter(Mandatory = $false)]
  [string]$AgentName = ${Env:computername},

  [Parameter(Mandatory = $false)]
  [int]$downloadMaxRetries = 5,

  [Parameter(Mandatory = $false)]
  [int]$downloadRetrySleepSeconds = 15,

  [Parameter(Mandatory = $false)]
  [switch]$PrepareDataDisk = $false,

  [Parameter(Mandatory = $false)]
  [string]$AgentInstallationPath = 'C:\Azure-Pipelines-Agent',

  [Parameter(Mandatory = $false)]
  [string]$AgentWorkPath = "$AgentInstallationPath\_work"
)

$currentLocation = Split-Path -parent $MyInvocation.MyCommand.Definition
Write-Verbose "Current folder: '$currentLocation'." -verbose

if ($PrepareDataDisk) {
  $AgentInstallationPath = "P:\Azure-Pipelines-Agent"
  $AgentWorkPath = "$AgentInstallationPath\_work"
  $drive = Split-Path -Path $AgentInstallationPath -Qualifier

  if (-Not (Test-Path $drive)) {
    Write-Host "Prepare non existing data disk."
    $disk = Get-Disk |
      Where-Object PartitionStyle -eq 'RAW' |
      Where-Object Size -gt 0 |
      Sort-Object number |
      Select-Object -First 1

    $disk |
      Initialize-Disk -PartitionStyle MBR -PassThru |
      New-Partition -UseMaximumSize -DriveLetter $($drive[0]) |
      Format-Volume -FileSystem NTFS -NewFileSystemLabel "azp-datadisk" -Confirm:$false -Force
  }
}

Write-Verbose "Use Agent Install Path: '$AgentInstallationPath'."
Write-Verbose "Use Agent Work Path: '$AgentWorkPath'."

$agentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path "$agentTempFolderName"
Write-Verbose "Temporary Agent download folder: '$agentTempFolderName'." -verbose

$agentTempDownloadFilePath = "$agentTempFolderName\azp-agent.zip"

$retries = 1
Write-Host "Downloading Azure Pipelines Agent install files."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
do {
  try {
    Write-Verbose "Trying to get download URL for latest azure pipelines agent release..."
    $username = "user";

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$PersonalAccessToken)))

    $tfsUrl = "https://dev.azure.com/lichtblick"
    $arch="win-x64"
    $queryUrl="$tfsUrl/_apis/distributedtask/packages/agent?platform=$arch&top=1"

    $latestReleases = Invoke-RestMethod -Method Get -Uri $queryUrl -Headers @{Authorization = "Basic $base64AuthInfo" } -ContentType "application/json"
    $latestReleaseDownloadUrl = $latestReleases.value[0].downloadUrl

    Invoke-WebRequest -Uri $latestReleaseDownloadUrl -Method Get -OutFile "$agentTempDownloadFilePath"
    Write-Verbose "Downloaded agent successfully on attempt $retries" -verbose
    break
  }
  catch {
    $exceptionText = ($_ | Out-String).Trim()
    Write-Verbose "Exception occured downloading agent: $exceptionText in try number $retries" -verbose
    $retries++
    Start-Sleep -Seconds $downloadRetrySleepSeconds
  }
}
while ($retries -le $downloadMaxRetries)

Expand-Archive -Path "$agentTempDownloadFilePath" -DestinationPath "$AgentInstallationPath" -Force
Write-Verbose "Extracted content from '$agentTempDownloadFilePath' to '$AgentInstallationPath'." -verbose

Remove-Item -Recurse -Force "$agentTempDownloadFilePath"
Write-Verbose "Temporary Agent download folder deleted: '$agentTempDownloadFilePath'." -verbose

Write-Host "Configuring Azure Pipelines agent."

Push-Location "$AgentInstallationPath"

$AzpUrl = "https://dev.azure.com/$AzpAccount"

& .\config.cmd --unattended `
  --agent "$AgentName" `
  --url "$AzpUrl" `
  --auth PAT `
  --token "$PersonalAccessToken" `
  --pool "$PoolName" `
  --runAsService `
  --work "$AgentWorkPath" `
  --replace

Pop-Location
