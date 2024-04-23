# PixeLAW App template
For additional step-by-step explanations on how to build and deploy your own PixeLAW app follow along [here](https://pixelaw.github.io/book/getting-started/quick-start-mud.html)!

# Prerequisites

## MUD
PixeLAW is built on top of MUD. Refer to this [page](https://mud.dev/quickstart) to get it installed.

# Getting started

### Clone this repository
#### Via GitHub
Use this template to create a new repository or clone this repository locally.
```sh
git clone https://github.com/themetacat/pixelaw_app_template_mud.git
```

### Install packages
```
cd pixelaw_app_template_mud/contracts/ && pnpm install
```

### Build this code
```
pnpm mud build
```

### Runing Core
**Before running this project, make sure to run the [Pixelaw/core](https://github.com/themetacat/pixelaw_core.git) repository.**

### Deploy/Update your App:
```
pnpm run deploy
```

# Advanced
### Local Development
#### Important Note:
After which, you can start deploying your app onto your local PixeLAW via:

Please note the following important details:

1. Ensure that the value of SYSTEM_FILE_NAME in the .env matches the system file name under the ./src/systems/ directory.For example:
```
system file: ./src/systems/MyAppSystem.sol
./env: SYSTEM_FILE_NAME=MyAppSystem
```
2. Ensure that the prefix of the extension file name in the `./script` directory matches the system name. For example:
```
system name: MyAppSystem.sol
extension name MyAppExtension.s.sol
```

#### Building your contracts:
```
pnpm mud build
```

#### Deploy/Update your App:
###### If the app contract is deployed for the first time: 
```
pnpm run deploy
```

###### If you want to update a deployed app：
First comment out the registerNamespace and registerFunctionSelector parts in ./script/MyAppExtension.s.sol:
```
// world.registerNamespace(namespaceResource);

// world.registerFunctionSelector(systemResource, "init()");
// world.registerFunctionSelector(systemResource, "interact((address,string,(uint32,uint32),string))");
```
then:
```
pnpm run deploy INIT=false
```

#### Upload your ABI JSON:
```
pnpm run upload
```

### Deploying to Demo

#### Building your contracts:
```
pnpm mud build
```

#### Deploy/Update your App:
###### If the app contract is deployed for the first time: 
```
pnpm run deploy RPC_URL=<replace-this-with-provided-rpc-url> CHAIN_ID=<replace-this-with-chain-id>
```

###### If you want to update a deployed app：
First comment out the registerNamespace and registerFunctionSelector parts in ./script/MyAppExtension.s.sol:
```
// world.registerNamespace(namespaceResource);

// world.registerFunctionSelector(systemResource, "init()");
// world.registerFunctionSelector(systemResource, "interact((address,string,(uint32,uint32),string))");
```
then:
```
pnpm run deploy INIT=false RPC_URL=<replace-this-with-provided-rpc-url> CHAIN_ID=<replace-this-with-chain-id>
```

#### Upload your ABI JSON:
```
pnpm run upload
```

## Command
### pnpm run deploy
###### if you set RPC_URL, you should set CHAIN_ID
```
pnpm run deploy
    INIT if INIT=false,update the system, default true
    RPC_URL, default http://127.0.0.1:8545
    CHAIN_ID, default 31337
```
