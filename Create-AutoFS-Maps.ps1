#
# (c)2020 Hans-Helmar Althaus <althaus(at)m57.de>
# create autofs-maps in active directory to be served by sssd
# this script will provide so called indirect maps.
#
# the created maps must not be unique, so it is possible to 
# create them in different OUs to serve different locations
# 

import-module ActiveDirectory

$TargetOU='OU=TST,OU=Sites,DC=mydomain,DC=com'

# create the map auto.master
New-ADObject -type nisMap -name auto.master -path $TargetOU `
  -otherAttributes @{ nisMapName='auto.master' }

## map "home"

# add the map auto.home with mount-point /home to auto.master
New-ADObject -type nisObject -name /home -path "CN=auto.master,$TargetOU" `
  -otherAttributes @{ nisMapName='auto.master'; nisMapEntry='auto.home' }

# create the map autofs.home
New-ADObject -type nisMap -name auto.home -path $TargetOU `
  -otherAttributes @{ nisMapName='auto.home' }

# add the special autofs-key '*' and nfs-export, '&' in the target is replaced by the key
New-ADObject -type nisObject -name '*' -path "CN=auto.home,$TargetOU" `
  -otherAttributes @{ nisMapName='auto.home'; nisMapEntry='-tcp,v4.2 NFSSERVER:/export/fs3/home/&' }

## map "share"

# add the map auto.share with mount-point /share to auto.master
New-ADObject -type nisObject -name /share -path "CN=auto.master,$TargetOU" `
  -otherAttributes @{ nisMapName='auto.master'; nisMapEntry='auto.share' }

# create the map autofs.share
New-ADObject -type nisMap -name auto.share -path $TargetOU `
  -otherAttributes @{ nisMapName='auto.share' }

# add the autofs-key mirror and nfs-export to auto.share
New-ADObject -type nisObject -name mirror -path "CN=auto.share,$TargetOU" `
  -otherAttributes @{ nisMapName='auto.share'; nisMapEntry='-tcp,v4.2 NFSSERVER:/export/fs1/share/mirror' }
  
# add the autofs-key software and nfs-export, repeat this step as often you need
New-ADObject -type nisObject -name software -path "CN=auto.share,$TargetOU" `
  -otherAttributes @{ nisMapName='auto.share'; nisMapEntry='-tcp,v4.2 NFSSERVER:/export/fs2/share/software' }
