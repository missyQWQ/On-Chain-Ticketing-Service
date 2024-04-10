// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";

contract TestPrimaryMarket is Test {
    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);
    }

    function testCreateNewEvent() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, maxNumberOfTickets);

        assertEq(ticketNFT.creator(), charlie);
        assertEq(ticketNFT.maxNumberOfTickets(), 100);
        assertEq(ticketNFT.eventName(), "Charlie's concert");
    }

    function testPurchase() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, maxNumberOfTickets);

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(id), alice);
        assertEq(ticketNFT.holderNameOf(id), "Alice");
        assertEq(purchaseToken.balanceOf(alice), 100e18 - ticketPrice);
        assertEq(purchaseToken.balanceOf(charlie), ticketPrice);
        vm.stopPrank();
    }

    function testPurchase_NotEnoughAllowance() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, maxNumberOfTickets);

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);

        vm.expectRevert(bytes("Not enough allowance"));
        primaryMarket.purchase(address(ticketNFT), "Alice");
        vm.stopPrank();
    }

    function testGetPrice() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, maxNumberOfTickets);

        assertEq(primaryMarket.getPrice(address(ticketNFT)), ticketPrice);
    }
}