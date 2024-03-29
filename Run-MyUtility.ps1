#requires -version 3.0
<#
  .SYNOPSIS
  .DESCRIPTION
  .EXAMPLE
  .INPUTS
  .OUTPUTS
  .NOTES
    Script Run-MyUtility.ps1 Version 2.0 by Ken Sweet on 7/5/2015
  .LINK
#>
[CmdletBinding()]
param (
)

$ErrorActionPreference = "Stop"

# Comment Out $VerbosePreference Line for Production Deployment
$VerbosePreference = "Continue"

# Comment Out $DebugPreference Line for Production Deployment
$DebugPreference = "Continue"

$ScriptName = "My Generic Utility"
$ScriptVersion = "2.21.0.0"
$ScriptAuthor = "Ken Sweet"

#region ******** My Generic Utility Script Customizations ********

#region ******** Thread ScriptBlock ********
$Thread = {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [String]$ComputerName
  )
  
  $ErrorActionPreference = "Stop"
  
  # Set Default Job Data that is returned to the Main Script, Returned values cannot be $Null, Emptry strings are OK
  $JobData = [PSCustomObject]@{"Status" = "Processing...";
                               "Value02" = "";
                               "Value03" = "";
                               "Value04" = "";
                               "Value05" = "";
                               "Value06" = "";
                               "Value07" = "";
                               "Value08" = "";
                               "Value09" = "";
                               "Value10" = "";
                               "Value11" = "";
                               "Value12" = "";
                               "Value13" = "";
                               "BeginTime" = (Get-Date);
                               "EndTime" = "";
                               "ErrorMessage" = ""}
  
  #region function Verify-Workstation
  function Verify-Workstation() 
  {
    <#
      .SYNOPSIS
        Verify Remote Workstation is the Correct One
      .DESCRIPTION
        Verify Remote Workstation is the Correct One
      .PARAMETER ComputerName
        Name of the Computer to Verify
      .PARAMETER Wait
        How Long to Wait for Job to be Completed
      .PARAMETER Serial
        Return Serial Number
      .PARAMETER Mobile
        Check if System is Mobile Workstation
      .INPUTS
      .OUTPUTS
      .EXAMPLE
        Verify-Workstation -ComputerName "MyWorkstation"
      .NOTES
        Original Script By Ken Sweet
      .LINK
    #>
    [CmdletBinding()]
    param (
      [parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
      [String[]]$ComputerName = [System.Environment]::MachineName,
      [Int]$Wait = 120,
      [Switch]$Serial,
      [Switch]$Mobile
    )
    Begin
    {
      Write-Verbose -Message "Enter Verify-Workstation Function"
$MyCompDataThread = @"
    `$ErrorActionPreference = 'Stop'
    Try
    {
      Write-Output -InputObject (Get-WmiObject -ComputerName '{0}' -Class Win32_ComputerSystem | Select-Object -Property 'UserName', 'Name', 'PartOfDomain', 'Domain', 'Manufacturer', 'Model', 'TotalPhysicalMemory', @{'Name' = 'Error'; 'Expression' = { `$False }}, @{'Name' = 'ErrorMessage'; 'Expression' = { '' }})
    }
    Catch
    {
      Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property @{'UserName' = ''; 'Name' = ''; 'Domain' = ''; 'Manufacturer' = ''; 'Model' = ''; 'TotalPhysicalMemory' = ''; 'Error' = `$True; 'ErrorMessage' = `$(`$Error[0].Exception.Message)})
    }
"@

$MyOSDataThread = @"
    `$ErrorActionPreference = 'Stop'
    Try
    {
      Write-Output -InputObject (Get-WmiObject -ComputerName '{0}' -Class Win32_OperatingSystem | Select-Object -Property 'Caption', 'CSDVersion', 'OSArchitecture', 'LocalDateTime', 'InstallDate', 'LastBootUpTime', @{'Name' = 'Error'; 'Expression' = { `$False }}, @{'Name' = 'ErrorMessage'; 'Expression' = { '' }})
    }
    Catch
    {
      Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property @{'Caption' = ''; 'CSDVersion' = ''; 'OSArchitecture' = ''; 'LocalDateTime' = ''; 'InstallDate' = ''; 'LastBootUpTime' = ''; 'Error' = `$True; 'ErrorMessage' = `$(`$Error[0].Exception.Message)})
    }
"@

$MyBIOSDataThread = @"
    `$ErrorActionPreference = 'Stop'
    Try
    {
      Write-Output -InputObject (Get-WmiObject -ComputerName '{0}' -Class Win32_Bios | Select-Object -Property 'SerialNumber', @{'Name' = 'Error'; 'Expression' = { `$False }}, @{'Name' = 'ErrorMessage'; 'Expression' = { '' }})
    }
    Catch
    {
      Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property @{'SerialNumber' = ''; 'Error' = `$True; 'ErrorMessage' = `$(`$Error[0].Exception.Message)})
    }
"@

$MyChassisDataThread = @"
    `$ErrorActionPreference = 'Stop'
    Try
    {
      Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property @{'IsMobile' = `$((@(8, 9, 10, 11, 12, 14) -contains (((Get-WmiObject -ComputerName '{0}' -Class Win32_SystemEnclosure).ChassisTypes)[0]))); 'Error' = `$False; 'ErrorMessage' = ''})
    }
    Catch
    {
      Write-Output -InputObject (New-Object -TypeName PSCustomObject -Property @{'IsMobile' = `$False; 'Error' = `$True; 'ErrorMessage' = `$(`$Error[0].Exception.Message)})
    }
"@
    }
    Process
    {
      Write-Verbose -Message "Enter Verify-Workstation Function - Process"
      ForEach ($Computer in $ComputerName)
      {
        $VerifyObject = [PSCustomObject]@{"ComputerName" = "Unknown"; 
                                          "Found" = $False; 
                                          "UserName" = ""; 
                                          "Domain" = ""; 
                                          "DomainMember" = ""; 
                                          "Manufacturer" = ""; 
                                          "Model" = ""; 
                                          "IsMobile" = $False; 
                                          "SerialNumber" = ""; 
                                          "Memory" = ""; 
                                          "OperatingSystem" = ""; 
                                          "ServicePack" = ""; 
                                          "Architecture" = ""; 
                                          "LocalDateTime" = ""; 
                                          "InstallDate" = ""; 
                                          "LastBootUpTime" = ""; 
                                          "IPAddress" = ""; 
                                          "Status" = "Off-Line";
                                          "ErrorMessage" = ""}
        Try
        {
          $IPAddresses = @([System.Net.Dns]::GetHostAddresses($Computer) | Where-Object -FilterScript { $PSItem.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } | Select-Object -ExpandProperty IPAddressToString)
          ForEach ($IPAddress in $IPAddresses)
          {
            if ((Test-Connection -Quiet -Count 2 -ComputerName $IPAddress))
            {
              $VerifyObject.Status = "On-Line"
              $VerifyObject.IPAddress = $IPAddress
              [Void]($MyJob = Start-Job -ScriptBlock ([ScriptBlock]::Create(($MyCompDataThread.Replace("{0}", $IPAddress)))))
              [Void](Wait-Job -Job $MyJob -Timeout $Wait)
              
              if ($MyJob.State -eq "Completed" -and $MyJob.HasMoreData)
              {
                $MyCompData = Get-Job -ID $MyJob.ID | Receive-Job -AutoRemoveJob -Wait
                if ($MyCompData.Error)
                {
                  $VerifyObject.Status = "Verify Comp Error"
                  $VerifyObject.ErrorMessage = $MyCompData.ErrorMessage
                }
                else
                {
                  $VerifyObject.ComputerName = "$($MyCompData.Name)"
                  $VerifyObject.UserName = "$($MyCompData.UserName)"
                  $VerifyObject.Domain = "$($MyCompData.Domain)"
                  $VerifyObject.DomainMember = "$($MyCompData.PartOfDomain)"
                  $VerifyObject.Manufacturer = "$($MyCompData.Manufacturer)"
                  $VerifyObject.Model = "$($MyCompData.Model)"
                  $VerifyObject.Memory = "$($MyCompData.TotalPhysicalMemory)"
                  if ($MyCompData.Name -eq @($Computer.Split(".", [System.StringSplitOptions]::RemoveEmptyEntries))[0])
                  {
                    $VerifyObject.Found = $True
                    
                    [Void]($MyJob = Start-Job -ScriptBlock ([ScriptBlock]::Create(($MyOSDataThread.Replace("{0}", $IPAddress)))))
                    [Void](Wait-Job -Job $MyJob -Timeout $Wait)
                    
                    if ($MyJob.State -eq "Completed" -and $MyJob.HasMoreData)
                    {
                      $MyOSData = Get-Job -ID $MyJob.ID | Receive-Job -AutoRemoveJob -Wait
                      if ($MyOSData.Error)
                      {
                        $VerifyObject.Status = "Verify Operating System Error"
                        $VerifyObject.ErrorMessage = $MyOSData.ErrorMessage
                      }
                      else
                      {
                        $VerifyObject.OperatingSystem = "$($MyOSData.Caption)"
                        $VerifyObject.ServicePack = "$($MyOSData.CSDVersion)"
                        $VerifyObject.Architecture = $(if ([String]::IsNullOrEmpty($MyOSData.OSArchitecture)) {"32-bit"} else {"$($MyOSData.OSArchitecture)"})
                        $VerifyObject.LocalDateTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($MyOSData.LocalDateTime)
                        $VerifyObject.InstallDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($MyOSData.InstallDate)
                        $VerifyObject.LastBootUpTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($MyOSData.LastBootUpTime)

                        if ($Serial)
                        {
                          [Void]($MyJob = Start-Job -ScriptBlock ([ScriptBlock]::Create(($MyBIOSDataThread.Replace("{0}", $IPAddress)))))
                          [Void](Wait-Job -Job $MyJob -Timeout $Wait)
                          
                          if ($MyJob.State -eq "Completed" -and $MyJob.HasMoreData)
                          {
                            $MyBIOSData = Get-Job -ID $MyJob.ID | Receive-Job -AutoRemoveJob -Wait
                            if ($MyBIOSData.Error)
                            {
                              $VerifyObject.Status = "Verify SerialNumber Error"
                              $VerifyObject.ErrorMessage = $MyBIOSData.ErrorMessage
                            }
                            else
                            {
                              $VerifyObject.SerialNumber = "$($MyBIOSData.SerialNumber)"
                            }
                          }
                          else
                          {
                            $VerifyObject.Status = "Verify SerialNumber Error"
                            [Void](Remove-Job -Job $MyJob -Force)
                          }
                        }
                        if ($Mobile)
                        {
                          [Void]($MyJob = Start-Job -ScriptBlock ([ScriptBlock]::Create(($MyChassisDataThread.Replace("{0}", $IPAddress)))))
                          [Void](Wait-Job -Job $MyJob -Timeout $Wait)
                          
                          if ($MyJob.State -eq "Completed" -and $MyJob.HasMoreData)
                          {
                            $MyChassisData = Get-Job -ID $MyJob.ID | Receive-Job -AutoRemoveJob -Wait
                            if ($MyChassisData.Error)
                            {
                              $VerifyObject.Status = "Verify is Mobile Error"
                              $VerifyObject.ErrorMessage = $MyChassisData.ErrorMessage
                            }
                            else
                            {
                              $VerifyObject.IsMobile = $($MyChassisData.IsMobile)
                            }
                          }
                          else
                          {
                            $VerifyObject.Status = "Verify is Mobile Error"
                            [Void](Remove-Job -Job $MyJob -Force)
                          }
                        }
                      }
                    }
                    else
                    {
                      $VerifyObject.Status = "Verify Operating System Error"
                      [Void](Remove-Job -Job $MyJob -Force)
                    }
                  }
                  else
                  {
                    $VerifyObject.Status = "Wrong Workstation Name"
                  }
                }
              }
              else
              {
                $VerifyObject.Status = "Verify Workstation Error"
                [Void](Remove-Job -Job $MyJob -Force)
              }
              Break
            }
          }
        }
        Catch
        {
          # Workstation Not in DNS
          $VerifyObject.Status = "Workstation Not in DNS"
        }
        
        Write-Output -InputObject $VerifyObject
        
        $VerifyObject = $Null
        $MyJob = $Null
        $MyCompData = $Null
        $MyOSData = $Null
        
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
      }
      Write-Verbose -Message "Exit Verify-Workstation Function - Process"
    }
    End
    {
      $MyCompDataThread = $Null
      $MyOSDataThread = $Null
      
      [System.GC]::Collect()
      [System.GC]::WaitForPendingFinalizers()
      Write-Verbose -Message "Exit Verify-Workstation Function"
    }
  }
  #endregion
  
  Try
  {
    # Add Optional Switches : -Serial -Mobile
    if (($VerifyData = Verify-Workstation -ComputerName $ComputerName).Found)
    {
      # Clear all Previous Error Messages
      $Error.Clear()
      
      <#
          $VerifyData is a Custom Object the has the following properties that you can use in your script

          ComputerName    : This is the Name of the Computer that is found, may be different than expected computer name
          Found           : True / False - This is True if the Workstation that was pinged was the expected Workstation
          UserName        : Domain\UserName of Logged on User, Will be Blank if user is Logged on via RDP
          Domain          : Domain \ WorkGroup Workstation is a member of
          IsMobile        : Optional Value - $True or $False
          SerialNumber    : Optional Value 
          Manufacturer    : Manufacturer of Computer
          Model           : Model of Computer
          Memory          : Total Memory in Bytes
          OperatingSystem : Installed Operating System
          ServicePack     : Installed Service Pack
          Architecture    : 32-Bit or 64-Bit
          LocalDateTime   : Date / Time on the Remote Workstation
          InstallDate     : Date / Time the Workstation was Imaged
          LastBootUpTime  : Date / Time the Workstation was Rebooted
          IPAddress       : IP Address of the Workstation
          Status          : On-Line, Wrong Name, Unknown, Off-Line, Error

        ******** Begin Put Your Code Here ********
      #>
      
      # Set Returned Job Data for when the Remote Workstation is found
      $JobData.Value02 = $VerifyData.IPAddress
      $JobData.Value03 = $VerifyData.ComputerName
      $JobData.Value04 = $VerifyData.OperatingSystem
      $JobData.Value05 = $VerifyData.ServicePack
      $JobData.Value06 = $VerifyData.Architecture

      Switch ($VerifyData.OperatingSystem)
      {
        {$PSItem.Contains("Windows 7") -or $PSItem.Contains("Windows 8")}
        {
          if ($VerifyData.Architecture -eq "64-Bit")
          {
            $JobData.Value07 = "Example - Win 7/8 x64"
          }
          else
          {
            $JobData.Value07 = "Example - Win 7/8 x86"
          }
          break
        }
        {$PSItem.Contains("Windows XP")}
        {
          $JobData.Value07 = "Example - Win XP x86"
          break
        }
        Default
        {
          $JobData.Value07 = "Example - Unknown OS"
          break
        }
      }
      
      # Generate Some Sample Random Data
      $JobData.Value08 = ("$([Char](Get-Random -Minimum 65 -Maximum 91))" * 8)
      $JobData.Value09 = ("$([Char](Get-Random -Minimum 65 -Maximum 91))" * 8)
      $JobData.Value10 = ("$([Char](Get-Random -Minimum 65 -Maximum 91))" * 8)
      $JobData.Value11 = ("$([Char](Get-Random -Minimum 65 -Maximum 91))" * 8)
      $JobData.Value12 = ("$([Char](Get-Random -Minimum 65 -Maximum 91))" * 8)
      $JobData.Value13 = ("$([Char](Get-Random -Minimum 65 -Maximum 91))" * 8)

      # if your Script Completed Sucessfully set returned $JabData.Status to "Done" so row will not be processed a second time
      $JobData.Status = "Done"
      
      <#
        ******** End Put Your Code Here ********
      #>
    }
    else
    {
      # Set Returned Job Data for when the Remote Workstation is not found
      $JobData.Value02 = $VerifyData.IPAddress
      $JobData.Value03 = $VerifyData.ComputerName
      $JobData.Status = $VerifyData.Status
      
      # Set returned Error Information $JabData.ErrorMessage to the Last Error Message
      $JobData.ErrorMessage = $VerifyData.ErrorMessage
    }
  }
  Catch
  {
    # Set Returned Job Status to indicate an error
    $JobData.Status = "Error - Catch"
    
    # Set returned Error Information $JabData.ErrorMessage to the last Error Message
    $JobData.ErrorMessage = "$($Error[0].Exception.Message)"
  }

  # Set Date / Time Job Finished
  $JobData.EndTime = (Get-Date)
  
  #Return Job Data to the Main Script
  $JobData
  
  $JobData = $Null
  $VerifyData = $Null
  
  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()
}
#endregion

