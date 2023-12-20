## Contracts

The source code for each contract is in the [`contracts/`](contracts/)
directory.

## Contracts

| Contract                                                                      | Description                                                      | Deployment                                                                                  |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [AVSReservesManagerFactory](contracts/src/core/AVSReservesManagerFactory.sol) | Factory for deploying AVSReservesManager contracts               | [0xa...Db7](https://goerli.etherscan.io/address/0xaFb50639327025951a7e995ee0827e52cDfAEDb7) |
| [AVSReservesManager](contracts/src/core/AVSReservesManager.sol)               | Coordinates payment emmissions from the AVS to the AVS operators | [0xa...Db7](https://goerli.etherscan.io/address/0xaFb50639327025951a7e995ee0827e52cDfAEDb7) |
| [SafetyFactorOracle](contracts/src/core/SafetyFactorOracle.sol)               | Provides a safety factor feed for the given AVS                  | [0xf...8C1](https://goerli.etherscan.io/address0xfa8995b2Bc50a6fe692Fe866286f4a24ab2aA8C1)  |
| [MockPaymentManager](contracts/test/mocks/MockPaymentManager.sol)             | Mock eigenlayer payment manager for testing purposes             | [0xa...a2f](https://goerli.etherscan.io/0xad284F2CBe5D9b0fa85B6c4EE26FCcdB3739Ba2f)         |
| [MockAVS](contracts/test/mocks/MockAVS.sol)                                   | Mock AVS for testing purposes                                    |

## Payment Flow

```mermaid
graph TD;
AVS-->|Emmisions Schedule| Reserves;
Reserves-->|Payout| EigenlayerPaymentsManager;
EigenlayerPaymentsManager-->|Claimable Tokens|Operators;

Anzen-.->|Consensus adjustment on rate of payments|Reserves

```

## Usage

```shell
$ cd contracts
```

### Build

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
forge script script/Deploy.s.sol:Deploy --rpc-url "https:ethereum-goerli.publicnode.com" --broadcast --verify -vvvv
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
