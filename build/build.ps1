param(
    [Parameter()]
    [switch] $pushPackage
)

$ErrorActionPreference = "Stop"

function Get-IncrementedVersion(){
    $version = Get-Content version
    $splitVersion = $version.Split(".")
    $splitVersion[2] = ([int]::Parse($splitVersion[2]) + 1).ToString()
    return [string]::Join(".", $splitVersion)
}

function Set-Version($version){
    Set-Content -Path version -Value $version
}

$version = Get-IncrementedVersion
Set-Version $version

Remove-Item *.zip

$zipPath = [System.IO.Path]::Combine((Get-Location), "VstsPullRequestApprover.$version.zip")
Add-Type -As System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory(
    (resolve-path .\VstsPullRequestApprover), 
    $zipPath,
    "Optimal", 
    $false)

if($pushPackage)
{
    $tag = "v$version"
    git tag $tag ; git push --tags
    .\build\tools\github-release.exe release `
                               --user naeemkhedarun `
                               --repo VstsPullRequestApprover `
                               --tag $tag
    
    .\build\tools\github-release.exe upload `
                               --user naeemkhedarun `
                               --repo VstsPullRequestApprover `
                               --tag $tag `
                               --name "VstsPullRequestApprover-$version.zip" `
                               --file $zipPath
}
