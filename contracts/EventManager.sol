// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventManager {

    // Data structures 

    struct Event {
        uint256 eventId;
        string  name;
        address organizer;
        uint256 ticketSupply;
        uint256 ticketsIssued;
        uint256 ticketPrice;    // in wei
        uint256 maxResalePrice; // price cap for resales, in wei
        bool    isActive;
    }

    // State variables 

    uint256 private eventCounter;
    mapping(uint256 => Event) private events;

    // Events (blockchain logs) 

    event EventCreated(
        uint256 indexed eventId,
        string  name,
        address indexed organizer,
        uint256 ticketSupply,
        uint256 ticketPrice,
        uint256 maxResalePrice
    );

    event EventDeactivated(uint256 indexed eventId);

    // Modifiers 

    modifier onlyOrganizer(uint256 eventId) {
        require(
            events[eventId].organizer == msg.sender,
            "Not the event organizer"
        );
        _;
    }

    modifier eventExists(uint256 eventId) {
        require(
            events[eventId].organizer != address(0),
            "Event does not exist"
        );
        _;
    }

    // Functions 

    /**
     * Called by organizer to create a new event.
     * Returns the new eventId so other contracts can reference it.
     */
    function createEvent(
        string  memory name,
        uint256 ticketSupply,
        uint256 ticketPrice,
        uint256 maxResalePrice
    ) external returns (uint256) {
        require(ticketSupply > 0,       "Supply must be > 0");
        require(ticketPrice > 0,        "Price must be > 0");
        require(maxResalePrice >= ticketPrice, "Resale cap below face value");

        eventCounter++;
        uint256 newId = eventCounter;

        events[newId] = Event({
            eventId:        newId,
            name:           name,
            organizer:      msg.sender,
            ticketSupply:   ticketSupply,
            ticketsIssued:  0,
            ticketPrice:    ticketPrice,
            maxResalePrice: maxResalePrice,
            isActive:       true
        });

        emit EventCreated(newId, name, msg.sender, ticketSupply, ticketPrice, maxResalePrice);
        return newId;
    }

    /**
     * Called by TicketToken when a ticket is minted,
     * to increment the issued count and check supply.
     */
    function recordTicketIssued(uint256 eventId)
        external
        eventExists(eventId)
    {
        Event storage e = events[eventId];
        require(e.isActive, "Event is not active");
        require(e.ticketsIssued < e.ticketSupply, "Sold out");
        e.ticketsIssued++;
    }

    /**
     * Organizer can deactivate an event (no more ticket sales).
     */
    function deactivateEvent(uint256 eventId)
        external
        onlyOrganizer(eventId)
        eventExists(eventId)
    {
        events[eventId].isActive = false;
        emit EventDeactivated(eventId);
    }

    // View functions (reakd only)

    function getEvent(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (Event memory)
    {
        return events[eventId];
    }

    function getResaleCap(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (uint256)
    {
        return events[eventId].maxResalePrice;
    }

    function getTicketPrice(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (uint256)
    {
        return events[eventId].ticketPrice;
    }

    function isEventActive(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (bool)
    {
        return events[eventId].isActive;
    }

    function getOrganizer(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (address)
    {
        return events[eventId].organizer;
    }
}