// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/interfaces/ITicketNFT.sol";

contract TestTicketNFT is Test {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function testCreator() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        assertEq(ticketNFT.creator(), charlie);
    }

    function testMaxTickets() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        assertEq(ticketNFT.maxNumberOfTickets(), 100);
    }

    function testEventName() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        assertEq(ticketNFT.eventName(), "Charlie's concert");
    }

    function testMint_CallerNotPrimaryMarket() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.prank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        vm.expectRevert(bytes("The caller must be the primary market"));
        vm.prank(alice);
        ticketNFT.mint(msg.sender, "Alice");
    }

    function testMint_ExceedMaxSupply() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 1;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");

        vm.expectRevert(bytes("Exceeds maximum number of tickets that can be minted"));
        ticketNFT.mint(bob, "Bob");
        vm.stopPrank();
    }

    function testBalanceOf() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        assertEq(ticketNFT.balanceOf(alice), 0);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        vm.stopPrank();
    }

    function testHolderOf() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        vm.stopPrank();
    }

    function testTransferFrom_CallerIsOwner() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();

        vm.startPrank(alice);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.holderOf(1), bob);
        vm.stopPrank();
    }

    function testTransferFrom_CallerIsNotOwnerButApproved() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();

        vm.prank(alice);
        ticketNFT.approve(charlie, 1);

        vm.prank(charlie);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.holderOf(1), bob);
    }

    function testApprove() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();

        vm.prank(alice);
        ticketNFT.approve(charlie, 1);

        assertEq(ticketNFT.getApproved(1), charlie);
    }

    function testApprove_CallerMustOwnTicket() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        vm.expectRevert(bytes("The caller must own the ticket"));
        ticketNFT.approve(charlie, 1);
        vm.stopPrank();
    }

    function testHolderNameOf() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.holderNameOf(1), "Alice");
        vm.stopPrank();
    }

    function testUpdateHolderName() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();

        vm.prank(alice);
        ticketNFT.updateHolderName(1, "Bob");

        assertEq(ticketNFT.holderNameOf(1), "Bob");
    }

    function testSetUsed() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        vm.stopPrank();
    }

    function testIsExpiredOrUsed() external {
        uint256 ticketPrice = 20e18;
        uint256 maxNumberOfTickets = 100;

        vm.startPrank(charlie);

        ITicketNFT ticketNFT = new TicketNFT(
            "Charlie's concert",
            maxNumberOfTickets,
            ticketPrice,
            charlie
        );

        ticketNFT.mint(alice, "Alice");

        assertEq(ticketNFT.isExpiredOrUsed(1), false);
        vm.stopPrank();
    }
}