// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * QuickBet - an on-chain betting contract that uses attestations and a modified version of snowball consensus 
 */

contract QuickBet{
    
    // only binary bets allowed
    // the description should clearly specify what each choice corresponds to
    // using an enum instead of a binary choice allows us to scale in the future
    // accepts 0 for a and 1 for b...probably change 
    enum CHOICE {a,b}
    
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
        bool complete;
        CHOICE winningBet;
        uint256 expiry;
    }

    event created(uint256 _betID, string _description);
    event started(uint256 _betID, string _description, address[] players);
    event complete(uint256 _betID, string _description, CHOICE _winner);

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
        require(uint(_choice) == 1 || uint(_choice) == 0, "You must chose 0 for a or 1 for b");
        betNum++;
        allBets[betNum].betID = betNum;
        allBets[betNum].description = _description;
        allBets[betNum].players.push(msg.sender);
        allBets[betNum].playerChoices[msg.sender] = _choice;
        allBets[betNum].playerBets[msg.sender] = _wager;
        //set expiry
        emit created(betNum, _description);
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
        emit started(_betID, bet.description, bet.players);
    }

    /**
     * @dev checks that atleast 1 person must be on the opposite side
     * @dev this can be turned into a modifer in the future 
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
     * @dev can scale this based on player.length (ex. <5 req total unanimous, >5 req supermajority)
     */
    function determineOutcome(uint256 _betID, CHOICE _attestation) public {
        Bet storage bet = allBets[_betID];
        
        //ensure that opposing bets exist
        require(opposingBets(_betID), "At least 2 people need to be on opposing sides");

        //make sure that the bet is not complete
        require(!bet.complete, "Bet is already completed");
        
        //make sure current time is after bet expiry
        require(block.timestamp >= bet.expiry, "Outcome cannot be determined. Bet has not expired");

        //save attestation and increment counter
        bet.playerAttestations[msg.sender] = _attestation;
        ++bet.attestationCount;
        uint256 minAttestations = bet.players.length - 2; //this is a placeholder for now

        //make sure minimum number of people have called the function to start the snowball
        require(bet.attestationCount >= minAttestations, "More attestations are required for random sampling");

        //implementing a rough/custom version of snowball consensus
        //  Randomly sample a minimum group of voters (size k)
        //  Get their majority vote (either supermajority or a custom quorum: a)
        //  Loop for X rounds (X is TBD) (this is different because we dont repeatedly query. you must reattest if majority is not reached)
        //  When the majority matches for Y (TBD) rounds, declare the winning choice (decision threshold b) 
        //  Potentially add an appeal function?

        uint8 round = 0;
        uint8 maxRounds = 10; // does this need to be dynamic? i dont think so...
        uint8[type(CHOICE).max + 1] memory votes; //static-size array for votes
        uint256 sampleSize = minAttestations / 2; //this might have to be dynamic based on the number of betters
        uint256 consecutiveSuccesses = 0;
        uint256 successThreshold = 6;

        while (round < maxRounds) {
            // reset vote counters to 0 to remove data from previous rounds if consensus was not reached 
            // is this optimal to happen here?
            CHOICE prevChoice;
            CHOICE majority;
            votes[0] = 0; // a
            votes[1] = 0; // b

            //take a random sample - this lets us scale if there are a lot of betters
            address[] memory sampledPlayers = new address[](sampleSize);
            for (uint256 i = 0; i < sampleSize; ++i) {
                uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % bet.players.length; //logic for randomness
                address player = bet.players[j];
                sampledPlayers[i] = player;
                if (bet.playerAttestations[player] == CHOICE.a){
                    votes[0]++;
                }
                else {
                    votes[1]++;
                }
            }

            //check consensus
            // for several choices, we would use votes.max, accounting for
            // the possibility of two maxima.
            majority = (votes[0] > votes[1]) ? CHOICE.a : CHOICE.b ;

            //check consecutive
            if (majority == prevChoice){
                ++consecutiveSuccesses;
            }
            else {
                consecutiveSuccesses = 1;
            }

            //exit out if threshold is hit
            if (consecutiveSuccesses == successThreshold){
                winningBet = majority;
                return;
            }

            //this then needs to hold the result of every single round <- why? aren't we just counting consecutive rounds?
            // if its the same for Y times --> then we exit out and declare a final value
            //if consensus was not reached:
            ++round;
        }
        //remove all the attestations to reset
        revert("Consensus was not reached. Reverting the process. Everyone must attest again");
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
