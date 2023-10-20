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
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",20,[System.Drawing.FontStyle]::Regular)
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
$SourcePortgroups = Get-VDPortgroup | Sort-Object
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
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",20,[System.Drawing.FontStyle]::Regular)
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
$targetPortgroups = Get-VDPortgroup | Sort-Object
$targetDatastores = Get-Datastore

Disconnect-VIServer "*" -confirm:$False

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
$form.Size = New-Object System.Drawing.Size(1200,800)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,650)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,650)
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
$listBox.Size = New-Object System.Drawing.Size(1000,40)
$listBox.Height = 500
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",15,[System.Drawing.FontStyle]::Regular)
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

#Target Portgroup Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Target Portgroup'
$form.Size = New-Object System.Drawing.Size(1200,800)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,650)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,650)
$cancelButton.Size = New-Object System.Drawing.Size(150,46)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,40)
$label.Size = New-Object System.Drawing.Size(560,40)
$label.Text = 'Select a Target Portgroup:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(1000,40)
$listBox.Height = 500
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",15,[System.Drawing.FontStyle]::Regular)
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

#Target Cluster Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Target Cluster'
$form.Size = New-Object System.Drawing.Size(1200,800)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,650)
$okButton.Size = New-Object System.Drawing.Size(150,46)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(300,650)
$cancelButton.Size = New-Object System.Drawing.Size(150,46)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,40)
$label.Size = New-Object System.Drawing.Size(560,40)
$label.Text = 'Select a Target Cluster:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(1000,40)
$listBox.Height = 500
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",15,[System.Drawing.FontStyle]::Regular)
$listbox.SelectionMode = 'MultiExtended'

foreach($targetCluster in $targetClusters){
    [void] $listBox.Items.Add($targetCluster)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $targetCluster = $listBox.SelectedItem

}
##########################################################################################################################

#Collect all VM's from source Portgroup
Write-Host -BackgroundColor Green "Collecting VM's on selected portgroup"

$filteredVMs = @()

foreach ($singlesourcevm in $SourceVMs){
    $singlevmnetwork = ($singlesourcevm | Get-NetworkAdapter).NetworkName
    if ($singlevmnetwork -eq $sourceportgroup){
        $filteredVMs += $singlesourcevm
        }
    }
        

Write-Host ""
Write-Host -ForegroundColor Green "Below are the VM's that will be moved with this migration"
Write-Host ""
Write-Host ""
$filteredVMs.name
Write-Host ""
Write-Host ""


Start-Sleep 10

#exclusion portion
#Look for VMs with multiple datastores and setup array for exclusions
Write-Host "Collecting exclusion VM's with multiple datastores"
$multiDSexclusion = @()
foreach ($singlevm in $filteredVMs){
    $temparray1 = "" | select Name
    $dscount = ($singlevm | Get-Datastore).count
    if ($dscount -ne "1"){
        $temparray1.name = $singlevm.Name
        $multiDSexclusion += $temparray1
    }
}

Write-Host ""
Write-Host -BackgroundColor Red "The following VM's will not be migrated due to multi-datastore exclusion"
Write-Host ""
Write-Host ""
$multiDSexclusion.Name
Write-Host ""
Write-Host ""

Start-Sleep 10

