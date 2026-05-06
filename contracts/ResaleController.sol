// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "./EventManager.sol";
import "./TicketToken.sol";

contract ResaleController {

    // Data structures

    struct Listing {
        uint256 ticketId;
        address seller;
        uint256 price;
        bool    isActive;
    }

    // State variables

    mapping(uint256 => Listing) private listings; // ticketId => Listing

    EventManager private eventManager;
    TicketToken  private ticketToken;

    // Events

    event TicketListed(
        uint256 indexed ticketId,
        address indexed seller,
        uint256 price
    );

    event TicketResold(
        uint256 indexed ticketId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    event ListingCancelled(uint256 indexed ticketId, address indexed seller);

    // Modifiers 

    modifier listingExists(uint256 ticketId) {
        require(listings[ticketId].isActive, "No active listing for this ticket");
        _;
    }

    modifier onlySeller(uint256 ticketId) {
        require(
            listings[ticketId].seller == msg.sender,
            "Not the seller of this ticket"
        );
        _;
    }

    // Constructor 

    constructor(address _eventManagerAddress, address _ticketTokenAddress) {
        eventManager = EventManager(_eventManagerAddress);
        ticketToken  = TicketToken(_ticketTokenAddress);
    }

    // Core functions 
    /**
     * Ticket owner lists their ticket for resale.
     * Checks price cap from EventManager before allowing the listing.
     * Seller must actually own the ticket.
     */
    function listForResale(uint256 ticketId, uint256 price) external {
        // Verify caller owns the ticket
        require(
            ticketToken.getOwner(ticketId) == msg.sender,
            "You do not own this ticket"
        );

        // Verify ticket hasn't been used
        require(
            !ticketToken.isUsed(ticketId),
            "Ticket has already been used"
        );

        // Verify no existing active listing
        require(
            !listings[ticketId].isActive,
            "Ticket already listed"
        );

        // *** KEY: Check price cap against EventManager ***
        uint256 eventId = ticketToken.getEventId(ticketId);
        uint256 resaleCap = eventManager.getResaleCap(eventId);
        require(
            price <= resaleCap,
            "Price exceeds resale cap set by organizer"
        );

        listings[ticketId] = Listing({
            ticketId: ticketId,
            seller:   msg.sender,
            price:    price,
            isActive: true
        });

        emit TicketListed(ticketId, msg.sender, price);
    }

    /**
     * Buyer purchases a resale ticket.
     * Validates payment, then triggers ownership transfer in TicketToken.
     * Forwards payment to seller automatically.
     */
    function buyResaleTicket(uint256 ticketId)
        external
        payable
        listingExists(ticketId)
    {
        Listing storage listing = listings[ticketId];

        require(
            msg.sender != listing.seller,
            "Cannot buy your own listing"
        );
        require(
            msg.value == listing.price,
            "Incorrect payment amount"
        );

        // Verify ticket still valid and unmodified since listing
        require(
            !ticketToken.isUsed(ticketId),
            "Ticket was used after listing"
        );
        require(
            ticketToken.getOwner(ticketId) == listing.seller,
            "Seller no longer owns this ticket"
        );

        address seller = listing.seller;
        uint256 price  = listing.price;

        // Deactivate listing before transfer (prevents re-entrancy)
        listing.isActive = false;

        // *** ResaleController tells TicketToken to transfer ownership ***
        ticketToken.transferTicket(ticketId, seller, msg.sender);

        // Forward payment to seller
        (bool sent, ) = seller.call{value: msg.value}("");
        require(sent, "Payment to seller failed");

        emit TicketResold(ticketId, seller, msg.sender, price);
    }

    /**
     * Seller cancels their own listing.
     */
    function cancelListing(uint256 ticketId)
        external
        listingExists(ticketId)
        onlySeller(ticketId)
    {
        listings[ticketId].isActive = false;
        emit ListingCancelled(ticketId, msg.sender);
    }

    // View functions

    function getListing(uint256 ticketId)
        external
        view
        returns (Listing memory)
    {
        return listings[ticketId];
    }

    function isListed(uint256 ticketId)
        external
        view
        returns (bool)
    {
        return listings[ticketId].isActive;
    }
}