function removeAllMembers{
    <#------------------------------------------------
    Use - removeAllMembers "distributionListEmail"
    
    $dlMail - Distribution list's e-mail address
    ------------------------------------------------#>
    
    param([String]$dlMail)

    foreach($member in Get-DistributionGroupMember -Identity $dlMail){
        Remove-DistributionGroupMember -Identity $dlMail -Member $member -Confirm:$false
        Write-Output "$($member.Displayname) has been removed from $dlMail"
    }

    Get-DistributionGroupMember -Identity $group
}

function addMembers{
    <#------------------------------------------------
    Use - addMembers "pathToFile" "distributionListEmail"

    $dlMail - Distribution list e-mail address
    $usersFile - File containing e-mail addresses
    ------------------------------------------------#>
    
    param([String]$usersFile, [String]$dlMail)

    foreach($user in Get-Content $usersFile){
        try {
            Add-DistributionGroupMember -Identity $dlMail -Member $user -ErrorAction 
            Write-Output "$user has been added to the $dlMail distribution list"
        }
        catch {
            Write-Output "An error has occured for $user"
        }
    }

    Get-DistributionGroupMember -Identity $dlMail
}
