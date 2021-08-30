pragma solidity ^0.8.0;

import "./erc1155.sol";
import "./access_control_mixin.sol";
import "./eip712base";
import "./context_mixin";

contract MintableERC1155 is ERC1155, AccessControl, EIP712Base, ContextMixin {

    using Strings for uint256;

    bytes public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Contract URI 
    string private _uri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri_
    ) public ERC1155(uri_) {
        name = _name;
        symbol = _symbol;
        _uri = uri_;
        _setupContractId("MintableERC1155");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _initializeEIP712(uri_)
    }

    function uri(uint256 _id) external view override returns (string memory) {
        return string(abi.encodePacked(_uri, _id.toString()));
    }

    function collectNFTs(address _token, uint256 _tokenId) external onlyOwner {
        uint256 amount = ERC1155(_token).balanceOf(address(this), _tokenId);
        ERC1155(_token).safeTransferFrom(address(this), msg.sender, _tokedId, amount, "");
    }

    function mint(address _account, uint256 _id, uint256 _amount, bytes calldata _data) external override only(PREDICATE_ROLE) {
        _mint(_account, _id, _amount, _data);
    }

    function mintBatch(address _account, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external override only(PREDICATE_ROLE) {
        _mintBatch(_account, _ids, _amounts, _data);
    } 

    function burn(address _account, uint256 _id, uint256 _value) public virtual {
        require(account == _msgSender() || isApprovedForAll(_account, _msgSender()), "ERC1155 : The caller is not the owner and is not approved for burning.");
        _burn(_account, _id, _value);
    }

    function burnBatch(address _account, uint256[] memory _ids, uint256[] meomory _values) public virtual {
        require(account == _msgSender() || isApprovedForAll(_account, _msgSender()), "ERC1155 : The caller is not the owner and is not approved for batch burning");
        _burnBatch(_account, _ids, _values);
    }

    function _msgSender() internal view override returns (address payable sender) {
        ContextMixin.msgSender();
    }
}