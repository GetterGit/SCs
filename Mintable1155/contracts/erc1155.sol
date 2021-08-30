pragma solidity ^0.8.0;

import "./ownable.sol";
import "./ierc1155token_receiver.sol";
import "./imintable_erc1155.sol"; 
import "./erc165.sol";
import "./safemath.sol";
import "./address.sol";
import "./context.sol";


contact ERC1155 is Ownable, IERC1155TokenReceiver, IMintableERC1155, ERC165, Context { //IERC1155TokenReceiver is IERC1155, hence I didn't put IERC115 here.

    //libraries used
    using SafeMath for uint256;
    using Address for address;

    // onReceive function signatures as per https://github.com/ethereum/EIPs/issues/1155
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    //mapping from address to TokenIDs and their balances for a given address
    mapping (address => mapping(uint256 => uint256)) internal balances;
    //mapping from accounts to operator approvals
    mapping (address => mapping(address => bool)) internal operators;

    /**
    -------------------------------------------------------------
    |              IERC1155 METADATA URI FUNCTIONS              |
    -------------------------------------------------------------
     */
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 _id) external view override returns (string memory) {
        return (abi.encodePacked(_url, _uint2str(_id)));
    }

    /**
    * @dev Sets a new URI for all token types, by relying on the token type ID
    * substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
    *
    * By this mechanism, any occurrence of the `\{id\}` substring in either the
    * URI or any of the amounts in the JSON file at said URI will be replaced by
    * clients with the token type ID.
    *
    * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
    * interpreted by clients as
    * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
    * for token type ID 0x4cce0.
    *
    * See {uri}.
    *
    * Because these URIs cannot be meaningfully represented by the {URI} event,
    * this function emits no events.
    */
    function _setURI(string memory _newuri) internal virtual {
        _uri = newuri;
    }

    /**
    -------------------------------------------------------------
    |                    BALANCE FUNCTIONS                      |
    -------------------------------------------------------------
     */

    /**
    * @notice Get the balance of an account's Tokens
    * @param _owner  The address of the token holder
    * @param _id     ID of the Token
    * @return        The _owner's balance of the Token type requested
    */
    function balanceOf(address _owner, uint256 _id) public view override returns (uint256) {
        return balances[_owner][_id];
    }

    /**
    * @notice Get the balance of multiple account/token pairs
    * @param _owners The addresses of the token holders
    * @param _ids    ID of the Tokens
    * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) public view override returns (uint256[] memory) {
        require(_owners.length == _ids.length, "ERC1155 : Balance of Batch : Lengths of owners' and ids' arrays don't match.");

        //Initiating the variable to store the results of the function execution
        uint256[] batchBalances = new uint256[](_owners.length);

        //Iterating on each owner and token id 
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    /**
    -------------------------------------------------------------
    |                    APPROVAL FUNCTIONS                     |
    -------------------------------------------------------------
     */

    /**
    * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
    * @dev MUST emit the ApprovalForAll event on success
    * @param _operator  Address to add to the set of authorized operators
    * @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        require (_msgSender() != _operator, "ERC1155 : Setting the approval for self.");
        operators[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
    * @notice Queries the approval status of an operator for a given owner
    * @param _owner     The owner of the Tokens
    * @param _operator  Address of authorized operator
    * @return isOperator True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        return operators[_owner][_operator];
    }

    /**
    -------------------------------------------------------------
    |                   INTERNAL TRANSFER FUNCTIONS             |
    -------------------------------------------------------------
    */

    /**
    * @notice Transfers amount amount of an _id from the _from address to the _to address specified
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    */
    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) internal virtual override {
        //Update balances
        balances[_from][_id] = balances[_from][_id].sub(_amount);
        balances[_to][_id] = balances[_to][_id].add(_amount);

        //Emit event
        emit TransferSingle(_msgSender(), _from, _to, _id, _amount);
    }

    /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    */
    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal virtual override {
        //Requre equal _ids and _amounts arrays' lengths
        require(_ids.length == _amounts.length, "ERC1155 : Not equal _ids and _amounts arrays' lengths in _safeBatchTransferFrom.")

        //Number of transfers to execute
        uint256 numTransfers = _ids.length;

        //Update balances for all transfers which is numTransfers.legnth
        for (uint256 i = 0; i < numTransfers; i++) {
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        //Emit event
        emit TransferBatch(_msgSender(), _from, _to, _ids, _amounts);
    }

    /**
    -------------------------------------------------------------
    |                   INTERNAL MINTING FUNCTIONS              |
    -------------------------------------------------------------
    */

    /**
	* @notice Creates `amount` tokens of token type `id`, and assigns them to `account`.
	* @dev Should be callable only by MintableERC1155Predicate
	* @dev Make sure minting is done only by this function
    * @dev If _to refers to a smart contract, then onERC1155Received should be called and it should return the acceptance magic value (implemented for the public minting function)
	* @param to user address for whom token is being minted
	* @param id token which is being minted
	* @param amount amount of token being minted
	* @param data extra byte data to be accompanied with minted tokens
	*/
    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) internal virtual override {
        require(_to != address(0), "ERC1155 : Can't mint to the zero address."); 
        balances[_to][_id] = balances[_to][_id].add(_amount); //Updating the recipient's balance
        emit TransferSingle(_msgSender(), address(0), _to, _id, _amount);
    }
    
    /**
	 * @notice Batched version of singular token minting, where
	 * for each token in `ids` respective amount to be minted from `amounts`
	 * array, for address `to`.
	 * @dev Should be callable only by MintableERC1155Predicate
	 * Make sure minting is done only by this function
     * @dev If _to refers to a smart contract, then onERC1155BatchReceived should be called and it should return the acceptance magic value (implemented for the public batch minting function)
	 * @param to user address for whom token is being minted
	 * @param ids tokens which are being minted
	 * @param amounts amount of each token being minted
	 * @param data extra byte data to be accompanied with minted tokens
	 */
    function _mintBatch(address _to, uint256][] memory _ids, uint256[] memory _amounts, bytes memory _data) internal virtual override {
        require(_to != address(0), "ERC1155 : Can't mint a batch to the zero address.");
        require(_ids.length == _amounts.length, "ERC1155 : _ids and _amounts length mismatch for the batch mint.");

        //Updating the recipient's balance
        for (i = 0; i < _ids.length; i++) {
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        emit TransferBatch(_msgSender(), address(0), _to, _ids, _amounts);
    }

    /**
    -------------------------------------------------------------
    |                   INTERNAL BURING FUNCTIONS               |
    -------------------------------------------------------------
    */

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
     function _burn(address _account, uint256 _id, uint256 _amount) internal virtual {
         require(_account != address(0), "ERC1155 : Burning from the zero address.");
         balances[_account][_id] = balances[_account][_id].sub(_amount, "ERC1155 : Burn amount exceeds the balance.");
         emit TransferSingle(_msgSender(), _account, address(0), _id, _amount);
     }

     /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
     function _burnBatch(address _account, uint256[] memory _ids, uint256[] memory _amounts) internal virtual {
        require(_account != address(0), "ERC1155 : Batch burning from the zero address.");
        require(_ids.lenght == _amounts,length, "ERC1155 : _ids and _amounts length mismatch for the batch burn.");

        //Updating the balances of the account the tokens are burned from
        for (i = 0; i < _ids.length; i++) {
            balances[_account][_ids[i]] = balances[_account][_ids[i]].sub(_amounts[i], "ERC1155 : Batch burn amount exceeds the balance.");
        }
        
        emit TransferBatch(_msgSender(), _account, address(0), _ids, _amounts);
     }
        

    /**
    -------------------------------------------------------------
    |              ERC1155 TOKEN RECEIVER FUNCTIONS             |
    -------------------------------------------------------------
    */

    /**
    * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
    */
    function _onERC1155Received(address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal override returns (bytes4 response) {
        //Pass the data if the recipient is a contract
        if (_to.isContract()) {
            bytes4 response = IERC1155TokenReceiver(_to).onERC1155Received(_msgSender(), _from, _id, _value, _data);
            require(response == ERC1155_RECEIVED_VALUE, "ERC1155 : Invalid on-receive message in _onERC1155Received.");
        }
    }

    /**
    * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
    */
    function _onERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data]) internal override returns (bytes4 response) {
        //Pass the data if the recipient is a contract
        if (_to.isContract()) {
            bytes4 response = IERC1155TokenReceiver(_to).onERC1155BatchReceived(_msgSender(), _from, _ids, _values, _data);
            require(respinse == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155 : Invalid on-receive message in _onERC1155BatchReceived.");
        }
    }

    /**
    -------------------------------------------------------------
    |                   PUBLIC TRANSFER FUNCTIONS               |
    -------------------------------------------------------------
     */

     /**
    * @notice Transfers amount amount of an _id from the _from address to the _to address specified
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256, _amount, bytes memory _data) public override {
        //A person sending the asset should either be its owner or approved by the owner to transfer this asset
        require(_msgSender() == _from || isApprovedForAll(_from, _msgSender()));
        //Should throw an error if sending to the zero address
        require(_to != address(0), "ERC1155 : Single transfer to the zero address.");
        // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

        //Calling required internal functions
        _safeTransferFrom(_from, _to, _id, _amount);
        _onERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public override {
        //A person sending the assets should either be its owner or approved by the owner to transfer these assets
        require(_msgSender() == _from || isApprovedForAll(_from, _msgSender()));
        //Should throw an error if sending to the zero address
        require(_to != address(0), "ERC1155 : Batch transfer to the zero address.");
        // The "_amounts <= balances[_from][_ids]" loop is not necessary since checked with safemath operations

        //Calling required internal functions
        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _onERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
   } 
}