# ListView and CSV Import/Export Column Name
$Column02 = "IPAddress"
$Column03 = "Name"
$Column04 = "OperatingSystem"
$Column05 = "ServicePack"
$Column06 = "Architecture"
$Column07 = "Column 07"
$Column08 = "Column 08"
$Column09 = "Column 09"
$Column10 = "Column 10"
$Column11 = "Column 11"
$Column12 = "Column 12"
$Column13 = "Column 13"

# Script Maximum Number of Threads
$MaxThreads = 4

#endregion

#region ******** My Generic Utility Custom Functions ********

#region ********* Show / Hide PowerShell Window *********
$WindowDisplay = @"
using System;
using System.Runtime.InteropServices;

namespace Window
{
  public class Display
  {
    [DllImport("Kernel32.dll")]
    private static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    public static bool Hide()
    {
      return ShowWindowAsync(GetConsoleWindow(), 0);
    }

    public static bool Show()
    {
      return ShowWindowAsync(GetConsoleWindow(), 5);
    }
  }
}
"@
Add-Type -TypeDefinition $WindowDisplay -Debug:$False
if ($VerbosePreference -eq "SilentlyContinue")
{
  [Void][Window.Display]::Hide()
}
#endregion

#region function New-ListViewItem
function New-ListViewItem()
{
  <#
    .SYNOPSIS
      Makes and adds a New ListViewItem to a ListView Control
    .DESCRIPTION
      Makes and adds a New ListViewItem to a ListView Control
    .PARAMETER ListView
    .PARAMETER BackColor
    .PARAMETER ForeColor
    .PARAMETER Font
    .PARAMETER Text
    .PARAMETER Tag
    .PARAMETER Group
    .PARAMETER ToolTip
    .PARAMETER Checked
    .PARAMETER PassThru
    .EXAMPLE
       = New-ListViewItem -ListView $listView -Text "Text" -Tag "Tag"
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param(
    [Object]$ListView = $MyUtility_ListView,
    [System.Drawing.Color]$BackColor = [System.Drawing.SystemColors]::Control,
    [System.Drawing.Color]$ForeColor = [System.Drawing.SystemColors]::ControlText,
    [parameter(Mandatory = $True)]
    [String]$Text,
    [String[]]$SubItems,
    [Object]$Tag,
    [System.Drawing.Font]$Font = $MyUtility_ListView.Font,
    [Object]$Group,
    [String]$ToolTip,
    [Switch]$Checked,
    [switch]$PassThru
  )
  Write-Verbose -Message "Enter New-ListViewItem Event for `$MyUtility_ListView"
  Try
  {
    #region $TempListViewItem = System.Windows.Forms.ListViewItem
    $TempListViewItem = New-Object -TypeName System.Windows.Forms.ListViewItem($Group)
    $ListView.Items.Add($TempListViewItem)
    $TempListViewItem.BackColor = $BackColor
    $TempListViewItem.ForeColor = $ForeColor
    $TempListViewItem.Font = $Font
    $TempListViewItem.Name = $Text.Replace(" ", "_")
    $TempListViewItem.Tag = $Tag
    $TempListViewItem.Text = $Text
    if ($PSBoundParameters.ContainsKey("SubItems"))
    {
      $TempListViewItem.SubItems.AddRange($SubItems)
    }
    $TempListViewItem.ToolTipText = $ToolTip
    $TempListViewItem.Checked = (-not $Checked)
    #endregion
    If ($PassThru)
    {
      $TempListViewItem
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code:$($Error[0].InvocationInfo.Line)"
  }
  Write-Verbose -Message "Exit New-ListViewItem Event for `$MyUtility_ListView"
}
#endregion

#region function New-ColumnHeader
function New-ColumnHeader()
{
  <#
    .SYNOPSIS
      Makes and Adds a New ColumnHeader for a ListView  Control
    .DESCRIPTION
      Makes and Adds a New ColumnHeader for a ListView  Control
    .PARAMETER ListView
    .PARAMETER Text
    .PARAMETER Tag
    .PARAMETER Width
    .PARAMETER PassThru
    .EXAMPLE
      $NewItem = New-ColumnHeader -Text "Text" -Tag "Tag"
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param(
    [Object]$ListView = $MyUtility_ListView,
    [parameter(Mandatory = $True)]
    [String]$Text,
    [Object]$Tag,
    [Int]$Width = -2,
    [switch]$PassThru
  )
  Write-Verbose -Message "Enter New-ColumnHeader Event for `$MyUtility_ListView"
  Try
  {
    #region $TempColumnHeader = System.Windows.Forms.ColumnHeader
    $TempColumnHeader = New-Object -TypeName System.Windows.Forms.ColumnHeader
    [Void]$ListView.Columns.Add($TempColumnHeader)
    $TempColumnHeader.Tag = $Tag
    $TempColumnHeader.Text = $Text
    $TempColumnHeader.Name = $Text.Replace(" ", "_")
    $TempColumnHeader.Width = $Width
    #endregion
    If ($PassThru)
    {
      $TempColumnHeader
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code:$($Error[0].InvocationInfo.Line)"
  }
  Write-Verbose -Message "Exit New-ColumnHeader Event for `$MyUtility_ListView"
}
#endregion

#region $MyLogo64
$MyLogo64 = @"
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
"@
#endregion

#region $MyIcon
$MyIcon = @"
AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAFAAAACQAAAAionZgipJeQKgAAAAkAAAAJAAAABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAKHhkYLw4JCEkNCgk0ZS4EqHQ2A8QSCwk/DQkIRRYQDjczMzMWAAAACgAA
AAoAAAAJAAAAAgAAAAAAAAAAAAAABIFQLoN0NwS6XSoElp5RBOukVgT0ZC0DomwyA6xpMQamODMxHQAAAA8AAAAOAAAADwAAAAMAAAAAAAAAAAAAAAGxgmFztmIG+rhkBf63Ywf7t2QH+rlkBf64ZAX9j1cqmQAA
AAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAANoHRVccFqCvq4aRXkvpd1ddGsjWnGeSzWxW0K/Y5YLZa9trQUAAAAAQAAAAAAAAAAAAAAAAAAAADFt7IfqG9Bo8d5Ke3Vgyb+onVLkAAAAAQAAAAB3LaVbtWD
J/zMfCjzomMuu7erpSEAAAAAAAAAAAAAAAAAAAAA29DMFr+Qbn/Nh0TY45hB/qh8UaIAAAAMAAAABs2nhYLjmEP8zoY95a96UpPKv7sXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACuZeDXuWhWfjfoFvys4xmqLuV
cp7eoWDr6aZb/ZVqTYcAAAAPrq6uFHJycjUAAAACAAAAAAAAAAAAAAAAAAAAAreQd4Xor3H5561v+O+2df7vtnX+6K5w+emvcfqZbk2+Ih4eoigoKK4lJSXLTk5OZ42NjScAAAAAAAAAAAAAAALKq5thuJN8gb6g
kFzbq4HZ26t86q6Nemu/nIh3eFdDxSwpKORBQUHFV1dXx0lJSelpaWlDAAAAAAAAAAAAAAAAAAAAAgAAAAIAAAACyKeVgbWQeZ4AAAALAAAACllXV4xXV1frZmZmUYCAgFR6enrsWVlZj6mpqRAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAsAAAAOAAAAAAAAAACHh4dGf39/535+ftKLi4vUh4eH1YWFhTwAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAurq6HoaGhk6MjIy/fn5+lXZ2doIAAAAOAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABs7OzJQAAAAwAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAA//+sQcA/rEEAAaxBgAGsQYAfrEEAD6xBAA+sQQAPrEGAA6xBgAGsQYABrEHAAKxB+YCsQf+BrEH/w6xB//+sQQ==
"@
#endregion


#endregion

#[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
#[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')

$FormSpacer = 4

#region $MyUtility_Form = System.Windows.Forms.Form
Write-Verbose -Message "Creating Form Control `$MyUtility_Form"
$MyUtility_Form = New-Object -TypeName System.Windows.Forms.Form
$MyUtility_Form.BackColor = [System.Drawing.Color]::White
$MyUtility_Form.Font = New-Object -TypeName System.Drawing.Font("Verdana", (8 * (96 / ($MyUtility_Form.CreateGraphics()).DpiX)), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Form.ForeColor = [System.Drawing.Color]::Black
$MyUtility_Form.Icon = [System.Drawing.Icon][System.Convert]::FromBase64String($MyIcon)
$MyUtility_Form.KeyPreview = $True
$MyUtility_Form.Name = "MyUtility_Form"
$MyUtility_Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$MyUtility_Form.Tag = $True
$MyUtility_Form.Text = "$ScriptName - $ScriptVersion"
#endregion

#region function Closing-MyUtility_Form
function Closing-MyUtility_Form()
{
  <#
    .SYNOPSIS
      Closing event for the MyUtility_Form Control
    .DESCRIPTION
      Closing event for the MyUtility_Form Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Closing-MyUtility_Form -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Closing Event for `$MyUtility_Form"
  Try
  {
    Write-Verbose -Message "Begin Terminating Any Remaining Jobs"
    [Void](Get-Job | Remove-Job -Force)
    Write-Verbose -Message "End Terminating Any Remaining Jobs"
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Closing Event for `$MyUtility_Form"
}
#endregion
$MyUtility_Form.add_Closing({Closing-MyUtility_Form -Sender $This -EventArg $PSItem})

#region function KeyDown-MyUtility_Form
function KeyDown-MyUtility_Form()
{
  <#
    .SYNOPSIS
      KeyDown event for the MyUtility_Form Control
    .DESCRIPTION
      KeyDown event for the MyUtility_Form Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       KeyDown-MyUtility_Form -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter KeyDown Event for `$MyUtility_Form"
  Try
  {
    if ($EventArg.Control -and $EventArg.Alt -and $EventArg.KeyCode -eq "F10")
    {
      if ($MyUtility_Form.Tag)
      {
        $Script:VerbosePreference = "SilentlyContinue"
        $Script:DebugPreference = "SilentlyContinue"
        [Void][Window.Display]::Hide()
        $MyUtility_Form.Tag = $False
      }
      else
      {
        $Script:VerbosePreference = "Continue"
        $Script:DebugPreference = "Continue"
        [Void][Window.Display]::Show()
        $MyUtility_Form.Tag = $True
      }
      $MyUtility_Form.Activate()
      $MyUtility_Form.Select()
    }
    elseif ($EventArg.KeyCode -eq "F1")
    {
      $MyUtility_ToolTip.Active = (-not $MyUtility_ToolTip.Active)
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit KeyDown Event for `$MyUtility_Form"
}
#endregion
$MyUtility_Form.add_KeyDown({KeyDown-MyUtility_Form -Sender $This -EventArg $PSItem})

#region function Load-MyUtility_Form
function Load-MyUtility_Form()
{
  <#
    .SYNOPSIS
      Load event for the MyUtility_Form Control
    .DESCRIPTION
      Load event for the MyUtility_Form Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Load-MyUtility_Form -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Load Event for `$MyUtility_Form"
  Try
  {
    New-ColumnHeader -Text "ComputerName"
    New-ColumnHeader -Text "Status"
    New-ColumnHeader -Text $Column02
    New-ColumnHeader -Text $Column03
    New-ColumnHeader -Text $Column04
    New-ColumnHeader -Text $Column05
    New-ColumnHeader -Text $Column06
    New-ColumnHeader -Text $Column07
    New-ColumnHeader -Text $Column08
    New-ColumnHeader -Text $Column09
    New-ColumnHeader -Text $Column10
    New-ColumnHeader -Text $Column11
    New-ColumnHeader -Text $Column12
    New-ColumnHeader -Text $Column13
    New-ColumnHeader -Text "Date / Time"
    New-ColumnHeader -Text "Error Message"
    
    ForEach ($Column in $MyUtility_ListView.Columns)
    {
      $Column.AutoResize([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
    }
    
    $Script:VerbosePreference = "SilentlyContinue"
    $Script:DebugPreference = "SilentlyContinue"
    $MyUtility_Form.Tag = $False
    [Void][Window.Display]::Hide()
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Load Event for `$MyUtility_Form"
}
#endregion
$MyUtility_Form.add_Load({Load-MyUtility_Form -Sender $This -EventArg $PSItem})

#region function Resize-MyUtility_Form
function Resize-MyUtility_Form()
{
  <#
    .SYNOPSIS
      Resize event for the MyUtility_Form Control
    .DESCRIPTION
      Resize event for the MyUtility_Form Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Resize-MyUtility_Form -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Resize Event for `$MyUtility_Form"
  Try
  {
    $MyUtility_Top_Label.Width = $MyUtility_Top_Panel.ClientSize.Width - ($MyUtility_Top_Label.Left + ($FormSpacer / 2))
  
    $MyUtility_Bottom_Import_Button.Width = [Math]::Floor(($MyUtility_Bottom_Panel.ClientSize.Width - ($FormSpacer * 6)) / 5)
    $MyUtility_Bottom_Clear_Button.Width = $MyUtility_Bottom_Import_Button.Width
    $MyUtility_Bottom_Process_Button.Width = $MyUtility_Bottom_Import_Button.Width + ($MyUtility_Bottom_Panel.ClientSize.Width - (($FormSpacer / 2) + (($MyUtility_Bottom_Import_Button.Width + $FormSpacer) * 5)))
    $MyUtility_Bottom_Export_Button.Width = $MyUtility_Bottom_Import_Button.Width
    $MyUtility_Bottom_Exit_Button.Width = $MyUtility_Bottom_Import_Button.Width

    $MyUtility_Bottom_Clear_Button.Location = New-Object -TypeName System.Drawing.Point(($MyUtility_Bottom_Import_Button.Right + $FormSpacer), $FormSpacer)
    $MyUtility_Bottom_Process_Button.Location = New-Object -TypeName System.Drawing.Point(($MyUtility_Bottom_Clear_Button.Right + $FormSpacer), $FormSpacer)
    $MyUtility_Bottom_Export_Button.Location = New-Object -TypeName System.Drawing.Point(($MyUtility_Bottom_Process_Button.Right + $FormSpacer), $FormSpacer)
    $MyUtility_Bottom_Exit_Button.Location = New-Object -TypeName System.Drawing.Point(($MyUtility_Bottom_Export_Button.Right + $FormSpacer), $FormSpacer)

  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Resize Event for `$MyUtility_Form"
}
#endregion
$MyUtility_Form.add_Resize({Resize-MyUtility_Form -Sender $This -EventArg $PSItem})

#region ******** $MyUtility_Form Controls ********

#region ListView Sort
$MyCustomListViewSort = @"
using System;
using System.Windows.Forms;
using System.Collections;

namespace MyCustom
{
  public class ListViewSort : IComparer
  {
    private int _SortColumn = 0;
    private bool _SortAscending = true;
    private bool _SortEnable = true;

    public ListViewSort()
    {
      _SortColumn = 0;
      _SortAscending = true;
    }

    public ListViewSort(int Column)
    {
      _SortColumn = Column;
      _SortAscending = true;
    }

    public ListViewSort(int Column, bool Order)
    {
      _SortColumn = Column;
      _SortAscending = Order;
    }

    public int SortColumn
    {
      get { return _SortColumn; }
      set { _SortColumn = value; }
    }

    public bool SortAscending
    {
      get { return _SortAscending; }
      set { _SortAscending = value; }
    }

    public bool SortEnable
    {
      get { return _SortEnable; }
      set { _SortEnable = value; }
    }

    public int Compare(object RowX, object RowY)
    {
      if (_SortEnable)
      {
        if (_SortAscending)
        {
          return String.Compare(((System.Windows.Forms.ListViewItem)RowX).SubItems[_SortColumn].Text, ((System.Windows.Forms.ListViewItem)RowY).SubItems[_SortColumn].Text);
        }
        else
        {
          return String.Compare(((System.Windows.Forms.ListViewItem)RowY).SubItems[_SortColumn].Text, ((System.Windows.Forms.ListViewItem)RowX).SubItems[_SortColumn].Text);
        }
      }
      else
      {
        return 0;
      }
    }
  }
}
"@
Add-Type -TypeDefinition $MyCustomListViewSort -ReferencedAssemblies "System.Windows.Forms" -Debug:$False
#endregion

#region $MyUtility_ListView = System.Windows.Forms.ListView
Write-Verbose -Message "Creating Form Control `$MyUtility_ListView"
$MyUtility_ListView = New-Object -TypeName System.Windows.Forms.ListView
$MyUtility_Form.Controls.Add($MyUtility_ListView)
$MyUtility_ListView.AllowColumnReorder = $True
$MyUtility_ListView.BackColor = [System.Drawing.Color]::White
$MyUtility_ListView.Dock = [System.Windows.Forms.DockStyle]::Fill
$MyUtility_ListView.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, $MyUtility_Form.Font.Size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_ListView.ForeColor = [System.Drawing.Color]::Black
$MyUtility_ListView.FullRowSelect = $True
$MyUtility_ListView.GridLines = $True
$MyUtility_ListView.HideSelection = $False
$MyUtility_ListView.ListViewItemSorter = New-Object -TypeName MyCustom.ListViewSort
$MyUtility_ListView.Name = "MyUtility_ListView"
$MyUtility_ListView.TabStop = $False
$MyUtility_ListView.Text = "MyUtility_ListView"
$MyUtility_ListView.View = [System.Windows.Forms.View]::Details
#endregion

#region function ColumnClick-MyUtility_ListView
function ColumnClick-MyUtility_ListView()
{
  <#
    .SYNOPSIS
      ColumnClick event for the MyUtility_ListView Control
    .DESCRIPTION
      ColumnClick event for the MyUtility_ListView Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       ColumnClick-MyUtility_ListView -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter ColumnClick Event for `$MyUtility_ListView"
  Try
  {
    if ($Sender.ListViewItemSorter.SortAscending -and $Sender.ListViewItemSorter.SortColumn -eq $EventArg.Column)
    {
      $Sender.ListViewItemSorter.SortAscending = $False
    }
    else
    {
      $Sender.ListViewItemSorter.SortColumn = $EventArg.Column
      $Sender.ListViewItemSorter.SortAscending = $True
    }
    $Sender.Sort()
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit ColumnClick Event for `$MyUtility_ListView"
}
#endregion
$MyUtility_ListView.add_ColumnClick({ColumnClick-MyUtility_ListView -Sender $This -EventArg $PSItem})

#region $MyUtility_Bottom_Panel = System.Windows.Forms.Panel
Write-Verbose -Message "Creating Form Control `$MyUtility_Bottom_Panel"
$MyUtility_Bottom_Panel = New-Object -TypeName System.Windows.Forms.Panel
$MyUtility_Form.Controls.Add($MyUtility_Bottom_Panel)
$MyUtility_Bottom_Panel.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$MyUtility_Bottom_Panel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$MyUtility_Bottom_Panel.Name = "MyUtility_Bottom_Panel"
$MyUtility_Bottom_Panel.Text = "MyUtility_Bottom_Panel"
#endregion

#region ******** $MyUtility_Bottom_Panel Controls ********

#region $MyUtility_OpenFileDialog = System.Windows.Forms.OpenFileDialog
Write-Verbose -Message "Creating Form Control `$MyUtility_OpenFileDialog"
$MyUtility_OpenFileDialog = New-Object -TypeName System.Windows.Forms.OpenFileDialog
$MyUtility_OpenFileDialog.Filter = "Import Files|*.txt;*.csv|Text Files|*.txt|CSV Files|*.csv|All Files|*.*"
$MyUtility_OpenFileDialog.InitialDirectory = $ENV:USERPROFILE
$MyUtility_OpenFileDialog.ShowHelp = $True
#endregion

#region $MyUtility_Bottom_Import_Button = System.Windows.Forms.Button
Write-Verbose -Message "Creating Form Control `$MyUtility_Bottom_Import_Button"
$MyUtility_Bottom_Import_Button = New-Object -TypeName System.Windows.Forms.Button
$MyUtility_Bottom_Panel.Controls.Add($MyUtility_Bottom_Import_Button)
$MyUtility_Bottom_Import_Button.AutoSize = $True
$MyUtility_Bottom_Import_Button.BackColor = [System.Drawing.Color]::Azure
$MyUtility_Bottom_Import_Button.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, ($MyUtility_Form.Font.Size * 1.5), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Bottom_Import_Button.ForeColor = [System.Drawing.Color]::Black
$MyUtility_Bottom_Import_Button.Location = New-Object -TypeName System.Drawing.Point($FormSpacer, $FormSpacer)
$MyUtility_Bottom_Import_Button.Name = "MyUtility_Bottom_Import_Button"
$MyUtility_Bottom_Import_Button.Text = "Import"
#endregion

#region function Click-MyUtility_Bottom_Import_Button
function Click-MyUtility_Bottom_Import_Button()
{
  <#
    .SYNOPSIS
      Click event for the MyUtility_Bottom_Import_Button Control
    .DESCRIPTION
      Click event for the MyUtility_Bottom_Import_Button Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Click-MyUtility_Bottom_Import_Button -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Click Event for `$MyUtility_Bottom_Import_Button"
  Try
  {
    $MyUtility_OpenFileDialog.FileName = $Null
    if ($MyUtility_OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
    {
      $MyUtility_ListView.ListViewItemSorter.SortEnable = $False
      $MyUtility_ListView.Items.Clear()
      $MyUtility_ListView.BeginUpdate()
      $MyUtility_ListView.Tag = @{}
      if ($MyUtility_OpenFileDialog.FileName.EndsWith(".csv", [System.StringComparison]::OrdinalIgnoreCase))
      {
        ForEach ($Item in @(Import-Csv -Path $MyUtility_OpenFileDialog.FileName))
        {
          $Key = $Item.ComputerName.ToUpper().Trim()
          if ((-not [String]::IsNullOrEmpty($Key)) -and (-not $MyUtility_ListView.Tag.Contains($Key)))
          {
            $MyUtility_ListView.Tag.Add($Key, $True)
            New-ListViewItem -Text $Key -SubItems @("$($Item.Status)", "$($Item.$Column02)", "$($Item.$Column03)", "$($Item.$Column04)", "$($Item.$Column05)", "$($Item.$Column06)", "$($Item.$Column07)", "$($Item.$Column08)", "$($Item.$Column09)", "$($Item.$Column10)", "$($Item.$Column11)", "$($Item.$Column12)", "$($Item.$Column13)", "$($Item."Date / Time")", "$($Item.ErrorMessage)") -Font $MyUtility_Form.Font -BackColor "White"
          }
        }
 
      }
      else
      {
        ForEach ($Item in @(Get-Content -Path $MyUtility_OpenFileDialog.FileName))
        {
          $Key = $Item.ToUpper().Trim()
          if ((-not [String]::IsNullOrEmpty($Key)) -and (-not $MyUtility_ListView.Tag.Contains($Key)))
          {
            $MyUtility_ListView.Tag.Add($Key, $True)
            New-ListViewItem -Text $Key -SubItems @("", "", "", "", "", "", "", "", "", "", "", "", "", "", "") -Font $MyUtility_Form.Font -BackColor "White"
          }
        }
      }
      $MyUtility_ListView.EndUpdate()
      $MyUtility_ListView.ListViewItemSorter.SortEnable = $True
      $MyUtility_ListView.Sort()
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Click Event for `$MyUtility_Bottom_Import_Button"
}
#endregion
$MyUtility_Bottom_Import_Button.add_Click({Click-MyUtility_Bottom_Import_Button -Sender $This -EventArg $PSItem})

#region $MyUtility_Bottom_Clear_Button = System.Windows.Forms.Button
Write-Verbose -Message "Creating Form Control `$MyUtility_Bottom_Clear_Button"
$MyUtility_Bottom_Clear_Button = New-Object -TypeName System.Windows.Forms.Button
$MyUtility_Bottom_Panel.Controls.Add($MyUtility_Bottom_Clear_Button)
$MyUtility_Bottom_Clear_Button.AutoSize = $True
$MyUtility_Bottom_Clear_Button.BackColor = [System.Drawing.Color]::Azure
$MyUtility_Bottom_Clear_Button.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, ($MyUtility_Form.Font.Size * 1.5), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Bottom_Clear_Button.ForeColor = [System.Drawing.Color]::Black
$MyUtility_Bottom_Clear_Button.Location = New-Object -TypeName System.Drawing.Point($FormSpacer, $FormSpacer)
$MyUtility_Bottom_Clear_Button.Name = "MyUtility_Bottom_Clear_Button"
$MyUtility_Bottom_Clear_Button.Text = "Clear"
#endregion

#region function Click-MyUtility_Bottom_Clear_Button
function Click-MyUtility_Bottom_Clear_Button()
{
  <#
    .SYNOPSIS
      Click event for the MyUtility_Bottom_Clear_Button Control
    .DESCRIPTION
      Click event for the MyUtility_Bottom_Clear_Button Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Click-MyUtility_Bottom_Clear_Button -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Click Event for `$MyUtility_Bottom_Clear_Button"
  Try
  {
    if ($MyUtility_ListView.Items.Count)
    {
      $MyUtility_ListView.Items.Clear()
      if ([System.Windows.Forms.MessageBox]::Show("Keep Workstation Names?", "Clear Data", "YesNo", "Question") -eq [System.Windows.Forms.DialogResult]::Yes)
      {
        $MyUtility_ListView.ListViewItemSorter.SortEnable = $False
        $MyUtility_ListView.BeginUpdate()
        ForEach ($Key in @($MyUtility_ListView.Tag.Keys))
        {
          New-ListViewItem -Text $Key -SubItems @("", "", "", "", "", "", "", "", "", "", "", "", "", "", "") -Font $MyUtility_Form.Font -BackColor "White"
        }
        $MyUtility_ListView.EndUpdate()
        $MyUtility_ListView.ListViewItemSorter.SortEnable = $True
        $MyUtility_ListView.Sort()
      }
      else
      {
        $MyUtility_ListView.Tag = @{}
      }
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }

  $ItemList = $Null
  $ItemCount = $Null
  $ThreadHash = $Null
  $FinishedJob = $Null
  $FinishedJobs = $Null
  $FailedJob = $Null
  $FailedJobs = $Null
  $JobData = $Null
  
  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()

  Write-Verbose -Message "Exit Click Event for `$MyUtility_Bottom_Clear_Button"
}
#endregion
$MyUtility_Bottom_Clear_Button.add_Click({Click-MyUtility_Bottom_Clear_Button -Sender $This -EventArg $PSItem})

#region $MyUtility_Bottom_Process_Button = System.Windows.Forms.Button
Write-Verbose -Message "Creating Form Control `$MyUtility_Bottom_Process_Button"
$MyUtility_Bottom_Process_Button = New-Object -TypeName System.Windows.Forms.Button
$MyUtility_Bottom_Panel.Controls.Add($MyUtility_Bottom_Process_Button)
$MyUtility_Bottom_Process_Button.AutoSize = $True
$MyUtility_Bottom_Process_Button.BackColor = [System.Drawing.Color]::Azure
$MyUtility_Bottom_Process_Button.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, ($MyUtility_Form.Font.Size * 1.5), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Bottom_Process_Button.ForeColor = [System.Drawing.Color]::Black
$MyUtility_Bottom_Process_Button.Location = New-Object -TypeName System.Drawing.Point($FormSpacer, $FormSpacer)
$MyUtility_Bottom_Process_Button.Name = "MyUtility_Bottom_Process_Button"
$MyUtility_Bottom_Process_Button.Tag = $True
$MyUtility_Bottom_Process_Button.Text = "Process"
#endregion

#region function Click-MyUtility_Bottom_Process_Button
function Click-MyUtility_Bottom_Process_Button()
{
  <#
    .SYNOPSIS
      Click event for the MyUtility_Bottom_Process_Button Control
    .DESCRIPTION
      Click event for the MyUtility_Bottom_Process_Button Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Click-MyUtility_Bottom_Process_Button -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Click Event for `$MyUtility_Bottom_Process_Button"
  Try
  {
    if ($MyUtility_ListView.Items.Count)
    {
      if ($MyUtility_Bottom_Process_Button.Tag)
      {
        $MyUtility_Bottom_Process_Button.Tag = $False
        $MyUtility_Bottom_Process_Button.Text = "Terminate"
        $MyUtility_Bottom_Process_Button.Refresh()
        
        $MyUtility_ListView.ListViewItemSorter.SortEnable = $False
        $MyUtility_Bottom_Import_Button.Enabled = $False
        $MyUtility_Bottom_Clear_Button.Enabled = $False
        $MyUtility_Bottom_Process_Button.Enabled = $True
        $MyUtility_Bottom_Export_Button.Enabled = $False
        $MyUtility_Bottom_Exit_Button.Enabled = $False

        $ItemList = @($MyUtility_ListView.Items | Where-Object -FilterScript { $PSItem.SubItems[1].Text -ne "Done" })
        
        if ($MaxThreads -gt 1)
        {
          $ThreadHash = @{}
          $ItemCount = $ItemList.Count - 1
          
          For ($Count = 0; $Count -le $ItemCount; $Count++)
          {
            if (-not $MyUtility_Bottom_Process_Button.Enabled)
            {
              Write-Verbose -Message "Break For Loop"
              break
            }
            
            Write-Verbose -Message "Begin Job Thread - $Count"
            $ThreadHash.Add("$Count", (Start-Job -ScriptBlock $Thread -ArgumentList ($ItemList[$Count].Name) -Name "$Count"))
            $ItemList[$Count].SubItems[1].Text = "Processing..."

            While (($ThreadHash.Count -eq $MaxThreads) -or ($ThreadHash.Count -and ($Count -eq $ItemCount)))
            {
              if (-not $MyUtility_Bottom_Process_Button.Enabled)
              {
                Write-Verbose -Message "Break Outter While Loop"
                break
              }
              
              While (@($ThreadHash.Values | Where-Object -FilterScript { $PSItem.State -eq "Running" }).Count -eq $ThreadHash.Count)
              {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
                
                if (-not $MyUtility_Bottom_Process_Button.Enabled)
                {
                  Write-Verbose -Message "Break Inner While Loop"
                  break
                }
              }
            
              if (($FailedJobs = @($ThreadHash.Values | Where-Object -FilterScript { @("Running", "Completed") -NotContains $PSItem.State })).Count)
              {
                ForEach ($FailedJob in $FailedJobs)
                {
                  $ThreadNum = $([int]$($FailedJob.Name))
                  Write-Verbose -Message "Failed Job Thread - $ThreadNum"
                  $ItemList[$ThreadNum].SubItems[1].Text = "Job Error"
                  $ItemList[$ThreadNum].SubItems[15].Text = $FailedJob.State
                  $ThreadHash.Remove($FailedJob.Name)
                  [Void](Remove-Job -Id $FailedJob.ID -Force)
                  [System.Windows.Forms.Application]::DoEvents()
                }
              }

              if (($FinishedJobs = @($ThreadHash.Values | Where-Object -FilterScript { $PSItem.State -eq "Completed"})).Count)
              {
                ForEach ($FinishedJob in $FinishedJobs)
                {
                  $ThreadNum = $([int]$($FinishedJob.Name))
                  Write-Verbose -Message "Completed Job Thread - $ThreadNum"
                  $JobData = Receive-Job -Id $FinishedJob.ID -Wait -AutoRemoveJob 
                  $ItemList[$ThreadNum].SubItems[1].Text = $JobData.Status
                  $ItemList[$ThreadNum].SubItems[2].Text = $JobData.Value02
                  $ItemList[$ThreadNum].SubItems[3].Text = $JobData.Value03
                  $ItemList[$ThreadNum].SubItems[4].Text = $JobData.Value04
                  $ItemList[$ThreadNum].SubItems[5].Text = $JobData.Value05
                  $ItemList[$ThreadNum].SubItems[6].Text = $JobData.Value06
                  $ItemList[$ThreadNum].SubItems[7].Text = $JobData.Value07
                  $ItemList[$ThreadNum].SubItems[8].Text = $JobData.Value08
                  $ItemList[$ThreadNum].SubItems[9].Text = $JobData.Value09
                  $ItemList[$ThreadNum].SubItems[10].Text = $JobData.Value10
                  $ItemList[$ThreadNum].SubItems[11].Text = $JobData.Value11
                  $ItemList[$ThreadNum].SubItems[12].Text = $JobData.Value12
                  $ItemList[$ThreadNum].SubItems[13].Text = $JobData.Value13
                  $ItemList[$ThreadNum].SubItems[14].Text = $JobData.EndTime
                  $ItemList[$ThreadNum].SubItems[15].Text = $JobData.ErrorMessage
                  $ThreadHash.Remove($FinishedJob.Name)
                  [System.Windows.Forms.Application]::DoEvents()
                }
              }
            }
          }
          
          Write-Verbose -Message "Begin Removing Remaining Jobs"
          [Void](Get-Job | Remove-Job -Force)
          Write-Verbose -Message "End Removing Remaining Jobs"
        }
        else
        {
          ForEach ($Item in $ItemList)
          {
            if (-not $MyUtility_Bottom_Process_Button.Enabled)
            {
              Write-Verbose -Message "Break ForEach Loop"
              break
            }
            
            Write-Verbose -Message "Begin Job Thread"
            $CurJob = Start-Job -ScriptBlock $Thread -ArgumentList ($Item.Name)
            $Item.SubItems[1].Text = "Processing..."
            
            While ($CurJob.State -eq "Running")
            {
              [System.Windows.Forms.Application]::DoEvents()
              Start-Sleep -Milliseconds 100
              
              if (-not $MyUtility_Bottom_Process_Button.Enabled)
              {
                Write-Verbose -Message "Break While Loop"
                break
              }
            }
            
            if ($CurJob.State -eq "Completed")
            {
              Write-Verbose -Message "Completed Job Thread"
              $JobData = Receive-Job -Id $CurJob.ID -Wait -AutoRemoveJob
              $Item.SubItems[1].Text = $JobData.Status
              $Item.SubItems[2].Text = $JobData.Value02
              $Item.SubItems[3].Text = $JobData.Value03
              $Item.SubItems[4].Text = $JobData.Value04
              $Item.SubItems[5].Text = $JobData.Value05
              $Item.SubItems[6].Text = $JobData.Value06
              $Item.SubItems[7].Text = $JobData.Value07
              $Item.SubItems[8].Text = $JobData.Value08
              $Item.SubItems[9].Text = $JobData.Value09
              $Item.SubItems[10].Text = $JobData.Value10
              $Item.SubItems[11].Text = $JobData.Value11
              $Item.SubItems[12].Text = $JobData.Value12
              $Item.SubItems[13].Text = $JobData.Value13
              $Item.SubItems[14].Text = $JobData.EndTime.ToString()
              $Item.SubItems[15].Text = $JobData.ErrorMessage
            }
            else
            {
              Write-Verbose -Message "Failed Job Thread"
              $Item.SubItems[1].Text = "Job Error"
              $Item.SubItems[14].Text = $JobData.DateTime
              $Item.SubItems[15].Text = $CurJob.State
              [Void](Remove-Job -Id $CurJob.ID -Force)
            }
            [System.Windows.Forms.Application]::DoEvents()
          }

          Write-Verbose -Message "Begin Removing Remaining Job"
          [Void](Get-Job | Remove-Job -Force)
          Write-Verbose -Message "End Removing Remaining Job"
        }

        $MyUtility_Bottom_Process_Button.Tag = $True
        $MyUtility_Bottom_Process_Button.Text = "Process"
        $MyUtility_Bottom_Import_Button.Enabled = $True
        $MyUtility_Bottom_Clear_Button.Enabled = $True
        $MyUtility_Bottom_Process_Button.Enabled = $True
        $MyUtility_Bottom_Export_Button.Enabled = $True
        $MyUtility_Bottom_Exit_Button.Enabled = $True
        $MyUtility_ListView.ListViewItemSorter.SortEnable = $True
        $MyUtility_ListView.Sort()
      }
      else
      {
        $MyUtility_Bottom_Process_Button.Tag = $True
        $MyUtility_Bottom_Process_Button.Text = "Process"
        
        $MyUtility_Bottom_Process_Button.Enabled = $False
      }
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Click Event for `$MyUtility_Bottom_Process_Button"
}
#endregion
$MyUtility_Bottom_Process_Button.add_Click({Click-MyUtility_Bottom_Process_Button -Sender $This -EventArg $PSItem})

#region $MyUtility_SaveFileDialog = System.Windows.Forms.SaveFileDialog
Write-Verbose -Message "Creating Form Control `$MyUtility_SaveFileDialog"
$MyUtility_SaveFileDialog = New-Object -TypeName System.Windows.Forms.SaveFileDialog
$MyUtility_SaveFileDialog.Filter = "CSV Files|*.csv"
$MyUtility_SaveFileDialog.InitialDirectory = $ENV:USERPROFILE
$MyUtility_SaveFileDialog.ShowHelp = $True
#endregion

#region $MyUtility_Bottom_Export_Button = System.Windows.Forms.Button
Write-Verbose -Message "Creating Form Control `$MyUtility_Bottom_Export_Button"
$MyUtility_Bottom_Export_Button = New-Object -TypeName System.Windows.Forms.Button
$MyUtility_Bottom_Panel.Controls.Add($MyUtility_Bottom_Export_Button)
$MyUtility_Bottom_Export_Button.AutoSize = $True
$MyUtility_Bottom_Export_Button.BackColor = [System.Drawing.Color]::Azure
$MyUtility_Bottom_Export_Button.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, ($MyUtility_Form.Font.Size * 1.5), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Bottom_Export_Button.ForeColor = [System.Drawing.Color]::Black
$MyUtility_Bottom_Export_Button.Location = New-Object -TypeName System.Drawing.Point($FormSpacer, $FormSpacer)
$MyUtility_Bottom_Export_Button.Name = "MyUtility_Bottom_Export_Button"
$MyUtility_Bottom_Export_Button.Text = "Export"
#endregion

#region function Click-MyUtility_Bottom_Export_Button
function Click-MyUtility_Bottom_Export_Button()
{
  <#
    .SYNOPSIS
      Click event for the MyUtility_Bottom_Export_Button Control
    .DESCRIPTION
      Click event for the MyUtility_Bottom_Export_Button Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Click-MyUtility_Bottom_Export_Button -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Click Event for `$MyUtility_Bottom_Export_Button"
  Try
  {
    if ($MyUtility_ListView.Items.Count)
    {
      $MyUtility_SaveFileDialog.FileName = $Null
      if ($MyUtility_SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
      {
        $MyUtility_ListView.Items | ForEach-Object -Process { [PSCustomObject][Ordered]@{"ComputerName" = $PSItem.SubItems[0].Text;
                                                                                         "Status" = $PSItem.SubItems[1].Text;
                                                                                         $Column02 = $PSItem.SubItems[2].Text;
                                                                                         $Column03 = $PSItem.SubItems[3].Text;
                                                                                         $Column04 = $PSItem.SubItems[4].Text;
                                                                                         $Column05 = $PSItem.SubItems[5].Text;
                                                                                         $Column06 = $PSItem.SubItems[6].Text;
                                                                                         $Column07 = $PSItem.SubItems[7].Text;
                                                                                         $Column08 = $PSItem.SubItems[8].Text;
                                                                                         $Column09 = $PSItem.SubItems[9].Text;
                                                                                         $Column10 = $PSItem.SubItems[10].Text;
                                                                                         $Column11 = $PSItem.SubItems[11].Text;
                                                                                         $Column12 = $PSItem.SubItems[12].Text;
                                                                                         $Column13 = $PSItem.SubItems[13].Text;
                                                                                         "Date / Time" = $PSItem.SubItems[14].Text;
                                                                                         "ErrorMessage" = $PSItem.SubItems[15].Text}} | Export-Csv -Encoding Ascii -NoTypeInformation -Path $MyUtility_SaveFileDialog.FileName
      }
    }
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Click Event for `$MyUtility_Bottom_Export_Button"
}
#endregion
$MyUtility_Bottom_Export_Button.add_Click({Click-MyUtility_Bottom_Export_Button -Sender $This -EventArg $PSItem})

#region $MyUtility_Bottom_Exit_Button = System.Windows.Forms.Button
Write-Verbose -Message "Creating Form Control `$MyUtility_Bottom_Exit_Button"
$MyUtility_Bottom_Exit_Button = New-Object -TypeName System.Windows.Forms.Button
$MyUtility_Bottom_Panel.Controls.Add($MyUtility_Bottom_Exit_Button)
$MyUtility_Bottom_Exit_Button.AutoSize = $True
$MyUtility_Bottom_Exit_Button.BackColor = [System.Drawing.Color]::Azure
$MyUtility_Bottom_Exit_Button.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, ($MyUtility_Form.Font.Size * 1.5), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Bottom_Exit_Button.ForeColor = [System.Drawing.Color]::Black
$MyUtility_Bottom_Exit_Button.Location = New-Object -TypeName System.Drawing.Point($FormSpacer, $FormSpacer)
$MyUtility_Bottom_Exit_Button.Name = "MyUtility_Bottom_Exit_Button"
$MyUtility_Bottom_Exit_Button.Text = "Exit"
#endregion

#region function Click-MyUtility_Bottom_Exit_Button
function Click-MyUtility_Bottom_Exit_Button()
{
  <#
    .SYNOPSIS
      Click event for the MyUtility_Bottom_Exit_Button Control
    .DESCRIPTION
      Click event for the MyUtility_Bottom_Exit_Button Control
    .PARAMETER Sender
       The Form Control that fired the Event
    .PARAMETER EventArg
       The Event Arguments for the Event
    .EXAMPLE
       Click-MyUtility_Bottom_Exit_Button -Sender $This -EventArg $PSItem
    .INPUTS
    .OUTPUTS
    .NOTES
    .LINK
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $True)]
    [Object]$Sender,
    [parameter(Mandatory = $True)]
    [Object]$EventArg
  )
  Write-Verbose -Message "Enter Click Event for `$MyUtility_Bottom_Exit_Button"
  Try
  {
    $MyUtility_Form.Visible = $False
    $MyUtility_Form.Close()
  }
  Catch
  {
    Write-Debug -Message "ErrMsg: $($Error[0].Exception.Message)"
    Write-Debug -Message "Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    Write-Debug -Message "Code: $(($Error[0].InvocationInfo.Line).Trim())"
  }
  Write-Verbose -Message "Exit Click Event for `$MyUtility_Bottom_Exit_Button"
}
#endregion
$MyUtility_Bottom_Exit_Button.add_Click({Click-MyUtility_Bottom_Exit_Button -Sender $This -EventArg $PSItem})

