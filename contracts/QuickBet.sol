// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * QuickBet - an on-chain betting contract that uses attestations and a modified version of snowball consensus 
 * Authors - Ishan Dhanani and Ian Beckett
 */

contract QuickBet{
    
    // only binary bets allowed
    // the description should clearly specify what each choice corresponds to
    // using an enum instead of a binary choice allows us to scale in the future
    // accepts 0 for Choice1 and 1 for Choice2...probably change 
    enum CHOICE {
        Choice1,
        Choice2
    }
    
    //restructure the attestation variables to make this cleaner
    struct Bet {
        uint256 betID;
        string description;
        address[] players;
        mapping(address => CHOICE) playerChoices;
        mapping(address => uint256) playerBets;
        mapping(address => CHOICE) playerAttestations;
        uint8 attestationCount;
        bool payoutReady;
        bool betComplete;
        CHOICE winningBet;
        uint256 betExpiry;
    }

    event BetCreated(uint256 _betID, string _description);
    event BetStarted(uint256 _betID, string _description, address[] players);
    event BetComplete(uint256 _betID, string _description, CHOICE _winner);

    mapping(uint256 => Bet) public allBets;
    uint256 public betNum;

    /**
     * @dev the first player opens a bet, places a bet, and sets the critera
     * @dev in the frontend, ensure players know to indicate which choice is which in the description
     * @param _description the description of the bet that clearly indicates which choice is which 
     * @param _choice the initiating player's choice
     * @param _wager the initiating player's wager
     */
    function createBet(string calldata _description, CHOICE _choice, uint256 _wager) public payable {
        require(uint(_choice) == 1 || uint(_choice) == 0, "You must chose 0 for Choice1 or 1 for Choice2");
        betNum++;
        allBets[betNum].betID = betNum;
        allBets[betNum].description = _description;
        allBets[betNum].players.push(msg.sender);
        allBets[betNum].playerChoices[msg.sender] = _choice;
        allBets[betNum].playerBets[msg.sender] = _wager;
        //set expiry
        emit BetCreated(betNum, _description);
    }

    /**
     * @dev function for players to join the bet
     * @param _betID the ID of the bet 
     * @param _choice the player's choice
     * @param _wager the player's wager
     */
    function joinBet(uint256 _betID, CHOICE _choice, uint256 _wager) public payable {
        Bet storage bet = allBets[_betID];
        bet.players.push(msg.sender);
        bet.playerChoices[msg.sender] = _choice;
        bet.playerBets[msg.sender] = _wager;
        emit BetStarted(_betID, bet.description, bet.players);
    }

    //turn this into a modifier
    /**
     * @dev checks that atleast 1 person must be on the opposite side
     * this can be turned into a modifer in the future 
     */
    function opposingBets(uint256 _betID) public view returns (bool) {
        Bet storage bet = allBets[_betID];
        for(uint256 i = 1; i < bet.players.length; ++i){
            if (bet.playerChoices[bet.players[i]] != bet.playerChoices[bet.players[0]]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev every participant needs to confirm the same outcome
     * @dev a rough attempt at continous sampling until consensus is reached
     * Anyone call call this function and attest their choice
     */
    function determineOutcome(uint256 _betID, CHOICE _attestation) public {
        Bet storage bet = allBets[_betID];
        
        //ensure that opposing bets exist
        require(opposingBets(_betID), "At least 2 people need to be on opposing sides");

        //make sure that the bet is not complete
        require(!bet.betComplete, "Bet is already completed");
        
        //make sure current time is after bet expiry
        require(block.timestamp >= bet.betExpiry, "Outcome cannot be determined. Bet has not expired");

        //save attestation and increment counter
        bet.playerAttestations[msg.sender] = _attestation;
        ++bet.attestationCount;
        uint8 minAttestations = 4; //this is a placeholder for now

        //make sure minimum number of people have called the function to start the snowball
        if (bet.attestationCount < minAttestations) { 
            revert("More attestations are required for random sampling");
        }

        //implementing a rough version of snowball consensus
        //  Randomly sample a minimum group of voters 
        //  Get their majority vote 
        //  Loop for X rounds (X is TBD)
        //  When the majority matches for Y (TBD) rounds, declare the winning choice 
        //  Potentially add an appeal function?

        uint8 round = 0;
        uint8 maxRounds = 3;
        uint8[2] memory votes; //static size array for votes --> index 0 is for the vote=0 and index 1 is for vote=2
        uint8 sampleSize = 2; //this needs to be calculated --> should this be minAttestations/2
        
        // reset vote counters to 0 to remove data from previous rounds if consensus was not reached 
        // is this optimal to happen here?
        votes[0] = 0;
        votes[1] = 0;
        
        while (round < maxRounds) {
            //take a random sample - this lets us scale if there are a lot of betters
            address[] memory sampledPlayers = new address[](sampleSize);
            for (uint256 i = 0; i < sampleSize; ++i) {
                uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % bet.players.length; //logic for randomness
                address player = bet.players[j];
                sampledPlayers[i] = player;
                if (bet.playerAttestations[player] == CHOICE.Choice1){ //might have to wrap the CHOICE.Choice1 in a uint()
                    votes[0]++;
                }
                else {
                    votes[1]++;
                }
            }
            //check consensus
            //this logic needs to be fixed//
            if (votes[0] > sampleSize / 2 || votes[1] > sampleSize / 2) {
                bet.betComplete = true;
                if (votes[0] > votes[1]){
                    bet.winningBet = CHOICE.Choice1;
                }
                else {
                    bet.winningBet = CHOICE.Choice2;
                }
                return;
            }

            //this then needs to hold the result of every single round
            // if its the same for Y times --> then we exit out and declare a final value
        }


        //if consensus was not reached
        ++round;
        //remove all the attestations to reset 
        revert("Consensus was not reached. Reverting the process. Please attest again");
    }

    /**
     * @dev logic to calculate payouts for winners
     * @dev winners must approve to receive their funds 
     */
    function payOut(uint256 _betID) public {
        //require(allBets[_betID].payoutReady, "payout not ready");
        //require(allBets[_betID].winningBet == playerChoices[msg.sender],  "only winners get paid");
        /* pay the man */
    }
}
