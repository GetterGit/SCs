pragma solidity ^0.4.22;

contract Vianu {

    string public constant name = "Vianu";
    string public constant symbol = "VIN";
    uint8 public constant decimals = 18;

    //These events will be invoked or emitted when a user is granted rights to withdraw tokens from an account (Approval), and after the tokens are actually transferred (Transfer).
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    //First, we need to define two mapping objects. This is the Solidity notion for an associative or key/value array.
    //The expression mapping(address => uint256) defines an associative array whose keys are of type address— a number used to denote account addresses, 
    //and whose values are of type uint256 — a 256-bit integer typically used to store token balances.
    mapping(address => uint256) balances; //holding the token balance of each owner account
    mapping(address => mapping(address => uint256)) allowed; //all of the accounts approved to withdraw from a given account together with the withdrawal sum allowed for each.

    //Blockchain storage is expensive and users of your contract will need to pay for, one way or another. Therefore you should always try to minimize storage size and writes into the blockchain. 

    //Will be setting the total amount of tokens at contract creation time and initially assign all of them to the “contract owner” i.e. the account that deployed the smart contract
    uint256 totalSupply_;

    //introducing the library to the solidity compiler
    using SafeMath for uint256;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_; //msg is a global variable declared and populated by Ethereum itself. It contains important data for performing the contract. The field we are using here: msg.sender contains the Ethereum account executing the current contract function. Only the deploying account can enter a contract’s constructor. When the contract is started up, this function allocates available tokens to the ‘contract owner’ account.
    } //A constructor is a special function automatically called by Ethereum right after the contract is deployed. It is typically used to initialize the token’s state using parameters passed by the contract’s deploying account.

    //This function will return the number of all tokens allocated by this contract regardless of owner.
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    //balanceOf will return the current token balance of an account, identified by its owner’s address.
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    //The transferring owner is msg.sender i.e. the one executing the function, which implies that only the owner of the tokens can transfer them to others.
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]); //If a require statement fails, the transaction is immediately rolled back with no changes written into the blockchain.
        balances[msg.sender] = balances[msg.sender].sub(numTokens); 
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens); //Right before exiting, the function fires ERC20 event Transfer allowing registered listeners to react to its completion.
        return true;
    }

    //What approve does is to allow an owner i.e. msg.sender to approve a delegate account—possibly the marketplace itself—to withdraw tokens from his account and to transfer them to other accounts.
    //As you can see, this function is used for scenarios where owners are offering tokens on a marketplace. It allows the marketplace to finalize the transaction without waiting for prior approval.
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens); //At the end of its execution, this function fires an Approval event.
        return true;
    }

    //This function returns the current approved number of tokens by an owner to a specific delegate, as set in the approve function.
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]); //msg.sender will be the delegate as I understand it
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens); //This basically allows a delegate with a given allowance to break it into several separate withdrawals, which is typical marketplace behavior.
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}



//We could stop here and have a valid ERC20 implementation. However, we want to go a step further, as we want an industrial strength token. 
//This requires us to make our code a bit more secure, though we will still be able to keep the token relatively simple, if not basic.

//SafeMath protects against the integer overflow attack by testing for overflow before performing the arithmetic action, thus removing the danger of overflow attack. 
//The library is so small that the impact on contract size is minimal, incurring no performance and little storage cost penalties.
library SafeMath { //Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); //assert statement is used to verify the correctness of the passed params. Should assert fail, the function execution will be immediately stopped and all blockchain changes shall be rolled back.
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}