$MyUtility_Bottom_Panel.ClientSize = New-Object -TypeName System.Drawing.Size(($($MyUtility_Bottom_Panel.Controls[$MyUtility_Bottom_Panel.Controls.Count - 1]).Right + $FormSpacer), ($($MyUtility_Bottom_Panel.Controls[$MyUtility_Bottom_Panel.Controls.Count - 1]).Bottom + $FormSpacer))

#endregion

#region $MyUtility_Top_Panel = System.Windows.Forms.Panel
Write-Verbose -Message "Creating Form Control `$MyUtility_Top_Panel"
$MyUtility_Top_Panel = New-Object -TypeName System.Windows.Forms.Panel
$MyUtility_Form.Controls.Add($MyUtility_Top_Panel)
$MyUtility_Top_Panel.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$MyUtility_Top_Panel.Dock = [System.Windows.Forms.DockStyle]::Top
$MyUtility_Top_Panel.Name = "MyUtility_Top_Panel"
$MyUtility_Top_Panel.Text = "MyUtility_Top_Panel"
#endregion

#region ******** $MyUtility_Top_Panel Controls ********

#region $MyUtility_Top_PictureBox = System.Windows.Forms.PictureBox
Write-Verbose -Message "Creating Form Control `$MyUtility_Top_PictureBox"
$MyUtility_Top_PictureBox = New-Object -TypeName System.Windows.Forms.PictureBox
$MyUtility_Top_Panel.Controls.Add($MyUtility_Top_PictureBox)
$MyUtility_Top_PictureBox.AutoSize = $True
$MyUtility_Top_PictureBox.Image = [System.Drawing.Image][System.Convert]::FromBase64String($MyLogo64)
$MyUtility_Top_PictureBox.Location = New-Object -TypeName System.Drawing.Point(($FormSpacer / 2), ($FormSpacer / 2))
$MyUtility_Top_PictureBox.Name = "MyUtility_Top_PictureBox"
$MyUtility_Top_PictureBox.Text = "MyUtility_Top_PictureBox"
#endregion
$MyUtility_Top_PictureBox.ClientSize = $MyUtility_Top_PictureBox.Image.Size

