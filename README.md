# QuickBets

An on-chain betting contract that uses leverages user attestations and a modified version of snowball consensus to determine the outcome of a bet. This is currently in development and is not meant to be used in production. If you have any ideas on how to improve this project or mess with the consensus portion, please reach out to me.

## Overview

QuickBet is an Solidity smart contract that enables users to create and participate in simple binary bets. For example, this application is useful for betting on the winner of the Super Bowl. It is not as useful for over/under or odds-based bets. The contract is designed to ensure that bets must have atleast 1 person on the other side and each bet has a predefined expiry time.

## Consensus (work in progress)

In traditional online betting, there is a central party that decides the winner. This central party is trusted and the decision can be easily verified. Although this is possible on chain via the use of an oracle, I decided to go an alternate route and use player attestations. I loosely based this off of [Snowball Consensus](https://docs.avax.network/overview/getting-started/avalanche-consensus).

On a high level, the process looks like this 
1. When the bet expires, each partipant attests to the winner (either Choice1 or Choice2 as determined in the bet description).
2. The contract then randomly subsamples the attestations and takes a majority vote on the outcome.
3. If the contract reaches Y consective votes that are the same, that choice is declared as the winner.

The mathematics are still a little fuzzy and the paramters for amount of subsamples and consecutive votes are not exact.
