## Reviewed commits

- cab7fc59a8ee73994f46f2556f3db4546b882ced - **Feature: Initial support for UDE**
- 81724cd64f63b084e4098e1c3aecdac2b5d8b754 - Fix: BOM on files
- 72f4df0d273ddb06a5507d4392d7302d0beb1fb8 - Docs: Updated CBH formatting
- 13993864ad980611a20578afc04a5de3754d77a7 - Fix: missing help details for AxExcelOutput
- 2a18e2ca8d7d1332d69aa2d2c3f971b3aa6c7eb2 - Refactor: Improve the worksheet name for all AxExcelOutput
- 31e62b1407eccaeb0f4d36869a3c8d0c6ad125c7 - Fix: SuppressMessages and Output errors
- ae88488b16b8ce9a579cb35b6d6cf7dc285a2891 - Fix: unit test errors
- b91fee742bb0fd078950559fa0e826c2ee939f58 - Fix: Add missing doc files
- e2c7be620033165f69ccdff1029bb04545a31cc9 - *Merge pull request #29 from Splaxi/ude-support*
- f762c7c37653b9863f9da9e0ebe5c6e9a11278ce - *New release* `0.0.17`
- 57d6dc7969802406be57a4f9d9e0536b9dfaf6da - **Feature: Add Defender support and Vs2022 installation validation**
- 8af1bd6b49a739f97139932a463ffc6c2815b36d - Fix: Download in external windows failed on file validation
- 15bb65c62a1d7d759da9e1f231752d33ae227752 - Fix: All unit test should work in PowerShell5 - so generation has to be done in PowerShell 5
- d5a31d2c633e52af80f69ddda0e4265ff1777d7d - Fix: failing unit tests
- 9cb2e3c50d845307474482a624d60522e1f08a16 - Fix: failing unit tests
- 7969fd998df65a56af43233f97e62ee03e9c453c - **Feature: Clear-UdeDbJitCache**
- 79873d658a4a75a27d54ebe79436747217f938fc - *Merge pull request #31 from d365collaborative/impl-defender-and-confirmVs* `0.0.18`
- 4965b9cd5e7262bda549f1074188ca27fc341126 - **Feature: FnO modules + packages from the API exposed**
- f44d040defcd8631b320a0b75cc6fccc74d3ecb6 - Fix: Unit tests failed
- 95f1f683d503c70bd6f25a5ee0a54c256bc80327 - Feature: FnO modules + packages from the API exposed
- d63a93481e181f12c12565b6746a64d27a5ebd0c - Feature: FnO modules + packages from the API exposed - Get-BapEnvironmentOperation
- e88e55dac11fea2990d890e333e7a61ab3eceedd - Feature: FnO modules + packages from the API exposed - Get-BapEnvironment
- 2d4237db69f1e9a4f8297881d9b13cc1e6a000b7 - **Feature: FnO modules + packages from the API exposed - Security and Database refresh/copy**
- 54a4847324beeebe34085776fed345239960c9e3 - Feature: FnO modules + packages from the API exposed - database copy/refresh
- b7037b82a2d448925255147a4b63f0b6b7f5e433 - *Merge pull request #39 from d365collaborative/v-next* `0.0.19`
- 36fa9d22b4f245c1153fce12076813af2c678378 - **Feature: Bap + FnO - User Management** + Admin Mode
- 2ce0f31ad3a0f3ebc728fd1dc44d46eb912104fc - Feature: Bap + FnO - User Management
- b1e94e29503afc527e146be4854f85f70f4e0a4d - *Merge pull request #42 from d365collaborative/v-next*
- 51c601f0f7345d871cc00f98a5abc4eddf1f1a8c - Feature: Bap + FnO - User Management
- eecfa2b429ff3bac56f4468faa315a82d7d6dcb6 - *Merge pull request #44 from d365collaborative/v-next* `0.0.20`
- f97459a5b9fbbf9067e8a0c9745cbfe306d999a4 - Fix: Minor issues
- bc5bc255caeddc98151b5d054a22c88d04a897fa - Fix: Minor issues
- 9e26317b66c3ff2d0e32333faa7464c183483781 - Fix: Minor issues
- 5b3fd62221ff3b5d3cc6fcd0812d2a22d59de4a0 - *Merge pull request #45 from d365collaborative/v-next* `0.0.21`
- a8421d975fb2d4806e256d7049e2992eaa101d10 - **Feature: Add FnOAppUpdate capabilities**
- 24d2e10b9180388fbc5a3995c18debf8700ef7e1 - Feature: Add FnOAppUpdate capabilities
- ba695d35520b5ec9931a32170092230b9c9afab6 - *Merge pull request #50 from d365collaborative/v-next* `0.0.22`

## General

- line breaks with \` in commands: replace with splatting or just breaking the line after a pipe `|`?
- AzAccount authorization should be done once in one central place
- checking for modules like TUN.CredentialManager should be done once in one central place
- casing of acronyms: UDE vs Ude
  - seems in command names, it is Ude, but in comments and documentation it is often UDE
- check for Administrator rights and force execution should be centralized
- centralize environment check
- store API endpoints in central place to have an easy overview
- for commands that start an environment action (like version update or database refresh), a switch should control if the command waits for completion or just returns the operation id

## Clear-UdeCredentialCache

- way that the `-Force` parameter is used: should that not be a whatif instead combined with `[ConfirmImpact("High")]`?
  - same question for `Clear-UdeOrphanedConfig`
- should this really remove the whole folder? could this be more surgical and only remove certain files?
- should there be any logging of what was removed?

## Get-UdeDbJit

- `Get` verb is maybe not the best here; the whole name is rather cryptic
- authorization could provide a better user experience
  - check for connected AzAccount and trigger login if necessary with some guidance in case of multiple tenants
  - handle issue when no token could be obtained
  - authorization is used in multiple places; could be refactored into a separate function

## Get-UdeDbJitCache

- also cryptic name

## Get-UdeDeveloperFiles

- nice!
- parallel download could probably be done in current powershell session
- code could be cleaned up a bit

## Get-UdeXrefDb

- that just lists databases that are not the standard ones
- why is this needed? > for the configuration

## Invoke-BapInstallAzCopy

- use `Install` verb instead

## Set-UdeConfig

- nice!
- it creates a new configuration, so verb should be `New` instead of `Set`

## Start-UdeDbSsms

- nice!
- requires 3 commands, maybe this could be done in one command?

## Add-UdeWindowsDefenderRules

- check for Administrator rights and force execution should be centralized
- are IIS and IISExpress still needed?

## Confirm-UdeVs2022Installation

- I thought community edition is also supported?
- not sure I like the `Confirm` verb here, as the command is doing a lot of installs

## Start-UdeDatabaseRefresh

- Would be nice to also check whether source environment is UDE, in which case the database copy is not supported

## Check tutorials

- `Get-BapEnvironment`