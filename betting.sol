// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.7.0;

contract Betting{
    //variables
    struct Bet{
        address payable challenger;     // challenger
        address payable accepter;       // accepter
        address payable judge;          // judge
        address payable winner;         //winner
        string statement;               //satement
        uint amount;                    // amount
        uint timeLimit;                  // time
        uint ID;                        // ID
        bool open;                      // open for acceptance
        bool declared;                  // result status
        bool settled;                   // settled
    }
    
    mapping(uint=>Bet) bet;             //bets
    
    address administrator;              //contract creator
    
    uint bet_count;                     // bet count
    
    
    
    //modifiers
    modifier onlyAdministrator(){
        require(administrator==msg.sender,"Not allowed");
        _;
    }
    
    modifier onlyJudge(uint _ID){
        require(bet[_ID].judge==msg.sender,"You are not the judge");
        _;
    }
    
    modifier onlyIfOpen(uint _ID){
        require(bet[_ID].open==true,"Bet is closed");
        _;
    }
    
    modifier notDeclared(uint _ID){
        require(bet[_ID].declared==false,"Already declared");
        _;
    }
    
    modifier notSettled(uint _ID){
        require(bet[_ID].settled==false,"Already Settled");
        _;
    }
    modifier notJudge(uint _ID){
        require(bet[_ID].judge!=msg.sender,"Judge is not allowed to accept the bet");
        _;
    }
    
    //functions
    
    //constructor
    constructor() public{
        administrator = msg.sender;
        bet_count = 0;
    }
    
    //challenger will call this function to create a bet
    function challenge(string memory _statement, uint _amount, address payable _judge) public payable returns(uint bet_ID){
        bet_count++;                        // incremented for every new bet
        bet_ID = bet_count;
        bet[bet_ID].ID = bet_count;
        bet[bet_ID].challenger = payable(msg.sender);
        bet[bet_ID].statement = _statement;
        bet[bet_ID].judge = _judge;
        bet[bet_ID].amount = _amount;
        bet[bet_ID].open = true;
        bet[bet_ID].timeLimit = now+86400;
        bet[bet_ID].declared = false;
        return bet_ID;                      // returns the bet ID 
    }
    
    
    //accepter will call this function to accept the the bet  with its id
    function accept(uint _ID) public payable onlyIfOpen(_ID) notJudge(_ID) {
        require(msg.value==bet[_ID].amount,"Invalid Amount");       //the value should be equal to the bet amount specified by the challenger
        bet[_ID].accepter = msg.sender;
        bet[_ID].open =false;
    }
    
    //judge will announce the result by callinng this function
    function declareResult(uint _ID, bool result ) public  notSettled(_ID) notDeclared(_ID) onlyJudge(_ID) {        //bet should not be settled not declared
        if(result==true){                                       // if condition/statement satisfied
            bet[_ID].winner = payable(bet[_ID].challenger);     //challenger will be the winner
        }
        else{                                                   // else
            bet[_ID].winner = payable(bet[_ID].accepter);       //accepter will be the winner
        }
        bet[_ID].declared = true;
    }
     
    // this function is called by only administrator 
    function settleBet(uint _ID) public payable notSettled(_ID)  onlyAdministrator returns(bool){       //should not be settled
        if(bet[_ID].open==true){                // if bet was not accepted by any one
            if(bet[_ID].timeLimit>now){        // if bet time is not over
                return false;
            }
            bet[_ID].challenger.transfer(bet[_ID].amount);  // if time is over
        }
        else if(bet[_ID].declared==false){                      // if result was not declared by the judge
            if(bet[_ID].timeLimit>now){        // if bet time is not over
                return false;
            }
            bet[_ID].challenger.transfer(bet[_ID].amount);      
            bet[_ID].accepter.transfer(bet[_ID].amount);
        }
        else{                                                               //when result is declared
            bet[_ID].judge.transfer(bet[_ID].amount/10);                         // 10% of total amount is given to the judge
            bet[_ID].winner.transfer((2*bet[_ID].amount)-(bet[_ID].amount/10)); // and remaing amount is given to the winner
        }
        bet[_ID].settled =true;
        return true;
        
    }
    
    // to get details of open bet
    function betDetails(uint _ID) public view onlyIfOpen(_ID) returns(string memory statement ,address judge , uint amount , uint timeLeft){
        statement = bet[_ID].statement;
        judge = bet[_ID].judge;
        amount = bet[_ID].amount;
        timeLeft = bet[_ID].timeLimit - now;
    }   
    
    
    
}