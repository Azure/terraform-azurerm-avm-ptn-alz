@echo off

echo avm: this launcher is no longer supported. 1>&2
echo( 1>&2
echo The container/make based AVM toolchain has been replaced by the Avm.Authoring 1>&2
echo PowerShell module. Install it from the PowerShell Gallery and run avm from 1>&2
echo PowerShell instead: 1>&2
echo( 1>&2
echo     Install-PSResource -Name Avm.Authoring -Scope CurrentUser -TrustRepository 1>&2
echo     Import-Module Avm.Authoring 1>&2
echo     avm --help 1>&2
echo( 1>&2
echo See https://github.com/Azure/azure-verified-modules-tools for details. 1>&2

exit /b 1
