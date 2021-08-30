pragma solidity ^0.8.0;

import "./enumerable_set.sol";
import "./context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {

    using EnumerableSet for EnumberableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    
    /****************************************|
    |                 Events                 |
    |_______________________________________*/

    /**
    * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
    *
    * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
    * {RoleAdminChanged} not being emitted signaling this.
    *
    * _Available since v3.1._
    */
    event RoleAdminChanged(bytes32 indexed _role, bytes32 indexed _previousAdminRole, bytes32 indexed _newAdminRole);

    /**
    * @dev Emitted when `account` is granted `role`.
    *
    * `sender` is the account that originated the contract call, an admin role
    * bearer except when using {_setupRole}.
    */
    event RoleGranted(bytes32 indexed _role, address indexed _account, address indexed _sender);

    /**
    * @dev Emitted when `account` is revoked `role`.
    *
    * `sender` is the account that originated the contract call:
    *   - if using `revokeRole`, it is the admin role bearer
    *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
    */
    event RoleRevoked(bytes32 indexed _role, address indexed _account, address indexed _sender);

    /****************************************|
    |                Functions               |
    |_______________________________________*/

    /**
    * @dev Returns `true` if `account` has been granted `role`.
    */
    function hasRole(bytes32 _role, address _account) public view returns (bool) {
        return _roles[_role].members.contains(_account);
    }

    /**
    * @dev Returns the number of accounts that have `role`. Can be used
    * together with {getRoleMember} to enumerate all bearers of a role.
    */
    function getRoleMemberCount(bytes32 _role) public view returns (uint256) {
        return _roles[_role].members.length();
    }

    /**
    * @dev Returns one of the accounts that have `role`. `index` must be a
    * value between 0 and {getRoleMemberCount}, non-inclusive.
    *
    * Role bearers are not sorted in any particular way, and their ordering may
    * change at any point.
    *
    * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
    * you perform all queries on the same block. See the following
    * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
    * for more information.
    */
    function getRoleMember(bytes32 _role, uint256 _index) public view returns (address) {
        return _roles[_role].members.at(_index);
    }

    /**
    * @dev Returns the admin role that controls `role`. See {grantRole} and
    * {revokeRole}.
    *
    * To change a role's admin, use {_setRoleAdmin}.
    */
    function getRoleAdmin(bytes32 _role) public view returns (bytes32) {
        return _roles[_role].adminRole;
    }

    /**
    * @dev Grants `role` to `account`.
    *
    * If `account` had not been already granted `role`, emits a {RoleGranted}
    * event.
    *
    * Requirements:
    *
    * - the caller must have ``role``'s admin role.
    */
    function grantRole(bytes32 _role, address _account) public virtual {
        require(hasRole(_roles[_role].adminRole, _msgSender()), "AccessControl : Sender must be the role admin to grant the role.");

        _grantRole(_role, _account);
    }

    /**
    * @dev Revokes `role` from `account`.
    *
    * If `account` had been granted `role`, emits a {RoleRevoked} event.
    *
    * Requirements:
    *
    * - the caller must have ``role``'s admin role.
    */
    function revokeRole(bytes32 _role, address _account) public virtual {
        require(hasRole(_roles[_role].adminRole, msg.sender), "AccessControl : Sender must be the role admin to revoke the role.");

        _revokeRole(_role, _account);
    }

    /**
    * @dev Revokes `role` from the calling account.
    *
    * Roles are often managed via {grantRole} and {revokeRole}: this function's
    * purpose is to provide a mechanism for accounts to lose their privileges
    * if they are compromised (such as when a trusted device is misplaced).
    *
    * If the calling account had been granted `role`, emits a {RoleRevoked}
    * event.
    *
    * Requirements:
    *
    * - the caller must be `account`.
    */
    function renounceRole(bytes32 _role, address _account) public virtual {
        require(_account == _msgSender(), "AccessControl : Can only renounce for self.");

        _revokeRole(_role, _account);
    }

    /**
    * @dev Grants `role` to `account`.
    *
    * If `account` had not been already granted `role`, emits a {RoleGranted}
    * event. Note that unlike {grantRole}, this function doesn't perform any
    * checks on the calling account.
    *
    * [WARNING]
    * ====
    * This function should only be called from the constructor when setting
    * up the initial roles for the system.
    *
    * Using this function in any other way is effectively circumventing the admin
    * system imposed by {AccessControl}.
    * ====
    */
    function _setupRole(bytes32 _role, address _account) internal virtual {
        _grantRole(_role, _account);
    }

    /**
    * @dev Sets `adminRole` as ``role``'s admin role.
    *
    * Emits a {RoleAdminChanged} event.
    */
    function _setRoleAdmin(bytes32 _role, bytes adminRole) internal virtual {
        emit RoleAdminChanged(_role, _roles[_role].adminRole, adminRole);
        _roles[_role].adminRole = adminRole;
    }

    /**
    * @dev Sets a role
    *
    * Emits a {RoleGranted} event.
    */
    function _grantRole(bytes32 _role, address _account) private {
        if (_roles[_role].members.add(_account)) {
            emit RoleGranted(_role, _account, _msgSender());
        }
    }

    /**
    * @dev Rovokes a role
    *
    * Emits a {RoleRevoked} event.
    */
    function _revokeRole(bytes32 _role, address _account) private {
        if (_roles[_role].members.remove(_account)) {
            emit RoleRevoked(_role, _account, _msgSender());
        }
    }
}