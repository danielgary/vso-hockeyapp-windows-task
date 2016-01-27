param(
    [string]$appID, # HockeyApp App ID
    [string]$apiToken, #HockeyApp App Token
    [string]$packageDirectory = "../b/AppxPackages/")
    
 

$buildSourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Build.SourcesDirectory"

Write-Host "Changing directory to $($buildSourcesDirectory)"
SetLocation -Path $buildSourcesDirectory

#Compress output directory
Add-Type -A System.IO.Compression.FileSystem


$path = dir $packageDirectory -Directory | Select-Object -first 1
Write-Host "Zipping " + "$($packageDirectory)$($path.Name) into upload.zip"




[IO.Compression.ZipFile]::CreateFromDirectory("$packageDirectory$($path.Name)", "upload.zip")


$zipFile = dir "./upload.zip" -File | Select-Object -first 1

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
curl -F ipa=@upload.zip  -X PUT -F "status=2" -F "notify=1" -H "X-HockeyAppToken: 
'@ + $apiToken + '" ' + $update_url


cmd /c $curlCommand