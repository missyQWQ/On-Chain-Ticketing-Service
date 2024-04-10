// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";

contract TestSecondaryMarket is Test {
    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    SecondaryMarket public secondaryMarket;
    ITicketNFT public ticketNFT;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    uint256 ticketPrice;

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);
        ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, maxNumberOfTickets);

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);
    }

    function testListTicket() external {
        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        ticketNFT.approve(address(secondaryMarket), id);
        secondaryMarket.listTicket(address(ticketNFT), id, 150e18);

        assertEq(ticketNFT.holderOf(id), address(secondaryMarket));
        assertEq(secondaryMarket.getHighestBid(address(ticketNFT), id), 150e18);
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT), id), address(0));

        vm.stopPrank();
    }

    function testSubmitBid() external {
        uint256 bidPrice = 155e18;

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        ticketNFT.approve(address(secondaryMarket), id);
        secondaryMarket.listTicket(address(ticketNFT), id, 150e18);

        vm.stopPrank();

        vm.startPrank(bob);
        purchaseToken.mint{value: 2e18}();
        purchaseToken.approve(address(secondaryMarket), bidPrice);
        secondaryMarket.submitBid(address(ticketNFT), id, bidPrice, "Bob");

        assertEq(secondaryMarket.getHighestBid(address(ticketNFT), id), bidPrice);
        assertEq(secondaryMarket.getHighestBidder(address(ticketNFT), id), bob);
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), bidPrice);
        vm.stopPrank();
    }

    function testAcceptBid() external {
        uint256 bidPrice = 155e18;

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        ticketNFT.approve(address(secondaryMarket), id);
        secondaryMarket.listTicket(address(ticketNFT), id, 150e18);
        vm.stopPrank();

        vm.startPrank(bob);
        purchaseToken.mint{value: 2e18}();
        purchaseToken.approve(address(secondaryMarket), bidPrice);
        secondaryMarket.submitBid(address(ticketNFT), id, bidPrice, "Bob");
        vm.stopPrank();

        uint256 aliceBalanceBefore = purchaseToken.balanceOf(alice);

        vm.prank(alice);
        secondaryMarket.acceptBid(address(ticketNFT), id);
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), 0);
        uint256 fee = (bidPrice * 0.05e18) / 1e18;
        assertEq(purchaseToken.balanceOf(charlie), ticketPrice + fee);
        assertEq(purchaseToken.balanceOf(alice), aliceBalanceBefore + bidPrice - fee);
        assertEq(ticketNFT.holderOf(id), bob);
        assertEq(ticketNFT.holderNameOf(id), "Bob");
    }

    function testAcceptBid_NotLister() external {
        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        ticketNFT.approve(address(secondaryMarket), id);
        secondaryMarket.listTicket(address(ticketNFT), id, 150e18);
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert(bytes("Only the lister can accept bid."));
        secondaryMarket.acceptBid(address(ticketNFT), id);
    }

    function testDelistTicket() external {
        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        ticketNFT.approve(address(secondaryMarket), id);
        secondaryMarket.listTicket(address(ticketNFT), id, 150e18);

        assertEq(ticketNFT.holderOf(id), address(secondaryMarket));

        secondaryMarket.delistTicket(address(ticketNFT), id);
        assertEq(ticketNFT.holderOf(id), address(alice));

        vm.stopPrank();
    }
}