#region $MyUtility_Top_Label = System.Windows.Forms.Label
Write-Verbose -Message "Creating Form Control `$MyUtility_Top_Label"
$MyUtility_Top_Label = New-Object -TypeName System.Windows.Forms.Label
$MyUtility_Top_Panel.Controls.Add($MyUtility_Top_Label)
$MyUtility_Top_Label.AutoSize = $True
$MyUtility_Top_Label.BackColor = [System.Drawing.Color]::Azure
$MyUtility_Top_Label.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$MyUtility_Top_Label.Font = New-Object -TypeName System.Drawing.Font($MyUtility_Form.Font.FontFamily, ($MyUtility_Form.Font.Size * 3), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point)
$MyUtility_Top_Label.ForeColor = [System.Drawing.Color]::Navy
$MyUtility_Top_Label.Name = "MyUtility_Top_Label"
$MyUtility_Top_Label.Text = "$ScriptName - $ScriptVersion"
$MyUtility_Top_Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
#endregion
$TempHeight = $MyUtility_Top_Label.Height
$MyUtility_Top_Label.AutoSize = $False
$MyUtility_Top_Label.Size = New-Object -TypeName System.Drawing.Size(([Math]::Ceiling($MyUtility_Top_Label.CreateGraphics().MeasureString("XXXX$($MyUtility_Top_Label.Text)XXXX", $MyUtility_Top_Label.Font).Width)), $TempHeight)

