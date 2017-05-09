$ErrorActionPreference = "Stop";

function Invoke-VSTSRestMethod
{
    param($apiBaseUri, $resourceUri, $accessToken, $verb = "GET", $body)

    $headers = @{
        Authorization=("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$accessToken")));
    }

    Write-Host  "$apiBaseUri/$resourceUri"

    return Invoke-RestMethod "$apiBaseUri/$resourceUri" -Headers $headers -Method $verb -Body $body -ContentType "application/json" 
}

function Get-ReviewerId
{
    param($apiBaseUri, $pullRequest, $accessToken, $reviewerAccount)

    Write-Host "`nGetting reviewers"
    $reviewers = Invoke-VSTSRestMethod $apiBaseUri "pullRequests/$pullRequest/reviewers" -accessToken $accessToken

    $reviewers.value.displayName | ForEach-Object { "  $($_)" } | Write-Host

    $reviewerId = $reviewers.value | Where-Object { $_.displayName -eq $reviewerAccount } | % { $_.id }

    if(!$reviewerId)
    {
        throw "$reviewerAccount is not set as a reviewer for this pull request."
    }

    return $reviewerId
}

function Set-Vote 
{
    param($apiBaseUri, $pullRequest, $accessToken, $reviewerId, $approve)
    
    $vote = if($approve) { 10 } else { -10 }

    Write-Host "`nUpdating vote..."
    Invoke-VSTSRestMethod $apiBaseUri "pullRequests/$pullRequest/reviewers/$reviewerId`?api-version=3.0" -accessToken $accessToken -verb PUT -body "{ vote: $vote }"
}

function Set-BuildStatusComment
{
    param($apiBaseUri, $pullRequest, $accessToken, $approve, $buildUri)

    Write-Host "`nAdding build status comment..."

    Invoke-VSTSRestMethod $apiBaseUri "pullRequests/$pullRequest/threads`?api-version=3.0" -accessToken $accessToken -verb POST -body @"
{
"comments": [
    {
    "parentCommentId": 0,
    "content": "$(if($approve){ "Build Succeeded: $buildUri" } else { "Build Failed: $buildUri" })",
    "commentType": 1
    }
],
"properties": {
    "Microsoft.TeamFoundation.Discussion.SupportsMarkdown": {
    "type": "System.Int32",
    "value": 1
    }
},
"status": 4
}
"@
}

function Get-VstsConnectionVariables
{
    param($vcsroot)

    $uri = new-object System.Uri $vcsroot
    
    return @{
        Instance = $uri.Authority;
        ProjectCollection = $uri.Segments[1].Replace('/','');
        TeamProject = $uri.Segments[2].Replace('/','')
        Repository = $uri.Segments[4].Replace('/','')
    }
}

function Get-VstsApiBaseUri
{
    param($vcsroot)

    $variables = Get-VstsConnectionVariables $vcsroot
    
    return "https://$($variables.Instance)/$($variables.TeamProject)/_apis/git/repositories/$($variables.Repository)"
}

function Get-PullRequestId
{
    param($branch)

    return $branch | select-string -Pattern "refs/pull/(?<id>[0-9]+)/merge" `
                   | Select-Object -ExpandProperty Matches `
                   | ForEach-Object { $_.Groups["id"].Value } `
                   | Select-Object -First 1
}

function Set-PullRequestStatus
{
    param($vcsroot, $branch, $accessToken, $reviewerAccount, [bool]$approve, $buildUri)

    Write-Host "**** Setting build status for pull request ****"

    $pullRequest = Get-PullRequestId $branch

    if(!$pullRequest)
    {
        Write-Host "`nNot a pull request. Skipping Step."
        return;
    }

    $apiBaseUri = Get-VstsApiBaseUri $vcsroot

    $reviewerId = Get-ReviewerId $apiBaseUri $pullRequest $accessToken $reviewerAccount

    Set-Vote $apiBaseUri $pullRequest $accessToken $reviewerId $approve

    Set-BuildStatusComment $apiBaseUri $pullRequest $accessToken $approve $buildUri
}

Export-ModuleMember -Function Set-PullRequestStatus