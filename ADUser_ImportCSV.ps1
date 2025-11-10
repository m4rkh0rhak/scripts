Example Script (Requires CSV as input):**

Import-Module ActiveDirectory

# Path to your CSV file
$Users = Import-Csv -Path "C:\Temp\ADUsers.csv"

foreach ($User in $Users) {
    $Name = "$($User.FirstName) $($User.LastName)"
    $UserPrincipalName = $User.Username + "@domain.com"
    $Password = (ConvertTo-SecureString $User.Password -AsPlainText -Force)
    New-ADUser `
        -Name $Name `
        -GivenName $User.FirstName `
        -Surname $User.LastName `
        -SamAccountName $User.Username `
        -UserPrincipalName $UserPrincipalName `
        -AccountPassword $Password `
        -Enabled $true `
        -Path $User.OU `
        -EmailAddress $User.Email
}

