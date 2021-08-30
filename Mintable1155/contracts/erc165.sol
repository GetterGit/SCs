pragma solidity ^0.8.0;

import "./ierc165.sol";

contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceID) external view override returns (bool) {  // Overriding IERC165 supportInterface function.
    return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0 ||    // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
            interfaceID == 0x0e89341c ||    //ERC-1155 Metadata URI support.
            interfaceID == 0xd9b67a26;      //ERC-1155 support.
    }

}