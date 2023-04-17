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
        mapping(address => bool) playerChoice;
        mapping(address => uint256) playerBets;
        bool betComplete;
        bool winningChoice;
        uint256 betExpiry;
    }

    event BetPlaced(uint256 _betID, string _description, address[] players);
    event BetComplete(uint256 _betID, string _description, bool _winningChoice);

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
        allBets[betNum].playerChoice[msg.sender] = _choice;
        allBets[betNum].playerBets[msg.sender] = _wager;
    }

    /**
     * @dev function for players to join the bet 
     */
    function joinBet(uint256 _betID, bool _choice, uint256 _wager) public payable {
        Bet storage bet = allBets[_betID];
        bet.players.push(msg.sender);
        bet.playerChoice[msg.sender] = _choice;
        bet.playerBets[msg.sender] = _wager;
    }

    /**
     * @dev start the bet. atleast 1 person must be on the opposite side
     */
    function opposingBets(uint256 _betID) public view returns (bool) {
        Bet storage bet = allBets[_betID];
        for(uint256 i = 1; i < bet.players.length; ++i){
            if (bet.playerChoice[bet.players[0]] != bet.playerChoice[bet.players[i]]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev every participant needs to sign/confirm the correct outcome
     */
    function determineOutcome(uint256 _betID) public view {
        require(opposingBets(_betID), "Atleast 2 people need to be on opposing sides");
        //mapping that holds everyones "signed" value of True or False
        //check that every value in the mapping is the same or throw 
        //if entire address[] has the same value then payout is enabled based on playerChoice
    }

    /**
     * @dev logic to calculate payouts for winners
     * @dev winners must approve to receive their funds 
     */
    function payOut() public {
        ///
    }


}