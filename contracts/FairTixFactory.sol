// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EventManager.sol";
import "./TicketToken.sol";
import "./ResaleController.sol";

contract FairTixFactory {

    // ─── State variables ───────────────────────────────────────────

    address public eventManager;
    address public ticketToken;
    address public resaleController;
    address public owner;
    bool    public deployed;

    // ─── Events ────────────────────────────────────────────────────

    event SystemDeployed(
        address indexed eventManager,
        address indexed ticketToken,
        address indexed resaleController
    );

    // ─── Constructor ───────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─── Modifiers ─────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier notDeployed() {
        require(!deployed, "System already deployed");
        _;
    }

    // Core deploy function 

    /**
     * Call this once after deploying the factory.
     * Deploys all three contracts, wires them together,
     * and locks so it can't be called again.
     */
    function deploy() external onlyOwner notDeployed {

        // 1. Deploy EventManager
        EventManager em = new EventManager();
        eventManager = address(em);

        // 2. Deploy TicketToken, pass EventManager address in
        TicketToken tt = new TicketToken(eventManager);
        ticketToken = address(tt);

        // 3. Deploy ResaleController, pass both addresses in
        ResaleController rc = new ResaleController(
            eventManager,
            ticketToken
        );
        resaleController = address(rc);

        // 4. Wire ResaleController into TicketToken
        //    (gives it permission to transfer tickets)
        tt.setResaleController(resaleController);

        // 5. Lock so deploy() can't be called again
        deployed = true;

        emit SystemDeployed(eventManager, ticketToken, resaleController);
    }

    // Getter 
    /**
     * Returns all three contract addresses in one call.
     * Use this in your front end on page load.
     */
    function getAddresses() external view returns (
        address _eventManager,
        address _ticketToken,
        address _resaleController
    ) {
        require(deployed, "System not deployed yet");
        return (eventManager, ticketToken, resaleController);
    }
}