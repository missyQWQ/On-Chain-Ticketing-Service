# On-Chain Ticketing Service
An on-chain ticketing service that features three core components:
1. a non-fungible token (NFT) contract for implementing ticket logic,
2. a primary marketplace that allows users to create tickets (by deploying new instances of an NFT contract) and mint these tickets in exchange for an ERC20 token payment,
3. a secondary marketplace that allows users to create bids for tickets listed for sale by current ticket holders.
## Introduction
It's a university project from Imperial College London 2023/24 70017 Principles of Distributed Ledgers. 

This on-chain ticketing service was modified based on a code skeleton available at https://gitlab.doc.ic.ac.uk/podl/2023/coursework-fall-skeleton
- Supervisor: Lewis Gudgeon, Daniel Perez, Paul Pritz, Sam Werner
- Author of the 6 newly added files: [Yichun Zhang](https://github.com/missyQWQ)

## Coursework skeleton
This is the skeleton for the coursework of the Principle of Distributed Ledgers 2023.
It contains [the interfaces](./src/interfaces) of the contracts to implement and an [ERC20 implementation](./src/contracts/PurchaseToken.sol).

The repository uses [Foundry](https://book.getfoundry.sh/projects/working-on-an-existing-project).

## Structure
The following are the newly added files based on the provided skeleton, including:
- 3 new contracts - TicketNFT.sol, PrimaryMarket.sol, SecondaryMarket.sol
- 3 new test scripts - TicketNFT.t.sol, PrimaryMarket.t.sol, SecondaryMarket.t.sol
```bash
.
├── src
│   ├── contracts
│   │   ├── TicketNFT.sol
│   │   ├── PrimaryMarket.sol
│   │   ├── SecondaryMarket.sol
│   │   ├── ...
│   ├── ...
├── test
│   ├── TicketNFT.t.sol
│   ├── PrimaryMarket.t.sol
│   ├── SecondaryMarket.t.sol
│   ├── ...
├── ...
```
## Running instruction
In the coursework-fall-skeleton folder, run the following in the terminal: 
```bash
forge build
forge test
```
