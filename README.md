# FairTix — Blockchain Ticketing System
 
A decentralised event ticketing system built with Solidity for the IFB452 Blockchain Technology unit at QUT. FairTix uses smart contracts to manage ticket issuance, ownership, and resale — reducing fraud and scalping by enforcing price caps directly on-chain.
 
## Contracts (so far)
 
### EventManager.sol
Handles event creation and management. Event organisers deploy this first and use it to define ticket supply, pricing, and resale price caps.
 
### TicketToken.solc (NEEDS MORE TESTING)
Handles ticket minting and ownership. Each ticket is a unique on-chain asset tied to an event. Buyers purchase tickets through this contract, which checks back against EventManager to verify event details and record issuance.
