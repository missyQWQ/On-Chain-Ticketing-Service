// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "../contracts/TicketNFT.sol";
import "../contracts/PurchaseToken.sol";

/**
 * The primary market is the first point of sale for tickets.
 * It is responsible for minting tickets and transferring them to the purchaser.
 * The NFT to be minted is an implementation of the ITicketNFT interface and should be created (i.e. deployed)
 * when a new event NFT collection is created
 * In this implementation, the purchase price and the maximum number of tickets
 * is set when an event NFT collection is created
 * The purchase token is an ERC20 token that is specified when the contract is deployed.
 */
contract PrimaryMarket is IPrimaryMarket {
    PurchaseToken private _purchaseToken;

    constructor(PurchaseToken purchaseToken) {
        _purchaseToken = purchaseToken;
    }

    /**
     * @param eventName is the name of the event to create
     * @param price is the price of a single ticket for this event
     * @param maxNumberOfTickets is the maximum number of tickets that can be created for this event
     */
    function createNewEvent(string memory eventName, uint256 price, uint256 maxNumberOfTickets)
        external
        override
        returns (ITicketNFT)
    {
        TicketNFT newTicketNFT = new TicketNFT(eventName, maxNumberOfTickets, price, msg.sender);
        emit EventCreated(msg.sender, address(newTicketNFT), eventName, price, maxNumberOfTickets);
        return newTicketNFT;
    }

    /**
     * @notice Allows a user to purchase a ticket from `ticketCollectionNFT`
     * @dev Takes the initial NFT token holder's name as a string input
     * and transfers ERC20 tokens from the purchaser to the creator of the NFT collection
     * @param ticketCollection the collection from which to buy the ticket
     * @param holderName the name of the buyer
     * @return id of the purchased ticket
     */
    function purchase(address ticketCollection, string memory holderName) external override returns (uint256 id) {
        TicketNFT ticketNFT = TicketNFT(ticketCollection);

        uint256 allowance = _purchaseToken.allowance(msg.sender, address(this));
        uint256 price = ticketNFT.ticketPrice();
        require(allowance >= price, "Not enough allowance");

        _purchaseToken.transferFrom(msg.sender, ticketNFT.creator(), price);
        id = ticketNFT.mint(msg.sender, holderName);
        emit Purchase(msg.sender, ticketCollection, id, holderName);
    }

    /**
     * @param ticketCollection the collection from which to get the price
     * @return price of a ticket for the event associated with `ticketCollection`
     */
    function getPrice(address ticketCollection) external view override returns (uint256) {
        TicketNFT ticketNFT = TicketNFT(ticketCollection);
        return ticketNFT.ticketPrice();
    }
}