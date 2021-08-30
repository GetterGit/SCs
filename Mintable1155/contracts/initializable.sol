pragma solidity ^0.8.0;

contract Initializable {
    bool initialized = false;

    modifier initializer() {
        require(!initialized, "Already initialized.");
        _;
        initialized = true;
    }
}