#Root Folder - Anything running off this script will come from this folder
$RootFolder = "C:\Scripts"

#Connecting to all vCenters
$Sourcevcenterlist = get-content "$RootFolder\vCenters\vcenterSOURCE.txt"

$Targetvcenterlist = get-content "$RootFolder\vCenters\vcenterTARGET.txt"


#make sure to have a credential file already created and ready in the proper folder

Write-Host "Please add your SOURCE (Old) vCenter Credentials"
$sourceVCSACredentials = Get-Credential

Write-Host "Please add your TARGET (New) vCenter Credentials"
$targetVCSACredentials = Get-Credential


#select your source VCSA
##########################################################################################################################

#Source vCenter Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Source vCenter'
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,240)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,240)
$cancelButton.Size = New-Object System.Drawing.Size(150,46)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,40)
$label.Size = New-Object System.Drawing.Size(560,40)
$label.Text = 'Select a Source vCenter:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(520,40)
$listBox.Height = 160
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Regular)
$listbox.SelectionMode = 'MultiExtended'

foreach($sourceVCSA in $Sourcevcenterlist){
    [void] $listBox.Items.Add($sourceVCSA)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $sourceVCSA = $listBox.SelectedItem

}

##########################################################################################################################


#Connect to Source VCSA
Write-Host "Connecting to $sourceVCSA"
Try {connect-viserver $sourceVCSA -Credential $sourceVCSACredentials} Catch {Connection-Alert $sourceVCSA ;break}

#Collect Source variable info
$SourceDatacenter = Get-Datacenter
$sourceHosts = Get-VMHost
$sourceClusters = Get-Cluster
$SourcePortgroups = Get-VDPortgroup
$SourceVMs = Get-vm | where {($_.ExtensionData.Config.ManagedBy.ExtensionKey -notlike 'com.vmware.vcDr*') -or ($_.ExtensionData.Config.ManagedBy.ExtensionKey -notlike 'com.vmware.vcHms*')}

Disconnect-VIServer "*" -Confirm:$False

##########################################################################################################################

#Target vCenter Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Target vCenter'
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,240)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,240)
$cancelButton.Size = New-Object System.Drawing.Size(150,46)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,40)
$label.Size = New-Object System.Drawing.Size(560,40)
$label.Text = 'Select a Target vCenter:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(520,40)
$listBox.Height = 160
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Regular)
$listbox.SelectionMode = 'MultiExtended'

foreach($targetVCSA in $Targetvcenterlist){
    [void] $listBox.Items.Add($targetVCSA)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $targetVCSA = $listBox.SelectedItem

}
##########################################################################################################################

#Connect to Target VCSA
Write-Host "Connecting to $targetVCSA"
Try {connect-viserver $targetVCSA -Credential $targetVCSACredentials} Catch {Connection-Alert $targetVCSA ;break}


#Collect target VCSA info
$targetDatacenter = Get-Datacenter
$targetHosts = Get-VMHost
$targetClusters = Get-Cluster
$targetPortgroups = Get-VDPortgroup

Disconnect-VIServer "*" -Force:$False

Write-Host "All variables collected. Reconnecting to both VCSA's"

start-sleep 5

Write-Host "Connecting to $targetVCSA"
Try {connect-viserver $targetVCSA -Credential $targetVCSACredentials} Catch {Connection-Alert $targetVCSA ;break}

Write-Host "Connecting to $sourceVCSA"
Try {connect-viserver $sourceVCSA -Credential $sourceVCSACredentials} Catch {Connection-Alert $sourceVCSA ;break}


#Get portgroups from a selected source VCSA and then list those portgroups based on a dropdown box
##########################################################################################################################

#Source portgroup Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Source portgroup'
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,240)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,240)
$cancelButton.Size = New-Object System.Drawing.Size(150,46)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,40)
$label.Size = New-Object System.Drawing.Size(560,40)
$label.Text = 'Select a Source portgroup:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(520,40)
$listBox.Height = 160
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Regular)
$listbox.SelectionMode = 'MultiExtended'

