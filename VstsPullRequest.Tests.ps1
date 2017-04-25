Import-Module ./VstsPullRequest.psm1

Describe "Set-PullRequestStatus" {
    Context "When approving a pull request and the reviewer has permission" {
        Mock -ModuleName VstsPullRequest Invoke-VSTSRestMethod `
             -ParameterFilter { return $resourceUri.EndsWith("reviewers") } {
            return @(@{ value = @{ displayName = "Reviewer"; id = "ReviewerId"; } })
        }

        Mock -ModuleName VstsPullRequest Invoke-VSTSRestMethod `
             -ParameterFilter { return $resourceUri.Contains("ReviewerId`?") } {
            $body | Should Be "{ vote: 10 }"
        }

        Mock -ModuleName VstsPullRequest Invoke-VSTSRestMethod `
             -ParameterFilter { return $resourceUri.Contains("threads") } {
            $body.Contains("Build Succeeded: https://teamcity/`?build-id=1") | Should Be $true 
        }

        Set-PullRequestStatus `
            -vcsroot "https://domain.visualstudio.com/DefaultCollection/Project/_git/git-repository" `
            -branch "refs/pull/586/merge" `
            -accessToken "xxx" `
            -reviewerAccount "Reviewer" `
            -approve $true `
            -buildUri "https://teamcity/?build-id=1"
    }

    Context "When approving a pull request and the reviewer doesn't have permission" {
        Mock -ModuleName VstsPullRequest Invoke-VSTSRestMethod `
             -ParameterFilter { return $resourceUri.EndsWith("reviewers") } {
            return @(@{ value = @{ displayName = "DifferentReviewer"; id = "ReviewerId"; } })
        }

        { Set-PullRequestStatus `
            -vcsroot "https://domain.visualstudio.com/DefaultCollection/Project/_git/git-repository" `
            -branch "refs/pull/586/merge" `
            -accessToken "xxx" `
            -reviewerAccount "Reviewer" `
            -approve $false `
            -buildUri "https://teamcity/?build-id=1" } | Should Throw "Reviewer is not set as a reviewer for this pull request."
    }
}

Describe "Get-VstsConnectionVariables" {
    InModuleScope VstsPullRequest {
        Context "When called with a valid repository uri" {
            $variables = Get-VstsConnectionVariables "https://domain.visualstudio.com/DefaultCollection/Project/_git/git-repository"
            
            It "Should return the instance" {
                $variables.Instance | Should Be "domain.visualstudio.com"
            }

            It "Should return the collection" {
                $variables.ProjectCollection | Should Be "DefaultCollection"
            }

            It "Should return the team project" {
                $variables.TeamProject | Should Be "Project"
            }
            
            It "Should return repository" {
                $variables.Repository | Should Be "git-repository"
            }
        }
    }
}

Describe "Get-VstsApiBaseUri" {
    InModuleScope VstsPullRequest {
        Context "When called with a valid repository uri" {
            $baseUri = Get-VstsApiBaseUri "https://domain.visualstudio.com/DefaultCollection/Project/_git/git-repository"
            
            It "Should return the base api uri" {
                $baseUri | Should Be "https://domain.visualstudio.com/Project/_apis/git/repositories/git-repository"
            }
        }
    }
}

Remove-Module VstsPullRequest