#Execution portion
foreach ($singlevm in $filteredvms){

    

    #multi-DS exclusion
    if ($multiDSexclusion.name -contains $singlevm.name){
        Write-Host ""
        Write-Host -BackgroundColor Red "VM $singlevm is in datastore exclusion list, skipping"
        Continue
    }

    #Snapshot Exclusion | Best practice is to have no snapshot while doing a cross vcenter migration. Excluding any VM with a snapshot and reccomend to remove them before migration.
    $snapshotcount = ($singlevm | Get-Snapshot).count
    if($snapshotcount -gt 0){
        Write-Host ""
        Write-Host -BackgroundColor Red "VM $singlevm has a snapshot that needs to be removed, skipping"
        Continue
    }

    #nics greater than 3 exception
    $Netadaptercount = ($singlevm | Get-NetworkAdapter).count
    if($Netadaptercount -ge 3){
        Write-Host ""
        Write-host -BackgroundColor red "VM $singlevm has 3 or more NICs' This is curently not supported. Skipping VM"
        continue
    }
    
    else{
        #check for multi nic adaptor. Select new portgroup for the second nic and add to move vm network array
        $AllTargetportgroups = @()

        if($Netadaptercount -eq 2){
        Write-Host "NET ADAPTER COUNT IS MORE THAN 1"
        ##########################################################################################################################

        #Target Portgroup portgroup for 2nd nic Selection Box
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Select a Target Potrgroup for 2nd NIC'
        $form.Size = New-Object System.Drawing.Size(1200,800)
        $form.StartPosition = 'CenterScreen'

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(150,650)
        $okButton.Size = New-Object System.Drawing.Size(150,46)
        $okButton.Text = 'OK'
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(300,650)
        $cancelButton.Size = New-Object System.Drawing.Size(150,46)
        $cancelButton.Text = 'Cancel'
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        $form.Controls.Add($cancelButton)

        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(20,40)
        $label.Size = New-Object System.Drawing.Size(560,40)
        $label.Text = 'Select a Target Potrgroup for 2nd NIC:'
        $form.Controls.Add($label)

        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Location = New-Object System.Drawing.Point(20,80)
        $listBox.Size = New-Object System.Drawing.Size(1000,40)
        $listBox.Height = 500
        $listBox.Font = New-Object System.Drawing.Font("Lucida Console",15,[System.Drawing.FontStyle]::Regular)
        $listbox.SelectionMode = 'MultiExtended'

        foreach($targetPortgroup2 in $targetPortgroups){
        [void] $listBox.Items.Add($targetPortgroup2)
        }

        $form.Controls.Add($listBox)

        $form.Topmost = $true

        $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
        $targetPortgroup2 = $listBox.SelectedItem
    }

    $AllTargetportgroups += $targetPortgroup
    $AllTargetportgroups += $targetPortgroup2
}

        if($Netadaptercount -eq 1){
            write-host "NET ADAPTER COUNT is 1"
            $AllTargetportgroups += $targetPortgroup
        }

        #find the folder the VM is currently using and verify folder exists on destination VCSA
        $TargetVMFolderCheck = $targetDatacenter | Get-Folder | where {$_.type -eq "VM"}
        if ($TargetVMFolderCheck.Name -notcontains $Singlevm.Folder.Name){
            Write-host "WARNING - Folder not discovered in target Cluster! Folder Migration will Fail."
            Write-host "------------------------------------------------------------------------"
            Read-Host "Press any key to continue or Ctrl + C to stop the script"
        }

        Start-Sleep 5

        Write-Host -BackgroundColor green "---------------------------------"
        Write-host -BackgroundColor green -ForegroundColor red "Migrating vm $singlevm"
        Write-Host -BackgroundColor green "---------------------------------"

        #Start pings
        Write-Host "Creating continuous ping for VM $singlevm"
        $FirstIP = (get-vm $singlevm).Guest.IPAddress[0] 
        $args = "/k ping $FirstIP -t"
        Start-Process -FilePath "$env:comspec" -ArgumentList $args

        #Pull tags from Source VM
        $vmtags = get-vm $singlevm | Get-TagAssignment

        #define target datastore
        $sourceDatastore = ($singlevm | Get-Datastore)
        $targetDatastore = foreach ($singleDatastore in $targetDatastores){
            if ($singleDatastore.name -contains $sourceDatastore.name){
                $singleDatastore
            }
        }

        #Select random host from Target Cluster to migrate to
        $targetHost = $TargetCluster | get-vmhost | where{$_.ConnectionState -eq “Connected”} | get-random

        #Get Target VM Folder name
        $targetVMFolder = $targetDatacenter | Get-Folder | where{($_.type -eq "VM") -and ($_.name -eq $singlevm.Folder.Name)}

        #start VM Migration
        Write-Host -ForegroundColor Green "Migrating vm $singlevm to Target VCSA Host $targetHost"
        $singlevm | Move-VM -Destination $targetHost -PortGroup $AllTargetportgroups -datastore $targetDatastore

        #redefine VM Object in target VCSA
        $singlevmdest = get-vm | where {$_.name -like $singlevm.name}

        #start Folder Migration
        Write-Host -ForegroundColor Green "Migrating vm $singlevm to Target VCSA Folder $targetVMFolder"
        $singlevmdest | Move-VM -Destination $TargetVMFolder

        #Re-Apply Tags (needs work)
        #$vmtags | %{get-vm $singlevm -Server $DestVC | New-TagAssignment -Tag ($_.Tag).name -Server $DestVC | Select Entity, Tag}

        $AllTargetportgroups = $null
        
    }
}

#Clear All Variables
$SourceDatacenter = $null
$sourceHosts = $null
$sourceClusters = $null
$SourcePortgroups = $null
$SourceVMs = $null
$targetDatacenter = $null
$targetHosts = $null
$targetClusters = $null
$targetPortgroup = $null
$targetDatastores = $null
$filteredVMs = $null
$SourceVMs = $null

Disconnect-VIServer "*" -Confirm:$false