if ($MyUtility_Top_Label.Height -lt $MyUtility_Top_PictureBox.Height)
{
  $MyUtility_Top_Label.Location = New-Object -TypeName System.Drawing.Point(($MyUtility_Top_PictureBox.Right + $FormSpacer), ($MyUtility_Top_PictureBox.Top + ($MyUtility_Top_PictureBox.Height - $MyUtility_Top_Label.Height) / 2))
  $MyUtility_Top_Panel.ClientSize = New-Object -TypeName System.Drawing.Size(($MyUtility_Top_Label.Size.Width + ($FormSpacer / 2)), ($MyUtility_Top_PictureBox.Bottom + ($FormSpacer / 2)))
}
else
{
  $MyUtility_Top_Label.Location = New-Object -TypeName System.Drawing.Point(($MyUtility_Top_PictureBox.Right + $FormSpacer), ($FormSpacer / 2))
  $MyUtility_Top_Panel.ClientSize = New-Object -TypeName System.Drawing.Size(($MyUtility_Top_Label.Size.Width + ($FormSpacer / 2)), ($MyUtility_Top_Label.Bottom + ($FormSpacer / 2)))
}

#endregion

$MyUtility_Form.ClientSize = New-Object -TypeName System.Drawing.Size(($MyUtility_Top_Label.Right + ($FormSpacer / 2)), 500)

$MyUtility_Form.MinimumSize = $MyUtility_Form.Size

#endregion

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($MyUtility_Form)

#[Void][Window.Display]::Show()

[Environment]::Exit(0)

