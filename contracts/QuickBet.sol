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

    Bet[] public bets;

    /**
     * @dev the first player opens a bet, places a bet, and sets the critera
     */
    function createBet() public payable {
        ///
    }

    /**
     * @dev function for players to join the bet 
     */
    function joinBet() public payable {
        ///
    }

    /**
     * @dev start the bet. atleast 1 person must be on the opposite side
     */
    function startBet() public {
        ///
    }

    /**
     * @dev every participant needs to sign/confirm the correct outcome
     */
    function confirmOutcome() public {
        ///
    }

    /**
     * @dev logic to calculate payouts for winners
     * @dev winners must approve to receive their funds 
     */
    function payOut() public {
        ///
    }


}