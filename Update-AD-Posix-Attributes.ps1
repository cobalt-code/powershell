#
# (c)2020 Hans-Helmar Althaus <althaus(at)m57.de>
#
# this script is intended for all people that do want thier user-account
# to get explicit posix properties from Active Dirctory. To use it you will
# have to add all managed accounts to a AD-Security-Group "unix" the script 
# will get all members of this group and add the required posix attributes
# to the user-objects. Attributes of user-objects that have values wil left
# untouched. The script will start with the numerical RID of the user-object
# to search for a free uidNumber ( the searchRange is 250 ).
#
# this powershell script must be run with sufficent permissions
#

import-module ActiveDirectory

# parameters that may have to adjusted
$loginShell   = '/bin/bash' # other people prefer /bin/csh, users login shell
$GroupName    = 'unix' # a universal security group off all unix accounts, used as users primary group
$uidNumberMin = 1000 # on most linux distributions uids below 1000 are reserved for local accounts
$gidNumberMin = 1000 # on most linux distributions gids below 1000 are reserved for local groups
$searchRange  =  250 # how many uids to test to be free from starting point

switch ((Get-ADDomain).Forest) {                        
  "1st-domain.de" { $DomainOffset = 20000 }                     
  "2nd-domain.de" { $DomainOffset = 10000 }                        
   Default        { $DomainOffset = 0 }
}

# 
# no more changes below this line
#

function Get-uidNumber( [Int] $uidNumber = $uidNumberMin ) {
# start to search for free uidNumer even at $uidNumberMin
# or at value given to function, return uidNumber
# or 0 if all numbers in the range are allocated

  $offset = 0
  while ( $offset -lt $searchRange ) {
    $UID = $uidNumber + $offset + $DomainOffset
    $filter = "uidNumber=" + $UID
    $object = $( try { Get-ADObject -LDAPFilter $filter } catch {$null} )
    if ( $object -eq $null ) { return $UID }
    $offset++
  }

  "  failed to find gidNumber: between:" + ( $uidNumber + $DomainOffset ) + `
     "and" + ( $uidNumber + $searchRange + $DomainOffset ) `
     | write-host -ForegroundColor Red
  return 0
}

function Get-gidNumber( [Int] $gidNumber = $gidNumberMin ) {
# start to search for free gidNumer even at $gidNumberMin
# or at value given to function, return gidNumber
# or 0 if all numbers in the range are allocated

  $offset = 0
  while ( $offset -lt 250 ) {
    $GID = $gidNumber + $offset + $DomainOffset
    $filter = "&(gidNumber=" + $GID + ")(ObjectClass=group)"
    $object = $( try { Get-ADObject -LDAPFilter $filter } catch {$null} )
    if ( $object -eq $null ) { return $GID }
    $offset++
  }

  "  failed to find gidNumber:" + ( $gidNumber + $DomainOffset ) + `
     "and" + ( $gidNumber + $searchRange + $DomainOffset ) `
    | write-host -ForegroundColor Red
  return 0
}

function addUnixAttributes {

  # ensure that the "PrimaryUserGroup" has at least a gidNumber

  $filter = "CN=" + $GroupName
  $ADObject = $( try { Get-ADObject -LDAPFilter $filter -Properties '*' } catch {$null} )
  
  "processing: " + $ADObject.DisplayName + " ( object is a Group )" | write-host -ForegroundColor Green
  "  objectSID: " + $ADObject.ObjectSID.value | write-host -ForegroundColor Gray
  $SIDT, $SIDRV, $SIDIA, $SIDST, $SID1, $SID2, $SID3, $RID = $ADObject.ObjectSID.value.split('-')
  "  group RID: " + $RID | write-host -ForegroundColor Gray

  if ( $ADObject.gidNumber -ne $null ) {
    $gidNumber = $ADObject.gidNumber
    "  gidNumber is: " + $gidNumber | write-host -ForegroundColor Yellow
    } else {
      $gidNumber = Get-gidNumber( $RID )
      if ( $gidNumber -lt $gidNumberMin ) {
      "  no free gidNumber" | write-host -ForegroundColor Red
    } else {
      "  setting gidNumber to $gidNumber" | write-host -ForegroundColor Red
      Set-ADGroup -Identity $ADObject -Replace @{ gidNumber = "$gidNumber" }
    }
  }
  
  if ( $gidNumber -lt $gidNumberMin ) {
    "  gidNumber is not acceptable" | write-host -ForegroundColor Red
  } else {
    ForEach ( $object in $input ) {
      $filter = "distinguishedName=" + $object.distinguishedName
      $ADObject = $( try { Get-ADObject -LDAPFilter $filter -Properties '*' } catch {$null} )
  
      if ( $ADObject -ne $null ) {

        if ( $ADObject.ObjectClass -eq "User" ) {

          "processing: " + $ADObject.DisplayName + " ( object is a User )" | write-host -ForegroundColor Green
          "  objectSID: " + $ADObject.ObjectSID.value | write-host -ForegroundColor Gray
          $SIDT, $SIDRV, $SIDIA, $SIDST, $SID1, $SID2, $SID3, $RID = $ADObject.ObjectSID.value.split('-')
          "  users RID: " + $RID | write-host -ForegroundColor Gray

          if ( $ADObject.gidNumber -ne $null ) {
            "  gidnumber is: " + $ADObject.gidNumber | write-host -ForegroundColor Yellow
          } else {
            "  setting gidNumber to $gidNumber" | write-host -ForegroundColor Red
            Set-ADUser -Identity $ADObject -Replace @{ gidNumber = "$gidNumber" }
          }

          if ( $ADObject.uidNumber -ne $null ) {
            "  uidNumber is: " + $ADObject.uidNumber | write-host -ForegroundColor Yellow
            } else {
            $uidNumber = Get-uidNumber( $RID )
            if ( $uidNumber -lt $uidNumberMin ) {
              "  no free uidNumber" | write-host -ForegroundColor Red
            } else {
              "  setting uidNumber to $uidNumber" | write-host -ForegroundColor Red
              Set-ADUser -Identity $ADObject -Replace @{ uidNumber = "$uidNumber" }
            }
          }

          if ( $ADObject.unixHomeDirectory -ne $null ) {
            "  unixHomeDirectory is: " + $ADObject.unixHomeDirectory | write-host -ForegroundColor Yellow
          } else {
            $attribute = "/home/$($ADObject.sAMAccountName)"
            "  setting unixHomeDirectory to $attribute" | write-host -ForegroundColor Red
            Set-ADUser -Identity $ADObject -Replace @{ unixHomeDirectory = "$attribute" }
          }

          if ( $ADObject.loginShell -ne $null ) {
            "  loginShell is: " + $ADObject.loginShell | write-host -ForegroundColor Yellow
          } else {
            "  setting loginShell to $loginShell" | write-host -ForegroundColor Red
            Set-ADUser -Identity $ADObject -Replace @{ loginShell = "$loginShell" }
          }
        }
      }
    }
  }
}

Get-ADGroupMember $GroupName | addUnixAttributes
