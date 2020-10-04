// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.7.0;

contract Betting{
    //variables
    struct Judge {
        bool acceptedByChallenger;              //judge is accepted by challenger
        bool acceptedByaccepter;                // judge is accepted by accepter
        bool allowedToDeclareResult;             // this is true when judge deposits security amount
        address payable judgeAddress;           // judge's address
        bool declared;                          // judge has declared result or not
    }
    
    struct Bet{
        address payable challenger;                 // challenger
        address payable accepter;                   // accepter
        address payable winner;                     //winner
        uint ToChallenger;                         // reults count in favour of challenger
        uint ToAccepter;                             // results count in favourof Accepter
        string statement;                           //satement
        mapping (uint=>Judge) judge;                //judges    
        uint judgesCount;                           // number judges
        uint judgesWhoDeclaredResult ;             // judges who declared result
        uint amount;                                // amount
        uint totalAmount;                            // all the amount in the bet including judges' security amount
        uint timeLimit;                             // time
        bool open;                                  // open for acceptance
        bool declared;                              // result status
        bool settled;                               // settled
    }
    
    mapping(uint=>Bet) bet;             //bets
    
    address administrator;              //contract creator
    
    uint bet_count;                     // bet count
    
    uint securityAmount = 1000000000000000000;          // security Amount given by judge while accepting the bet (1 ether) fixed
    
    
    //modifiers
    modifier onlyAdministrator(){
        require(administrator==msg.sender,"Not allowed");
        _;
    }
    
    modifier onlyJudge(uint bet_ID, uint judge_ID){
        require(bet[bet_ID].judge[judge_ID].judgeAddress==msg.sender,"Judge ID does not match");
        require(bet[bet_ID].judge[judge_ID].allowedToDeclareResult==true,"You are not the judge");
         require(bet[bet_ID].judge[judge_ID].declared==false,"Judge have already declared the result");
        _;
    }
    
    modifier onlyIfOpen(uint bet_ID){
        require(bet[bet_ID].open==true,"Bet is closed");
        _;
    }
    
    modifier notSettled(uint bet_ID){
        require(bet[bet_ID].settled==false,"Already Settled");
        _;
    }
    modifier ifTimeIsOver(uint bet_ID){
        require(now > bet[bet_ID].timeLimit,"Cannot settle bet early");
        _;
    }
    
    //functions
    
    //constructor
    constructor() public{
        administrator = msg.sender;
        bet_count = 0;
    }
    
    //challenger will call this function to create a bet
    function challenge(string memory _statement, uint _amount) public payable returns(uint bet_ID){
        require(msg.value==_amount,"Amount specify is not equal to value send");
        bet_count++;                        // incremented for every new bet
        bet_ID = bet_count;
        bet[bet_ID].challenger = payable(msg.sender);
        bet[bet_ID].statement = _statement;
        bet[bet_ID].amount = _amount;
        bet[bet_ID].totalAmount = _amount;
        bet[bet_ID].judgesCount =0;
        bet[bet_ID].ToChallenger =0;
        bet[bet_ID].ToAccepter = 0;
        bet[bet_ID].judgesWhoDeclaredResult =0;
        bet[bet_ID].open = true;
        bet[bet_ID].timeLimit = now+86400;
        bet[bet_ID].declared = false;
        return bet_ID;                      // returns the bet ID 
    }
    
    
    //accepter will call this function to accept the the bet  with its id
    function accept(uint bet_ID) public payable onlyIfOpen(bet_ID)  {
        require(msg.value==bet[bet_ID].amount,"Invalid Amount");       //the value should be equal to the bet amount specified by the challenger
        bet[bet_ID].accepter = msg.sender;
        bet[bet_ID].totalAmount+=msg.value;
        bet[bet_ID].open =false;
    }
    
    //challenger and accepter can add a judge using this function
    function addJudge(uint bet_ID, address payable _judge) public payable returns(uint judge_ID) {
        require(bet[bet_ID].settled==false,"bet is Settled");                                          // cannot add judge if bet is already Settled //declared
        require(bet[bet_ID].declared ==false, "result is declared");                                    //declared
        require(bet[bet_ID].open==false,"Bet is still open cannot add judge");                          // or  bet is still open
        if(msg.sender!=bet[bet_ID].challenger){
            require(msg.sender==bet[bet_ID].accepter,"You are not allowed");                                // this function can be call by challenger and accepter
            bet[bet_ID].judgesCount++;
            judge_ID = bet[bet_ID].judgesCount;
            bet[bet_ID].judge[judge_ID].acceptedByaccepter =true;
            bet[bet_ID].judge[judge_ID].acceptedByChallenger =false;
        }
        else{
            bet[bet_ID].judgesCount++;
            judge_ID = bet[bet_ID].judgesCount;
            bet[bet_ID].judge[judge_ID].acceptedByChallenger =true;
            bet[bet_ID].judge[judge_ID].acceptedByaccepter =false;
        }
        bet[bet_ID].judge[judge_ID].judgeAddress = _judge;
        bet[bet_ID].judge[judge_ID].allowedToDeclareResult =false;
            
    }
    
    //challenger and accept a judge added by anyone of them
    function acceptJudge(uint bet_ID, uint judge_ID) public {
        if(msg.sender!=bet[bet_ID].challenger){                                                             // using this function opposite party can accept the judge
            require(msg.sender==bet[bet_ID].accepter,"You are not allowed");                                // without this permision judge  cannot exxcept the judge
            require(bet[bet_ID].judge[judge_ID].acceptedByaccepter==false,"You have already accepted");
            bet[bet_ID].judge[judge_ID].acceptedByaccepter =true;
        }
        else{
            require(bet[bet_ID].judge[judge_ID].acceptedByChallenger==false,"You have already accepted");
            bet[bet_ID].judge[judge_ID].acceptedByChallenger =true;
        }
    }
    
    //judge will call to accept the challege
    function judgeAcceptance(uint bet_ID, uint judge_ID) public payable {
        require(msg.sender == bet[bet_ID].judge[judge_ID].judgeAddress,"Not Allowed");                                  // judge have to accept the bet and 
        require(bet[bet_ID].judge[judge_ID].acceptedByaccepter==true,"You are not accepted by accepter");               // deposite a security amount in case fail to declare result
        require(bet[bet_ID].judge[judge_ID].acceptedByChallenger==true,"You are not accepted by challenger");
        require(msg.value == securityAmount, "Security amount is not appropriate");
        bet[bet_ID].judge[judge_ID].allowedToDeclareResult =true;
        bet[bet_ID].totalAmount+=securityAmount;
        
    }
    
    
    //judge will announce the result by callinng this function
    function declareResult(uint bet_ID, bool result, uint judge_ID ) public  notSettled(bet_ID)  onlyJudge(bet_ID,judge_ID)  {        //bet should not be settled not declared
        if(result==true){                                              // if condition/statement satisfied
            bet[bet_ID].ToChallenger++;     //challenger will be the winner
        }
        else{                                                          // else
            bet[bet_ID].ToAccepter++;       //accepter will be the winner
        }
        bet[bet_ID].judge[judge_ID].declared = true;
        bet[bet_ID].declared = true;
        bet[bet_ID].judgesWhoDeclaredResult++;
    }
     
    // this function is called by only administrator 
    function settleBet(uint bet_ID) public payable notSettled(bet_ID)  onlyAdministrator ifTimeIsOver(bet_ID) returns(bool){       //should not be settled
        if(bet[bet_ID].open==true){                // if bet was not accepted by any one
            bet[bet_ID].challenger.transfer(bet[bet_ID].totalAmount);  // if time is over
        }
        else if(bet[bet_ID].declared==false){                      // if result was not declared by the judge
            bet[bet_ID].challenger.transfer(bet[bet_ID].totalAmount/2);      
            bet[bet_ID].accepter.transfer(bet[bet_ID].totalAmount/2);
        }
        else{                                                                                                                   //when result is declared
            if(bet[bet_ID].ToChallenger==bet[bet_ID].ToAccepter){
               for(uint i=1;i<=bet[bet_ID].judgesCount;i++){
                    if(bet[bet_ID].judge[i].declared==true){
                        bet[bet_ID].judge[i].judgeAddress.transfer(securityAmount); // security amount is return to judges who declared result
                        bet[bet_ID].totalAmount-= securityAmount;               //subtracting the amount from total
                    }
                } 
                bet[bet_ID].challenger.transfer(bet[bet_ID].totalAmount/2);                 // result is tie then total amount is equally distributed
                bet[bet_ID].challenger.transfer(bet[bet_ID].totalAmount/2); 
            }
            else{
                if(bet[bet_ID].ToChallenger>bet[bet_ID].ToAccepter){
                    bet[bet_ID].winner =bet[bet_ID].challenger;
                }
                else{
                    bet[bet_ID].winner =bet[bet_ID].accepter;
                }
                for(uint i=1;i<=bet[bet_ID].judgesCount;i++){
                    if(bet[bet_ID].judge[i].declared==true){
                        bet[bet_ID].judge[i].judgeAddress.transfer(bet[bet_ID].amount/(10*bet[bet_ID].judgesWhoDeclaredResult) + securityAmount); // 10% of total amount is given to all the judges(equal share)
                        bet[bet_ID].totalAmount-=bet[bet_ID].amount/(10*bet[bet_ID].judgesWhoDeclaredResult) + securityAmount;               //subtracting the amount from total
                    }
                }
                bet[bet_ID].winner.transfer((2*bet[bet_ID].amount)-(bet[bet_ID].amount/10)); // and remaing amount is given to the winner
                bet[bet_ID].totalAmount-=(2*bet[bet_ID].amount)-(bet[bet_ID].amount/10);                       //subtracting the amount from total
                if( bet[bet_ID].totalAmount>0){
                    bet[bet_ID].challenger.transfer(bet[bet_ID].totalAmount/2);                 // security Amount of judges 
                    bet[bet_ID].challenger.transfer(bet[bet_ID].totalAmount/2);                 // who didn't declare result
                }
            }
            
        }
        bet[bet_ID].settled =true;
        return true;
        
    }
    
    // to get details of open bet
    function betDetails(uint bet_ID) public view onlyIfOpen(bet_ID) returns(string memory statement , uint amount , uint timeLeft, bool open){
        statement = bet[bet_ID].statement;                                  // this function will return the bet details
        amount = bet[bet_ID].amount;
        timeLeft = bet[bet_ID].timeLimit - now;
        open= bet[bet_ID].open;
        
    }   
    
    // function to get judge status
    function judgeDetails(uint bet_ID, uint judge_ID)public view  returns(address payable judgeAddress, bool acceptedByChallenger, bool acceptedByaccepter, bool allowedToDeclareResult){
       judgeAddress = bet[bet_ID].judge[judge_ID].judgeAddress;
       acceptedByChallenger = bet[bet_ID].judge[judge_ID].acceptedByChallenger;
       acceptedByaccepter = bet[bet_ID].judge[judge_ID].acceptedByaccepter;
       allowedToDeclareResult = bet[bet_ID].judge[judge_ID].allowedToDeclareResult;
    }
    
    
    
}