# Coursework skeleton

This is the skeleton for the coursework of the Principle of Distributed Ledgers 2023.
It contains [the interfaces](./src/interfaces) of the contracts to implement and an [ERC20 implementation](./src/contracts/PurchaseToken.sol).

The repository uses [Foundry](https://book.getfoundry.sh/projects/working-on-an-existing-project).

# Structure
The following are the new added files based on the provided skeleton, including:
    3 new contracts - TicketNFT.sol, PrimaryMarket.sol, SecondaryMarket.sol
    3 new test scripts - TicketNFT.t.sol, PrimaryMarket.t.sol, SecondaryMarket.t.sol
.
|-- src
|   |-- contracts
|   |   |-- TicketNFT.sol
|   |   |-- PrimaryMarket.sol
|   |   |-- SecondaryMarket.sol
|   |   |-- ...
|   |-- ...
|-- test
|   |-- TicketNFT.t.sol
|   |-- PrimaryMarket.t.sol
|   |-- SecondaryMarket.t.sol
|   |-- ...
|-- ...

# Running instruction
In the coursework-fall-skeleton folder, run the following in the terminal: 
    forge build
    forge test

# Author
Author of the 6 new added files - Yichun Zhang