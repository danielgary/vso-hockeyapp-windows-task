param(
    [string]$appID, # HockeyApp App ID
    [string]$apiToken, #HockeyApp App Token
    [string]$packageDirectory = "../b/AppxPackages/",
    [string]$buildNumber = $env:BUILD_BUILDNUMBER
    )
    
 Write-Host "Build Number: $($buildNumber)"

$buildSourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Build.SourcesDirectory"

Write-Host "Changing directory to $($buildSourcesDirectory)"
Set-Location -Path $buildSourcesDirectory

#Compress output directory
Add-Type -A System.IO.Compression.FileSystem


$path = dir $packageDirectory -Directory | Select-Object -first 1
$zipPath = "$($buildSourcesDirectory)/upload.zip"
Write-Host "Zipping " + "$($packageDirectory)$($path.Name) into $($zipPath)"




[IO.Compression.ZipFile]::CreateFromDirectory("$packageDirectory$($path.Name)", $zipPath)


$zipFile = dir "$($buildSourcesDirectory)/upload.zip" -File | Select-Object -first 1

Write-Host "Zipped file: $($zipFile.name), Size: $($zipFile.length)"





#Get previous versions
$version_url = "https://rink.hockeyapp.net/api/2/apps/$($appID)/app_versions"
$versions = Invoke-RestMethod -Method GET -Uri $version_url -Header @{"X-HockeyAppToken" = $apiToken}


$existingVersion = $versions.app_versions[0]


#Default to version 1 unless others already exist
$nextVersion = 1

if($existingVersion)
{
     $nextVersion = 1 + $existingVersion.version
}
   

$create_url = "https://rink.hockeyapp.net/api/2/apps/$($appID)/app_versions/new"


$body = @{
    bundle_version = $nextVersion

}

#Create new version and get response object
$response = Invoke-RestMethod -Method POST -Uri $create_url  -Header @{ "X-HockeyAppToken" = $apiToken } -Body $body



$update_url = "https://rink.hockeyapp.net/api/2/apps/$($appID)/app_versions/$($response.id)"

$file = @{
    ipa="upload.zip"
}

$body = @{
    ipa="@upload.zip"
    status = 2
    notify = 1
}


#Upload upload.zip file
$curlCommand = @'
curl -k -F ipa=@upload.zip  -X PUT -F "status=2" -F "notify=1" -H "X-HockeyAppToken: 
'@ + $apiToken + '" ' + $update_url


$output = (cmd /c $curlCommand 2`>`&1)