// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ISecondaryMarket.sol";
import "../contracts/TicketNFT.sol";
import "../contracts/PurchaseToken.sol";

/**
 * The secondary market is the point of sale for tickets after they have been initially purchased from the primary market
 */
contract SecondaryMarket is ISecondaryMarket {
    PurchaseToken private _purchaseToken;
    uint256 public constant FEE_PERCENTAGE = 5;

    struct Bid {
        address bidder;
        uint256 amount;
        string newName;
    }

    struct ListingStruct {
        address lister;
        uint256 price;
        bool isListed;
    }

    mapping(address => mapping(uint256 => ListingStruct)) public listings;
    mapping(address => mapping(uint256 => Bid)) public highestBids;

    constructor(PurchaseToken purchaseToken) {
        _purchaseToken = purchaseToken;
    }

    /**
     * @dev This method lists a ticket with `ticketID` for sale by transferring the ticket
     * such that it is held by this contract. Only the current owner of a specific
     * ticket is able to list that ticket on the secondary market. The purchase
     * `price` is specified in an amount of `PurchaseToken`.
     * Note: Only non-expired and unused tickets can be listed
     */
    function listTicket(address ticketCollection, uint256 ticketID, uint256 price) external override {
        TicketNFT ticketNFT = TicketNFT(ticketCollection);
        require(ticketNFT.holderOf(ticketID) == msg.sender, "Caller doesnot hold the ticket");
        require(!ticketNFT.isExpiredOrUsed(ticketID), "Ticket is expired or used");
        
        listings[ticketCollection][ticketID] = ListingStruct(msg.sender, price, true);
        highestBids[ticketCollection][ticketID] = Bid(address(0), price, "");
        ticketNFT.transferFrom(msg.sender, address(this), ticketID);
        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }

    /**
     * @notice This method allows the msg.sender to submit a bid for the ticket from `ticketCollection` with `ticketID`
     * The `bidAmount` should be kept in escrow by the contract until the bid is accepted, a higher bid is made,
     * or the ticket is delisted.
     * If this is not the first bid for this ticket, `bidAmount` must be strictly higher that the previous bid.
     * `name` gives the new name that should be stated on the ticket when it is purchased.
     * Note: Bid can only be made on non-expired and unused tickets
     */
    function submitBid(address ticketCollection, uint256 ticketID, uint256 bidAmount, string calldata name)
        external
        override
    {
        require(listings[ticketCollection][ticketID].isListed, "Ticket not listed");
        TicketNFT ticketNFT = TicketNFT(ticketCollection);
        require(!ticketNFT.isExpiredOrUsed(ticketID), "Ticket is expired or used");

        Bid storage currentBid = highestBids[ticketCollection][ticketID];
        require(bidAmount > currentBid.amount, "Bid must be higher than current highest");
        require(bidAmount <= _purchaseToken.allowance((msg.sender), address(this)), "Insufficient token allowance");

        _purchaseToken.transferFrom(msg.sender, address(this), bidAmount);
        if (currentBid.bidder != address(0)) {
            _purchaseToken.transfer(currentBid.bidder, currentBid.amount);
        }

        highestBids[ticketCollection][ticketID] = Bid(msg.sender, bidAmount, name);
        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }

    /**
     * Returns the current highest bid for the ticket from `ticketCollection` with `ticketID`
     */
    function getHighestBid(address ticketCollection, uint256 ticketId) external view override returns (uint256) {
        return highestBids[ticketCollection][ticketId].amount;
    }

    /**
     * Returns the current highest bidder for the ticket from `ticketCollection` with `ticketID`
     */
    function getHighestBidder(address ticketCollection, uint256 ticketId) external view override returns (address) {
        return highestBids[ticketCollection][ticketId].bidder;
    }

    /*
     * @notice Allow the lister of the ticket from `ticketCollection` with `ticketID` to accept the current highest bid.
     * This function reverts if there is currently no bid.
     * Otherwise, it should accept the highest bid, transfer the money to the lister of the ticket,
     * and transfer the ticket to the highest bidder after having set the ticket holder name appropriately.
     * A fee charged when the bid is accepted. The fee is charged on the bid amount.
     * The final amount that the lister of the ticket receives is the price
     * minus the fee. The fee should go to the creator of the `ticketCollection`.
     */
    function acceptBid(address ticketCollection, uint256 ticketID) external override {
        ListingStruct storage listing = listings[ticketCollection][ticketID];
        require(listing.isListed, "This ticket is not listed.");
        require(listing.lister == msg.sender, "Only the lister can accept bid.");

        Bid storage highestBid = highestBids[ticketCollection][ticketID];
        require(highestBid.bidder != address(0), "No bid available currently.");

        uint256 fee = highestBid.amount * FEE_PERCENTAGE / 100;
        uint256 finalAmount = highestBid.amount - fee;

        _purchaseToken.transfer(listing.lister, finalAmount);
        TicketNFT ticketNFT = TicketNFT(ticketCollection);
        require(!ticketNFT.isExpiredOrUsed(ticketID), "Ticket is expired or used");

        _purchaseToken.transfer(ticketNFT.creator(), fee);
        ticketNFT.updateHolderName(ticketID, highestBid.newName);
        ticketNFT.transferFrom(address(this), highestBid.bidder, ticketID);
        listing.isListed = false;
        emit BidAccepted(highestBid.bidder, ticketCollection, ticketID, highestBid.amount, highestBid.newName);
    }

    /**
     * @notice This method delists a previously listed ticket of `ticketCollection` with `ticketID`. Only the account that
     * listed the ticket may delist the ticket. The ticket should be transferred back
     * to msg.sender, i.e., the lister, and escrowed bid funds should be return to the bidder, if any.
     */
    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        ListingStruct storage listing = listings[ticketCollection][ticketID];
        require(listing.isListed, "This ticket is not listed yet.");
        require(listing.lister == msg.sender, "Only lister can delist the ticket.");
        TicketNFT(ticketCollection).transferFrom(address(this), msg.sender, ticketID);
        listing.isListed = false;

        Bid storage currentBid = highestBids[ticketCollection][ticketID];
        if (currentBid.bidder != address(0)) {
            _purchaseToken.transfer(currentBid.bidder, currentBid.amount);
        }

        emit Delisting(ticketCollection, ticketID);
    }
}