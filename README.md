# VstsPullRequestApprover

A PowerShell module to help you approve and reject VSTS pull requests based on the status of your CI process.

If the build is successful it will:

* Set the PR as approved from the account you've configured.
* Leave a comment linking to the successful build.

else if it has failed:

* Set the PR as rejected.
* Leave a comment linking to the failed build.

![An approved pr](https://github.com/naeemkhedarun/VstsPullRequestApprover/raw/master/docs/images/pr-approved-with-comment.png)

# Getting Started

You can get started with the module in a number of ways.

## Using PsGet

```
Install-Module -ModuleUrl https://github.com/naeemkhedarun/VstsPullRequestApprover/raw/master/VstsPullRequestApprover/VstsPullRequestApprover.psm1
```

## Using the Zip release

Download the latest release from the releases page:

[https://github.com/naeemkhedarun/VstsPullRequestApprover/releases/latest](https://github.com/naeemkhedarun/VstsPullRequestApprover/releases/latest)

You can unpack it into the PSModulePath `C:\Users\_user_\Documents\WindowsPowerShell\Modules` to autoload it.

If you are using TeamCity you can roll it out across the agents as an [agent tool](https://confluence.jetbrains.com/display/TCD10/Installing+Agent+Tools).

## Create a VSTS User and get an access token

You can either use your own account or create a dedicated account to do the approvals. This account
should be included in the branch policies and its access token used to submit the approval.

![branch policy](https://github.com/naeemkhedarun/VstsPullRequestApprover/raw/master/docs/images/branch-policy.png)

Next log in as the approval user and [generate an access token](https://www.visualstudio.com/en-us/docs/setup-admin/team-services/use-personal-access-tokens-to-authenticate) which you can pass to the module when setting the pull request status. It will need the `Code (read and write)` permission.

## Import and run the cmdlet from your build script / step

You can now call the module to set the status:

```
Import-Module VstsPullRequestApprover

Set-PullRequestStatus `
            -vcsroot "https://domain.visualstudio.com/DefaultCollection/Project/_git/git-repository" `
            -branch "refs/pull/586/merge" `
            -accessToken "xxx" `
            -reviewerAccount "Reviewer" `
            -approve $false `
            -buildUri "https://teamcity/?build-id=1"
```

### vcsroot

This is the uri of the Git repository that your build is using. It is broken down and used to
constructor the uris for the VSTS API.

### branch

The VSTS pull request branch which is being built. It contains the ID of the pull request used 
in the api calls. It is in the format `ref/pull/_id_/merge`.

### accessToken

The approving users access token with the `Code (read and write)` permission.

### reviewerAccount

The display name of the approving users account. We search the available reviewers from the API to resolve
the users ID. If the user isn't set up as a reviewer you will get an error and a list of available reviewer names.

### approve

$true for approving the pull request, and $false for denying.

### buildUri

The uri for the build which is compiling and testing the pull request.

# Issues and feature requests

Please start raise an [issue](https://github.com/naeemkhedarun/VstsPullRequestApprover/issues) on github for any bugs or features you would like to see.
