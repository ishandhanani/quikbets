// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * QuickBet - a frictionaless betting application
 * Authors - Ishan Dhanani and Ian Beckett
 * Build as the final project for CSCE689
 */

contract QuickBet{
    struct Bet {
        uint256 betID;
        string description;
        address[] players;
        mapping(address => bool) playerChoices;
        mapping(address => uint256) playerBets;
        mapping(address => bool) outcomeReports;
        bool payoutReady;
        bool betComplete;
        uint256 betExpiry;
    }

    event BetPlaced(uint256 _betID, string _description, address[] players);
    event BetComplete(uint256 _betID, string _description);

    mapping(uint256 => Bet) public allBets;
    uint256 public betNum;

    /**
     * @dev the first player opens a bet, places a bet, and sets the critera
     */
    function createBet(string calldata _description, bool _choice, uint256 _wager) public payable {
        betNum++;
        allBets[betNum].betID = betNum;
        allBets[betNum].description = _description;
        allBets[betNum].players.push(msg.sender);
        allBets[betNum].playerChoices[msg.sender] = _choice;
        allBets[betNum].playerBets[msg.sender] = _wager;
    }

    /**
     * @dev function for players to join the bet 
     */
    function joinBet(uint256 _betID, bool _choice, uint256 _wager) public payable {
        Bet storage bet = allBets[_betID];
        bet.players.push(msg.sender);
        bet.playerChoices[msg.sender] = _choice;
        bet.playerBets[msg.sender] = _wager;
    }

    /**
     * @dev start the bet. atleast 1 person must be on the opposite side
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
     */
    function determineOutcome(uint256 _betID) public {
        require(opposingBets(_betID), "At least 2 people need to be on opposing sides");
        //mapping that holds everyones "signed" value of True or False
        //check that every value in the mapping is the same
        Bet storage bet = allBets[_betID];
        for (uint256 i = 1; i < players.length; ++i) {
            require(
                bet.playerChoices[bet.players[i]] == bet.playerChoices[bet.players[0]],
                "some players dispute the outcome"
            );
        }
        //if every player agrees, then payout is enabled based on playerChoices
        bet.payoutReady = true;
    }

    /**
     * @dev logic to calculate payouts for winners
     * @dev winners must approve to receive their funds 
     */
    function payOut(uint256 _betID) public {
        require(allBets[_betID]payoutReady, "payout not ready");
        /* foo */
    }

    function receive() {/* foo */}
    Fallback() {}
}
