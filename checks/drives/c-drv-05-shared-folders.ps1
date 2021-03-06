﻿<#
    DESCRIPTION: 
        Check shared folders to ensure no additional shares are present.  Shared folders should be documented with a designated team specified as the owner.

    REQUIRED-INPUTS:
        IgnoreTheseShares - List of share names that can be ignored

    DEFAULT-VALUES:
        IgnoreTheseShares = ('NETLOGON', 'SYSVOL', 'CertEnroll')

    DEFAULT-STATE:
        Enabled

    RESULTS:
        PASS:
            No additional shares found
        WARNING:
            Shared folders found, check against documentation
        FAIL:
        MANUAL:
        NA:

    APPLIES:
        All Servers

    REQUIRED-FUNCTIONS:
        None
#>

Function c-drv-05-shared-folders
{
    Param ( [string]$serverName, [string]$resultPath )

    $serverName    = $serverName.Replace('[0]', '')
    $resultPath    = $resultPath.Replace('[0]', '')
    $result        = newResult
    $result.server = $serverName
    $result.name   = $script:lang['Name']
    $result.check  = 'c-drv-05-shared-folders'

    #... CHECK STARTS HERE ...#

    Try
    {   #                                                              Admin Shares         IPC Share
        [string]$query = "SELECT Name FROM Win32_Share WHERE NOT(Type='2147483648' OR Type='2147483651') AND NOT Name=''"
        If ($script:appSettings['IgnoreTheseShares'].Count -gt 0)
        {
            For ($i = 0; $i -lt $script:appSettings['IgnoreTheseShares'].Count; $i++)
            {
                $query += " AND NOT Name='" + $script:appSettings['IgnoreTheseShares'][$i] + "'"
            }
        }
        [array]$check = Get-WmiObject -ComputerName $serverName -Query $query -Namespace ROOT\Cimv2 | Select-Object -ExpandProperty Name
    }
    Catch
    {
        $result.result  = $script:lang['Error']
        $result.message = $script:lang['Script-Error']
        $result.data    = $_.Exception.Message
        Return $result
    }

    If ($check.Count -gt 0)
    {
        $result.result  = $script:lang['Warning']
        $result.message = 'Shared folders found, check against documentation'
        $check | ForEach { $result.data += '{0},#' -f $_ }
    }
    Else
    {
        $result.result  = $script:lang['Pass']
        $result.message = 'No additional shares found'
    }
    
    Return $result
}