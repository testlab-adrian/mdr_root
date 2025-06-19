# function Get-CleanString {
#     [CmdletBinding()]
#     [OutputType([string])]
#     param (
#         [Parameter(Mandatory = $true)]
#         [AllowEmptyString()]
#         [string]
#         $Value
#     )

#     function Deploy-Rules {
#         [CmdletBinding()]
#         [OutputType([string])]
#         param (
#             [Parameter(Mandatory = $true)]
#             [string]
#             $customerName,
#             # List of full file paths to deploy
#             [Parameter(Mandatory = $true)]
#             [string[]]
#             $rulePaths
#         )

#         foreach ($path in $rulePaths){
#             $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($path)

#             Write-Host "Deploying Rule: $ruleName from $path"
#         }


#     }