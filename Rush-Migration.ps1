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

foreach ($Sourcevcenter in $Sourcevcenterlist) {
    Write-Host "Connecting to $Sourcevcenter"
    Try {connect-viserver $Sourcevcenter -Credential $sourceVCSACredentials} Catch {Connection-Alert $Sourcevcenter ;break}
    }

foreach ($Targetvcenter in $Targetvcenterlist) {
    Write-Host Connecting to "$Targetvcenter"
    Try {connect-viserver $Targetvcenter -Credential $targetVCSACredentials} Catch {Connection-Alert $Targetvcenter ;break}
    }

#Get all VM an Host Variables
Write-host "Defining all Variables"
$Getallclusters = Get-Cluster
$GetAllHosts = Get-VMHost
Write-Host "done"

#Add Target Distributed PortGroup
$targetDPG = ""


##########################################################################################################################

#Source Host Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Source Host for VM Migration'
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
$label.Text = 'Select a Source Host for VM Migration:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,80)
$listBox.Size = New-Object System.Drawing.Size(520,40)
$listBox.Height = 160
$listBox.Font = New-Object System.Drawing.Font("Lucida Console",12,[System.Drawing.FontStyle]::Regular)
$listbox.SelectionMode = 'MultiExtended'

foreach($singleHost in $GetallHosts){
    [void] $listBox.Items.Add($singleHost)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $SourceHost = $listBox.SelectedItem

}

############################################################################################################################


#Target Cluster Selection Box
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Target Cluster for VM Migration'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Select a Target Cluster for VM Migration'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80
$listbox.SelectionMode = 'MultiExtended'

foreach($singleCluster in $GetallClusters){
    [void] $listBox.Items.Add($singleCluster)
}

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    
    $TargetCluster = $listBox.SelectedItem

}

############################################################################################################################

#Collect all VM's from source Host
Write-Host "Collecting VM's on host"
$HostVMs = Get-VMHost -Name $SourceHost | Get-VM | where {($_.ExtensionData.Config.ManagedBy.ExtensionKey -notlike '*com.vmware.vcDr*')}
Start-sleep 3

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
foreach ($singlevm in $HostVMs){
    if ($multidsarray -contains $singlevm.name){
        Write-Host "VM $singlevm is in datastore exclusion list, skipping"
    }
    else{
        #find the folder the VM is currently using and verify folder exists on destination VCSA
        $TargetVMFolderCheck = get-datacenter -name "TARGET DATACENTER" | Get-Folder | where {$_.type -eq "VM"}
         if ($TargetVMFolderCheck.Name -notcontains $Singlevm.Folder.Name){
            Write-host "WARNING - Folder not discovered in target Cluster! Migration will Fail."
            Write-host "------------------------------------------------------------------------"
            Read-Host "Press any key to continue"
         }

        #Start pings
        Write-Host "Creating continuous ping for VM $singlevm"
        $FirstIP = (get-vm $singlevm).Guest.IPAddress[0] 
        $args = "/k ping $FirstIP -t"
        Start-Process -FilePath "$env:comspec" -ArgumentList $args

        #Pull tags from Source VM
        $vmtags = get-vm $singlevm | Get-TagAssignment


        #Select random host from Target Cluster to migrate to
        $targetHost = get-Cluster $TargetCluster | get-vmhost | where{$_.ConnectionState -eq “Connected”}| get-random

        #Get Target VM Folder name
        $TargetVMFolder = Get-Datacenter -name "RUMC" | Get-Folder | where{($_.type -eq "VM") -and ($_.name -eq $singlevm.Folder.Name)}


        #start VM Migration
        Write-Host "Migrating vm $singlevm to Target VCSA Host $targetHost"
        $singlevm | Move-VM -Destination $targethost -PortGroup $targetDPG -WhatIf

        #start Folder Migration
        Write-Host "Migrating vm $singlevm to Target VCSA Folder $TargetVMFolder"
        $singlevm | Move-VM -Destination $TargetVMFolder -WhatIf

        #Re-Apply Tags (needs work)
        #$vmtags | %{get-vm $singlevm -Server $DestVC | New-TagAssignment -Tag ($_.Tag).name -Server $DestVC | Select Entity, Tag}


        
    }
}
