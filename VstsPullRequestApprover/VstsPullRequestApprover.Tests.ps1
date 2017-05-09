Import-Module ./VstsPullRequestApprover.psm1

Describe "Set-PullRequestStatus" {
    Context "When approving a pull request and the reviewer has permission" {
        Mock -ModuleName VstsPullRequestApprover Invoke-VSTSRestMethod `
             -ParameterFilter { return $resourceUri.EndsWith("reviewers") } {
            return @(@{ value = @{ displayName = "Reviewer"; id = "ReviewerId"; } })
        }

        Mock -ModuleName VstsPullRequestApprover Invoke-VSTSRestMethod `
             -ParameterFilter { return $resourceUri.Contains("ReviewerId`?") } {
            $body | Should Be "{ vote: 10 }"
        }

        Mock -ModuleName VstsPullRequestApprover Invoke-VSTSRestMethod `
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
        Mock -ModuleName VstsPullRequestApprover Invoke-VSTSRestMethod `
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
    InModuleScope VstsPullRequestApprover {
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
    InModuleScope VstsPullRequestApprover {
        Context "When called with a valid repository uri" {
            $baseUri = Get-VstsApiBaseUri "https://domain.visualstudio.com/DefaultCollection/Project/_git/git-repository"
            
            It "Should return the base api uri" {
                $baseUri | Should Be "https://domain.visualstudio.com/Project/_apis/git/repositories/git-repository"
            }
        }
    }
}

Describe "Get-PullRequestId" {
    InModuleScope VstsPullRequestApprover {
        Context "When called with a valid pull request branch" {
            $id = Get-PullRequestId "refs/pull/861/merge"
            
            It "Should return the id" {
                $id | Should Be "861"
            }
        }

        Context "When called with a versioned branch" {
            $id = Get-PullRequestId "refs/head/release/1.0.0"
            
            It "Should return null" {
                $id | Should Be $null
            }
        }
        
        Context "When called with a unversioned branch" {
            $id = Get-PullRequestId "refs/head/develop"
            
            It "Should return null" {
                $id | Should Be $null
            }
        }

                
        Context "When called with a feature branch" {
            $id = Get-PullRequestId "refs/head/feature/12321-new-feature"
            
            It "Should return null" {
                $id | Should Be $null
            }
        }
    }
}


Remove-Module VstsPullRequestApprover