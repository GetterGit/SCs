pragma solidity ^0.8.0;

import "./access_control.sol";

contract AccessControlMixin is AccessControl {
    string private _revertMsg;

    function _setupContractId(string memory _contractId) internal {
        _revertMsg = string(abi.encodePacked(_contractId, "AccessControlMixin : INSUFFICIENT PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(hasRole(_role, _msgSender()), _revertMsg);
        _;
    }
}