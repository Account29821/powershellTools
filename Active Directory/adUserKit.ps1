function createUsers{
    param([String]$usersFile)

    $userCount = 0
    $users = Import-CSV $usersFile -Delimiter ","

    mkdir logs -ErrorAction Ignore
    Out-File .\logs\$usersFile.log -ErrorAction Continue
    
    
    foreach($user in $users){
        $givenName = ($user | Select-Object -ExpandProperty Surname).ToUpper()
        $surname = $user | Select-Object -ExpandProperty GivenName

        $mail = ($surname + "." + $givenName + "@company.com").toLower()
        $displayName = "$surname $givenName"
        $samAccName = "$surname.$givenName".toLower()
        $upn = "$surname.$givenName@company.com".toLower()

        $password = ConvertTo-SecureString -String "password" -AsPlainText -Force
        
        New-ADUser -Name $displayName -Surname $givenName -GivenName $surname -EmailAddress $mail -DisplayName $displayName `
        -Enabled 1 -SamAccountName $samAccName -UserPrincipalName $upn -AccountPassword $password -ChangePasswordAtLogon 1 `
        -Path "OU=Users,DC=DOMAIN,DC=LOCAL" -Title $($user | Select-Object -ExpandProperty Title) -Company "Company" -Department $($user | Select-Object -ExpandProperty Department)
        
        "$surname $givenName's account has been created !" | Out-File .\logs\$usersFile.log -Append
        $userCount++
    }
    "`n$userCount accounts created !" | Out-File .\logs\$usersFile.log -Append
}

function changeUserMainGroup{
    param([String]$groupName)

    $group = Get-ADGroup "Utilisateurs du domaine" -Properties primaryGroupID, primaryGroupToken
    Get-ADUser -Filter "Name -like '*groupName*'" | Set-ADUser -Replace @{primaryGroupID = $group.primaryGroupToken}
    
}

function clearUsersGroups{
    param([String]$OU)

    $userSam = Get-ADUser -Filter * -SearchBase $OU
    foreach($user in $userSam){
        $userGroups = Get-ADUser -Identity $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        Remove-ADGroupMember -Identity $userGroups -Members $user -Confirm:$false
    }
}

function addUsersToGroup{
    param([String]$OU, [String]$group)

    $users = Get-ADUser -Filter * -SearchBase $OU
    foreach($user in $users){
        Add-ADGroupMember -Identity $group -Members $user.SamAccountName
    }
}

function extractCurrentActiveUsers{
    $ouFilters = "OU1", "OU2", "OU3"

    foreach($ou in $ouFilters){
        "### ----- $ou ----- ###" >> .\currentActiveUsers\currentStudents.csv
        (Get-ADOrganizationalUnit -Filter "Name -like '*$OU*'").distinguishedName | ForEach-Object {(Get-ADUser -Filter * -SearchBase $_) | Select-Object SamAccountName} >> .\currentActiveUsers\currentStudents.csv
    }
}

function changeUsersTitle{
    $ouList = (Get-ADOrganizationalUnit -Filter "Name -like '*Inactive*'").DistinguishedName
    foreach($ou in $ouList){
        (Get-ADUser -Filter * -SearchBase $ou).SamAccountName | ForEach-Object {Set-ADUser -Identity $_ -Title "Inactive user"}
    }
}