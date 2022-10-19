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
We use Foundary and VSCode as our smart contract development toolchain.
* Install Foundary: https://book.getfoundry.sh/getting-started/installation
* Install the Solidity plugin for VSCode: https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity
* Clone the repository
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