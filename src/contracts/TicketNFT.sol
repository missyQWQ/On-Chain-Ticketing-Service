// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    string private _eventName;
    address private _creator;
    uint256 private _maxNumberOfTickets;
    uint256 private _totalSupply;
    uint256 private _ticketPrice;
    address private _primaryMarket;

    struct Ticket {
        uint256 id;
        string holderName;
        uint256 expiryDate;
        bool isUsed;
    }

    mapping(uint256 => Ticket) private _tickets;
    mapping(uint256 => address) private _ticketHolders;
    mapping(address => uint256) private _balance;
    mapping(uint256 => address) private _ticketApprovals;

    modifier onlyPrimaryMarket() {
        require(msg.sender == _primaryMarket, "The caller must be the primary market");
        _;
    }

    constructor(
        string memory curEventName,
        uint256 curMaxNumberOfTickets,
        uint256 curTicketPrice,
        address eventCreator
    ) {
        _eventName = curEventName;
        _maxNumberOfTickets = curMaxNumberOfTickets;
        _creator = eventCreator;
        _primaryMarket = msg.sender;
        _totalSupply = 0;
        _ticketPrice = curTicketPrice;
    }

    /**
     * @dev Returns the address of the user who created the NFT collection
     * This is the address of the user who called `createNewEvent` in the primary market
     */
    function creator() public view override returns (address) {
        return _creator;
    }

    /**
     * @dev Returns the maximum number of tickets that can be minted for this event.
     */
    function maxNumberOfTickets() public view override returns (uint256) {
        return _maxNumberOfTickets;
    }

    /**
     * @dev Returns the name of the event for this TicketNFT
     */
    function eventName() public view override returns (string memory) {
        return _eventName;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function ticketPrice() public view returns (uint256) {
        return _ticketPrice;
    }

    /**
     * Mints a new ticket for `holder` with `holderName`.
     * The ticket must be assigned the following metadata:
     * - A unique ticket ID. Once a ticket has been used or expired, its ID should not be reallocated
     * - An expiry time of 10 days from the time of minting
     * - A boolean `used` flag set to false
     * On minting, a `Transfer` event should be emitted with `from` set to the zero address.
     *
     * Requirements:
     *
     * - The caller must be the primary market
     */
    function mint(address holder, string memory holderName) public override onlyPrimaryMarket returns (uint256) {
        require(_totalSupply < _maxNumberOfTickets, "Exceeds maximum number of tickets that can be minted");
        _totalSupply++;
        uint256 ticketId = _totalSupply;
        _tickets[ticketId] = Ticket(ticketId, holderName, block.timestamp + 10 days, false);
        _ticketHolders[ticketId] = holder;
        _balance[holder]++;
        emit Transfer(address(0), holder, ticketId);
        return ticketId;
    }

    /**
     * @dev Returns the number of tickets a `holder` has.
     */
    function balanceOf(address holder) public view override returns (uint256) {
        return _balance[holder];
    }

    /**
     * @dev Returns the address of the holder of the `ticketID` ticket.
     *
     * Requirements:
     *
     * - `ticketID` must exist.
     */
    function holderOf(uint256 ticketID) public view override returns (address) {
        address holder = _ticketHolders[ticketID];
        require(holder != address(0), "`ticketID` does not exist");
        return holder;
    }

    /**
     * @dev Transfers `ticketID` ticket from `from` to `to`.
     * This should also set the approved address for this ticket to the zero address
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - the caller must either:
     *   - own `ticketID`
     *   - be approved to move this ticket using `approve`
     *
     * Emits a `Transfer` and an `Approval` event.
     */
    function transferFrom(address from, address to, uint256 ticketID) public override {
        require(from != address(0), "`from` cannot be the zero address.");
        require(to != address(0), "`to` cannot be the zero address.");
        
        address holder = holderOf(ticketID);
        address approved = _ticketApprovals[ticketID];
        require(
            msg.sender == holder || msg.sender == approved,
            "Caller must own `ticketID` or be approved to move this ticket using `approve`"
        );

        _ticketApprovals[ticketID] = address(0);
        emit Approval(holder, address(0), ticketID);

        _balance[from]--;
        _balance[to]++;
        _ticketHolders[ticketID] = to;
        emit Transfer(from, to, ticketID);
    }

    /**
     * @dev Gives permission to `to` to transfer `ticketID` ticket to another account.
     * The approval is cleared when the ticket is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the ticket
     * - `ticketID` must exist.
     *
     * Emits an `Approval` event.
     */
    function approve(address to, uint256 ticketID) public override {
        address holder = holderOf(ticketID);
        require(msg.sender == holder, "The caller must own the ticket");
        _ticketApprovals[ticketID] = to;
        emit Approval(holder, to, ticketID);
    }

    /**
     * @dev Returns the account approved for `ticketID` ticket.
     *
     * Requirements:
     *
     * - `ticketID` must exist.
     */
    function getApproved(uint256 ticketID) public view override returns (address) {
        require(_ticketHolders[ticketID] != address(0), "`ticketID` does not exist");
        return _ticketApprovals[ticketID];
    }

    /**
     * @dev Returns the current `holderName` associated with a `ticketID`.
     * Requirements:
     *
     * - `ticketID` must exist.
     */
    function holderNameOf(uint256 ticketID) public view override returns (string memory) {
        require(_ticketHolders[ticketID] != address(0), "`ticketID` does not exist");
        return _tickets[ticketID].holderName;
    }

    /**
     * @dev Updates the `holderName` associated with a `ticketID`.
     * Note that this does not update the actual holder of the ticket.
     *
     * Requirements:
     *
     * - `ticketID` must exists
     * - Only the current holder can call this function
     */
    function updateHolderName(uint256 ticketID, string calldata newName) external override {
        require(_ticketHolders[ticketID] != address(0), "`ticketID` does not exist");
        require(_ticketHolders[ticketID] == msg.sender, "Only the current holder can call this function");
        _tickets[ticketID].holderName = newName;
    }

    /**
     * @dev Sets the `used` flag associated with a `ticketID` to `true`
     *
     * Requirements:
     *
     * - `ticketID` must exist
     * - the ticket must not already be used
     * - the ticket must not be expired
     * - Only the creator of the collection can call this function
     */
    function setUsed(uint256 ticketID) external override {
        require(_ticketHolders[ticketID] != address(0), "`ticketID` does not exist");
        require(msg.sender == _creator, "Only the creator of the collection can call this function");
        
        Ticket storage ticket = _tickets[ticketID];
        require(!ticket.isUsed, "The ticket must not already be used");
        require(block.timestamp <= ticket.expiryDate, "The ticket must not be expired");
        ticket.isUsed = true;
    }

    /**
     * @dev Returns `true` if the `used` flag associated with a `ticketID` if `true`
     * or if the ticket has expired, i.e., the current time is greater than the ticket's
     * `expiryDate`.
     * Requirements:
     *
     * - `ticketID` must exist
     */
    function isExpiredOrUsed(uint256 ticketID) external view override returns (bool) {
        require(_ticketHolders[ticketID] != address(0), "`ticketID` does not exist");
        Ticket memory ticket = _tickets[ticketID];
        
        bool isTicketExpired = block.timestamp > ticket.expiryDate;
        bool isTicketUsed = ticket.isUsed;
        return isTicketExpired || isTicketUsed;
    }
}