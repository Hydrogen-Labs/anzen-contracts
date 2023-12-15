## Contracts

The source code for each contract is in the [`contracts/`](contracts/)
directory.

## Contracts

| Contract                                                                      | Description                                                      |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [AVSReservesManagerFactory](contracts/src/core/AVSReservesManagerFactory.sol) | Factory for deploying AVSReservesManager contracts               |
| [AVSReservesManager](contracts/src/core/AVSReservesManager.sol)               | Coordinates payment emmissions from the AVS to the AVS operators |
| [SafetyFactorOracle](contracts/src/core/SafetyFactorOracle.sol)               | Provides a safety factor feed for the given AVS                  |
| [MockPaymentManager](contracts/test/mocks/MockPaymentManager.sol)             | Mock eigenlayer payment manager for testing purposes             |
| [MockAVS](contracts/test/mocks/MockAVS.sol)                                   | Mock AVS for testing purposes                                    |

## Payment Flow

```mermaid
graph TD;
AVS-->|Emmisions Schedule| Reserves;
Reserves-->|Payout| EigenlayerPaymentsManager;
EigenlayerPaymentsManager-->|Claimable Tokens|Operators;

Anzen-->|Consensus adjustment on rate of payments|Reserves

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
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
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
