# WEC_Systems_SIG_Recs2020_Blockchain_Task

## Problem Statement
### The task is to write a smart contract to enable Peer-to-peer betting with the following features :
- Every bet has two parties - a challenger and an acceptor, along with a statement/condition and a deadline, which forms the basis of the bet.
- There is also a third party, the Judge/Referee who is decided mutually by the two participants and is responsible for judging the outcome of the bet.
- There is also a fee for the judge (determined by the creator of the contract - 0 - 100 % of the bet amount).
- The challenger and acceptor must deposit their bets (equal amounts) to enter the bet (The challenger does this during the creation of the contract and the acceptor does this when he/she accepts the bet)
- Everyone should be able to view the details of open bets (that have not been accepted).
- The Ether should be distributed amongst the parties when the deadline is reached.
### Additional Features (Optional) :
- Multiple judges, to reduce cheating.
- The judge is supposed to deposit a predetermined amount of Ether and in case he/she does not make a decision by the Deadline (each bet has a deadline), this amount is divided amongst the two participants




## To run the code
- go to this link https://remix.ethereum.org/
- click on GitHub below Import From
- Paste this link in the box appearing on the screen :- https://github.com/alimurtaza0411/WEC_Systems_SIG_Recs2020_Blockchain_Task/blob/main/betting.sol
- Press ok
- you will see the betting.sol file in side navigation bar
- activate following two plugins :
    - DEPLOY & RUN TRANSACTIONS
    - SOLIDITY COMPILER
- compile the contract and run.
