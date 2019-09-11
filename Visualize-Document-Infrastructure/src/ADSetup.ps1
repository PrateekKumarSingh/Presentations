
# # create new AD Users
$OU = New-ADOrganizationalUnit -Name TestOU -Verbose -PassThru

Import-Csv org.csv | 
Select-Object givenname, surname, name, samaccountname, title, department, city, @{n = 'enabled'; e = { $true } } |
New-ADUser -Verbose -Path $OU.DistinguishedName -AccountPassword ('Password@123' | ConvertTo-SecureString -AsPlainText -Force)

Import-Csv org.csv | 
Where-Object Manager | 
Foreach-Object {
    Set-ADUser $_.samaccountname -Manager (Get-ADUser $_.Manager) -Verbose
} 

# export AD users
$Password = '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000724d09ce0305f244968c56f654c1f8f300000000020000000000106600000001000020000000539dcc0c0c269a4e9c8bc5d512ad6b2101ce2586ec4fd248a9085ad1c3f750c6000000000e800000000200002000000048f58df32b11a1d6a4b40d07e6700645bdd243f59215226b4de75332fd7aa367200000002d6ab0bb2056575ea854d1dc77cf9ec4e0dbbf6c5969ae2780cb260aa237bdbe40000000d4c7709b25dc42b499bc1460b4acd0d4f17a027c2545121f49e2ed789ccda4689f26368e84fb62ad9490bf47c923e28795ec28abbb152f47718bb5ca979d5f40'
$creds = [pscredential]::new('Administrator', $Password)

Invoke-Command -ComputerName dc1 -Credential $creds -ScriptBlock {
    Get-ADUser -Filter * -SearchBase 'OU=TestOU,DC=test,DC=com' -Properties * -Server dc1 |
    Select-Object givenname,
    surname,
    name,
    samaccountname,
    Manager,
    title,
    department,
    city, 
    @{n = 'directreports'; e = { $_.directreports -join ';' } }
} | Export-csv .\src\org.csv -NoTypeInformation
