// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EventManager.sol";

contract TicketToken {


    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address owner;
        bool    isUsed;
        bool    isValid;
    }

    // State variables 

    uint256 private ticketCounter;

    mapping(uint256 => Ticket)  private tickets;
    mapping(address => uint256[]) private ownerTickets; // all tickets held by an address

    address private eventManagerAddress;
    address private resaleControllerAddress; // set after ResaleController is deployed

    EventManager private eventManager;

    // Events

    event TicketMinted(
        uint256 indexed ticketId,
        uint256 indexed eventId,
        address indexed owner
    );

    event TicketTransferred(
        uint256 indexed ticketId,
        address indexed from,
        address indexed to
    );

    event TicketUsed(uint256 indexed ticketId, address indexed owner);

    // Modifiers

    modifier onlyResaleController() {
        require(
            msg.sender == resaleControllerAddress,
            "Only ResaleController can call this"
        );
        _;
    }

    modifier ticketExists(uint256 ticketId) {
        require(tickets[ticketId].isValid, "Ticket does not exist");
        _;
    }

    modifier onlyTicketOwner(uint256 ticketId) {
        require(
            tickets[ticketId].owner == msg.sender,
            "Not the ticket owner"
        );
        _;
    }


    constructor(address _eventManagerAddress) {
        eventManagerAddress = _eventManagerAddress;
        eventManager = EventManager(_eventManagerAddress);
        contractOwner = msg.sender;
    }


    /**
     * Only the deployer's account can call this (simple owner check).
     */
    address private contractOwner;


    function setResaleController(address _resaleController) external {
        require(
            resaleControllerAddress == address(0),
            "ResaleController already set"
        );
        resaleControllerAddress = _resaleController;
    }


    /**
     * Buyer calls this to purchase a ticket directly from organizer.
     * Requires exact payment matching the event's ticket price.
     * Calls back to EventManager to check supply and record issuance.
     */
    function mintTicket(uint256 eventId) external payable returns (uint256) {
        require(
            eventManager.isEventActive(eventId),
            "Event is not active"
        );

        uint256 price = eventManager.getTicketPrice(eventId);
        require(msg.value == price, "Incorrect payment amount");

        // Tell EventManager to record this issuance 
        eventManager.recordTicketIssued(eventId);

        ticketCounter++;
        uint256 newTicketId = ticketCounter;

        tickets[newTicketId] = Ticket({
            ticketId: newTicketId,
            eventId:  eventId,
            owner:    msg.sender,
            isUsed:   false,
            isValid:  true
        });

        ownerTickets[msg.sender].push(newTicketId);

        // Forward payment to event organizer
        address organizer = eventManager.getOrganizer(eventId);
        (bool sent, ) = organizer.call{value: msg.value}("");
        require(sent, "Payment to organizer failed");

        emit TicketMinted(newTicketId, eventId, msg.sender);
        return newTicketId;
    }

    /**
     * Called ONLY by ResaleController after validating price cap.
     * Transfers ownership from seller to buyer.
     */
    function transferTicket(uint256 ticketId, address from, address to)
        external
        onlyResaleController
        ticketExists(ticketId)
    {
        require(!tickets[ticketId].isUsed, "Ticket already used");
        require(tickets[ticketId].owner == from, "Seller does not own ticket");

        tickets[ticketId].owner = to;
        ownerTickets[to].push(ticketId);

        emit TicketTransferred(ticketId, from, to);
    }

    /**
     * Called by venue staff to validate and mark a ticket as used.
     * Once marked used it cannot be transferred or reused.
     */
    function markUsed(uint256 ticketId)
        external
        ticketExists(ticketId)
    {
        require(!tickets[ticketId].isUsed, "Ticket already used");
        tickets[ticketId].isUsed = true;
        emit TicketUsed(ticketId, tickets[ticketId].owner);
    }

    // View functions 

    function getTicket(uint256 ticketId)
        external
        view
        ticketExists(ticketId)
        returns (Ticket memory)
    {
        return tickets[ticketId];
    }

    function getOwner(uint256 ticketId)
        external
        view
        ticketExists(ticketId)
        returns (address)
    {
        return tickets[ticketId].owner;
    }

    function isUsed(uint256 ticketId)
        external
        view
        ticketExists(ticketId)
        returns (bool)
    {
        return tickets[ticketId].isUsed;
    }

    function getTicketsByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerTickets[owner];
    }

    function getEventId(uint256 ticketId)
        external
        view
        ticketExists(ticketId)
        returns (uint256)
    {
        return tickets[ticketId].eventId;
    }
}