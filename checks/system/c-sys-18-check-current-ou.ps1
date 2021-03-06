﻿<#
    DESCRIPTION: 
        Check that the current server OU path is not in the default location(s).  The list of OUs should contain at least the default "Computers" OU, and must be the full distinguished name of the locations.

    REQUIRED-INPUTS:
        NoInTheseOUs - List of full-path OU names that the servers should not be located in.

    DEFAULT-VALUES:
        NoInTheseOUs = ('cn=Computers', 'ou=Quarantine')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            Server not in default location
        WARNING:
        FAIL:
            Server is in default location
        MANUAL:
        NA:
            Not a domain joined server

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function c-sys-18-check-current-ou
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = $script:lang['Name']
    $result.check  = 'c-sys-18-check-current-ou'

    #... CHECK STARTS HERE ...#

    Try
    {
        [string] $query  = "SELECT PartOfDomain FROM Win32_ComputerSystem"
        [boolean]$check  = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Cimv2 | Select-Object -ExpandProperty PartOfDomain

        If ($check -eq $true)
        {
            $result.result  = $script:lang['Pass']
            $result.message = 'Server not located in a default OU location'

            $objDomain   = New-Object System.DirectoryServices.DirectoryEntry
            $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
            $strFilter   = "(&(objectCategory=computer)(name=$serverName))"
            $objSearcher.SearchRoot = $objDomain
            $objSearcher.Filter     = $strFilter
            [string]$strPath = ($objSearcher.FindOne().Path).ToLower()
            If ([string]::IsNullOrEmpty($strPath) -eq $true) { Throw 'Failed to get OU path from Active Directory' }

                    $strPath   = ($strPath -split "ldap://cn=$($serverName.ToLower()),")[1]    # Remove Computer Name
            [string]$CurrentOU = ($strPath -split ',DC=')[0]                                   # Remove Domain Name

            ForEach ($OU In $script:appSettings['NoInTheseOUs'])
            {
                If ($CurrentOU -like "*$OU")
                {
                    $result.result  = $script:lang['Fail']
                    $result.message = 'Server found in a default OU location'
                    Break
                }
            }

            [string]$splitPath1, $splitPath2 = ($strPath -split ',dc=', 2)
            $result.data   += "$splitPath1,#dc=$splitPath2"
        }
        Else
        {
            $result.result  = $script:lang['Not-Applicable']
            $result.message = 'Not a domain joined server'
            $result.data    = ''
        }

        Return $result
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
        Return $result
    }
}
