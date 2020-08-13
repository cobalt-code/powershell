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
