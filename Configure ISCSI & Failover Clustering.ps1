#--- Author : Ali Hojaji ---#

#--*-----------------------------------------*--#
#---> ISCSI & Configure Failover Clustering <---#
#--*-----------------------------------------*--#

#--> start iscsi initiator service on both nodes
Invoke-Command CL1-TEST,CL2-FKT { Get-Service *iscsi* |Set-Service -StartupType Automatic -PassThru | Start-Service }

#--> view iscsi initiator addresses
Invoke-Command CL1-TEST,Cl2-TEST { Get-InitiatorPort }

#--> create iscsi target portal for discovery
Invoke-Command CL1-TEST,CL2-TEST { New-IscsiTargetPortal -TargetPortalAddress 192.168.3.105 }


#---> iSCSI Target <---#


#--> create iscsi lun
Invoke-Command FS-TEST { New-IscsiVirtualDisk -Path D:\CL-DataDisk.vhdx -SizeBytes 100GB }
Invoke-Command FS-TEST { New-IscsiVirtualDisk -Path D:\CL-QuorumDisk.vhdx -SizeBytes 1GB }

#--> create iscsi target
Invoke-Command FS-TEST { New-IscsiServerTarget -TargetName CL-Target -InitiatorIds "IQN:iqn.1991-05.com.microsoft:cl1-fkt.farkiantech.com","IQN:iqn.1991-05.com.microsoft"

#--> assign luns to target
Invoke-Command FS-TEST { Add-IscsiVirtualDiskTargetMapping -TargetName CL-Target -Path D:\CL-DataDisk.vhdx }
Invoke-Command FS-TEST { Add-IscsiVirtualDiskTargetMapping -TargetName CL-Target -Path D:\CL-QuorumDisk.vhdx }


#---> iSCSI Initiators (post-targ) <---#


#--> update discovery Portal with new target information
Invoke-Command CL1-TEST,CL2-TEST { Get-IscsiTargetPortal | Update-IscsiTargetPortal }

view iscsi target
Invoke-Command CL1-TEST,CL2-TEST { Get-IscsiTarget } 

#--> connect initiators to target
Invoke-Command CL1-TEST,CL2-TEST { Get-IscsiTarget | connect-IscsiTarget }

#--> forece the connection to persist (across reboots)
Invoke-Command CL1-TEST,CL2-TEST { Get-IscsiSession | Register-IscsiSession }


#---> Failover Clustering  <---#

#--> install failover clustering feature on both nodes
Invoke-Command CL1-TEST,CL2-TEST { Install-WindowsFeature Failover-Clustering }

#--> run cluster validation
Test-Cluster -Node CL1-TEST,CL2-TEST

#--> create a new cluster (multi-domain/workgroup - no network name)
New-Cluster -Name CL-TEST -Node CL1-TEST,CL2-TEST -StaticAddress 192.168.1.150 -AdministrativeAccessPoint Dns