foreach($sourceportgroup in $SourcePortgroups){
    [void] $listBox.Items.Add($sourceportgroup)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $sourceportgroup = $listBox.SelectedItem

}

##########################################################################################################################

#Target Portgroup portgroup Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Source DPG'
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,240)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,240)
$cancelButton.Size = New-Object System.Drawing.Size(150,46)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,40)
$label.Size = New-Object System.Drawing.Size(560,40)
$label.Text = 'Select a Source DPG:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(520,40)
$listBox.Height = 160
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Regular)
$listbox.SelectionMode = 'MultiExtended'

foreach($targetPortgroup in $targetPortgroups){
    [void] $listBox.Items.Add($targetPortgroup)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $targetPortgroup = $listBox.SelectedItem

}

##########################################################################################################################

#Collect all VM's from source Portgroup
Write-Host "Collecting VM's on selected portgroup"

$filteredVMs = @()
 
foreach ($singlesourcevm in $SourceVMs){
    $singlevmnetwork = ($singlesourcevm | Get-NetworkAdapter).NetworkName
    if ($singlevmnetwork -eq $sourceportgroup){
        $filteredVMs += $singlesourcevm
        }
    }
        
Write-Host "Below are the VM's that will be moved with this migration"
$filteredVMs.name

Start-Sleep 10

#exclusion portion
#Look for VMs with multiple datastores and setup array for exclusions
Write-Host "Collecting exclusion VM's with multiple datastores"
$multidsarray = @()
foreach ($singlevm in $HostVMs){
    $temparray1 = "" | select Name
    $dscount = ($singlevm | Get-Datastore).count
    if ($dscount -ne "1"){
        $singlevm.Name = $temparray1.Name
        $multidsarray += $temparray1
    }
}


Start-Sleep 3

#Execution portion
foreach ($singlevm in $filteredvms){
    if ($multidsarray -contains $singlevm.name){
        Write-Host "VM $singlevm is in datastore exclusion list, skipping"
    }
    else{
        #find the folder the VM is currently using and verify folder exists on destination VCSA
        $TargetVMFolderCheck = $targetDatacenter | Get-Folder | where {$_.type -eq "VM"}
         if ($TargetVMFolderCheck.Name -notcontains $Singlevm.Folder.Name){
            Write-host "WARNING - Folder not discovered in target Cluster! Folder Migration will Fail."
            Write-host "------------------------------------------------------------------------"
            Read-Host "Press any key to continue or Ctrl + C to stop the script"
         }

        #Start pings
        Write-Host "Creating continuous ping for VM $singlevm"
        $FirstIP = (get-vm $singlevm).Guest.IPAddress[0] 
        $args = "/k ping $FirstIP -t"
        Start-Process -FilePath "$env:comspec" -ArgumentList $args

        #Pull tags from Source VM
        $vmtags = get-vm $singlevm | Get-TagAssignment


        #Select random host from Target Cluster to migrate to
        $targetHost = get-Cluster $TargetCluster | get-vmhost | where{$_.ConnectionState -eq “Connected”} | get-random

        #Get Target VM Folder name
        $targetVMFolder = $targetDatacenter | Get-Folder | where{($_.type -eq "VM") -and ($_.name -eq $singlevm.Folder.Name)}

        #start VM Migration
        Write-Host "Migrating vm $singlevm to Target VCSA Host $targetHost"
        $singlevm | Move-VM -Destination $targethost -PortGroup $targetDPG -WhatIf

        #start Folder Migration
        Write-Host "Migrating vm $singlevm to Target VCSA Folder $targetVMFolder"
        $singlevm | Move-VM -Destination $TargetVMFolder -WhatIf

        #Re-Apply Tags (needs work)
        #$vmtags | %{get-vm $singlevm -Server $DestVC | New-TagAssignment -Tag ($_.Tag).name -Server $DestVC | Select Entity, Tag}


        
    }
}