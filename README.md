# VstsPullRequestApprover

A PowerShell module to help you approve and reject VSTS pull requests based on the status of your CI process.

If the build is successful it will:

* Set the PR as approved from the account you've configured.
* Leave a comment linking to the successful build.

else if it has failed:

* Set the PR as rejected.
* Leave a comment linking to the failed build.

![An approved pr](https://github.com/naeemkhedarun/VstsPullRequestApprover/raw/master/docs/images/pr-approved-with-comment.png)

