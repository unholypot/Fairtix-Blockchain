# FairTix A Blockchain Ticketing System
 
A decentralised event ticketing system built with Solidity for the IFB452 Blockchain Technology unit at QUT. FairTix uses smart contracts to manage ticket issuance, ownership, and resale reducing fraud and scalping by enforcing price caps directly on-chain.
 
## Contracts (so far)
 
### EventManager.sol
Handles event creation and management. Event organisers deploy this first and use it to define ticket supply, pricing, and resale price caps.
 
### TicketToken.solc (NEEDS MORE TESTING)
Handles ticket minting and ownership. Each ticket is a unique on-chain asset tied to an event. Buyers purchase tickets through this contract, which checks back against EventManager to verify event details and record issuance.

### ResaleController.sol ( have not tested)
Regulated resale marketplace enforcing price caps. Sellers list tickets, buyers purchase with ETH, and ownership transfers atomically.


### Deployment & Usage

 **Deploy EventManager** Copy the deployed address
 **Deploy TicketToken**  Copy the deployed address
 **Deploy ResaleController** Copy the deployed address

 Configure TicketToken aka // In Remix, call TicketToken.setResaleController(<ResaleController_address>)

This enables the ResaleController to manage ticket transfers

Testing that i have done so far

Create event → Mint ticket → Verify transfer restrictions
List for resale → Buy resale ticket → Verify new ownership
Attempt overselling → Verify supply enforcement
Attempt price cap violation → Verify resale restriction
Mark ticket used → Verify transfer prevention



## This is how u can use the factory contract to deploy all 3 of them
### Step 1: Deploy the Factory Contract
3. Select "FairTixFactory" from the contract dropdown
4. Click "Deploy" 

### Step 2: Deploy the System
1. After deployment, locate the "deploy" function in the factory contract
2. Click the "deploy" button to deploy all three contracts
3. Wait for the transaction to complete

### Step 3: Get Contract Addresses
1. After deployment completes, call `getAddresses()` function
2. Copy the three returned addresses:
   - EventManager address
   - TicketToken address
   - ResaleController address

### Step 4: Load Contracts in Remix
1. For each contract you want to interact with:
   - Go to "Deploy & Run Transactions" tab
   - Select the contract (EventManager, TicketToken, or ResaleController)
   - Click "At Address" button
   - Paste the corresponding address from Step 3
   - Click "At Address" to load the contract instance
