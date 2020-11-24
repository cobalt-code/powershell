# powershell
powershell Tools to speed up things

1) Update-AD-Posix-Attributes.ps1

this script is intended for all people that do want thier user-account
to get explicit posix properties from Active Dirctory. To use it you will
have to add all managed accounts to a AD-Security-Group "unix" the script 
will get all members of this group and add the required posix attributes
to the user-objects. Attributes of user-objects that have values wil left
untouched. The script will start with the numerical RID of the user-object
to search for a free uidNumber ( the searchRange is 250 ).

2) Create-AutoFS-Maps.ps1

this script is intended to create autofs-maps in active directory to be 
served by sssd to autofs this script will provide so called indirect maps.
The created maps must not be unique, so it is possible to create them in 
different OUs to serve different locations.

3) Split-VCF.ps1

this script is intended to split multi enty VCF file as created by LotusNote
into multiple single entry VCF files that can be used to import contacts to
Miucrosoft Outlook.

4) Split-VCF.bat

this wrapper may be used to run Powershell script on a computer that requires
signed powershell-scripts.
