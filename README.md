```
 _____               ______  _         _   _        _   
/  ___|              | ___ \(_)       | \ | |      | |  
\ `--.  _   _  _ __  | |_/ / _   ___  |  \| |  ___ | |_ 
 `--. \| | | || '_ \ | ___ \| | / _ \ | . ` | / _ \| __|
/\__/ /| |_| || | | || |_/ /| || (_) || |\  ||  __/| |_ 
\____/  \__, ||_| |_|\____/ |_| \___/ \_| \_/ \___| \__|
         __/ |                                          
        |___/                                                 
```
# SynBioNet Protocol v1
This repository contains the smart contract source code for v1 of the SynBioNet.

## What is SynBioNet?
SynBioNet is a non-custodial market protocol designed to encourage and incentivize innovation and collaboration around synthetic biology.

## Documentation
TODO

## Setup 
We use Foundary and VSCode (optional) as our smart contract development toolchain.
* Install Foundary: https://book.getfoundry.sh/getting-started/installation
* Install the Solidity plugin for VSCode: https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity
* Clone this repository
* From this directory, run `forge install`

VSCode settings via `.vscode/setting.json`:
```json
{
    "solidity.packageDefaultDependenciesContractsDirectory": "src",
    "solidity.packageDefaultDependenciesDirectory": "lib",
    "search.exclude": {
        "lib": true
    }
}
```
## Test
You can run all the tests with the following command:

```bash
 > forge test -vvv
```
`-vvv` is for extra verbosity

## Build
For now we include the core `abis` in the repository (artifacts dir) so other projects can import the artifacts for use via `npm`.  However, this package is not yet published on `npm`, so install with `npm` using the github project URL.

Before commiting new contract code, run `make artifacts` to update the `abis`


