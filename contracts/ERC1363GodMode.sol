// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/ERC1363.sol";
import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Receiver.sol";
import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Spender.sol";

/// Missing events - AddressSanctioned, AddressUnscantioned, GodTxfer, AdminUpgrade

/** How it works
- Admin can sanction/Unsanction any address 
- God can do what admin can do +++  { tranfer token from any --> any address plus + Change admin }
- Sanction means - Cannot accept or Send tokens
- GodTxfer does not need/affect Approvals
**/

/**
 * @title ERC1363GodMode
 * @dev Token with god mode. A special address is able to transfer tokens between addresses at will.
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

/// Sanction can be made by an address can be sactioner , cannot sanction GOD
/// GOD can change sanctioner
contract ERC1363GodMode is ERC20, ERC20Capped, ERC1363 {
    uint private constant SUPPLY_CAP = 100_000_000;
    address admin;
    mapping(address => bool) public isSanctioned;
    address public immutable GOD;

    constructor(
        address god
    ) ERC20("GMODE", "GMODE") ERC20Capped(SUPPLY_CAP) ERC1363() {
        GOD = god;
        admin = god;
    }

    modifier onlyGOD() {
        require(msg.sender == GOD, "Only GOD");
        _;
    }

    modifier adminAndAbove() {
        require(
            msg.sender == admin || msg.sender == GOD,
            "Only Admin and GOD allowed"
        );
        _;
    }

    modifier notSanctioned(address from, address to) {
        require(
            !(isSanctioned[from] || isSanctioned[to]),
            "Sanctioned address detected"
        );
        _;
    }

    event GodTxfer(
        address indexed from,
        address indexed to,
        uint indexed amount
    );

    event AddressSanctioned(address indexed _address, address sanctionedBy);

    event AddressUnscantioned(address indexed _address, address sanctionedBy);

    event AdminChanged(address oldAdmin, address newAdmin);

    /**
     * @dev allow any address to mint tokens
     * @param _address to sanction
     */
    function sanction(address _address) external adminAndAbove {
        require(!(_address == GOD), "GOD can't be sanctioned");
        isSanctioned[_address] = true;
    }

    /**
     * @dev allow any address to mint tokens
     * @param _address to sanction
     */

    function unsanction(address _address) external adminAndAbove {
        isSanctioned[_address] = false;
    }

    /**
     * @dev allow any address to mint tokens
     * @param amount value to store
     */
    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Capped) {
        super._mint(to, amount);
    }

    // Anyone can mint any number of tokens till cap is reached
    function mint(uint _amount) external returns (bool) {
        _mint(msg.sender, _amount);
        return true;
    }

    /**
     * @dev god can transfer token to any account from any account
     * @return value of boolean
     */
    function godTransfer(
        address from,
        address to,
        uint amount
    ) public onlyGOD returns (bool) {
        _transfer(from, to, amount);
        emit GodTxfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public override(ERC20, IERC20) returns (bool) {
        require(!isSanctioned[to], "Sanctioned address detected");
        return super.transfer(to, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(IERC20, ERC20) returns (bool) {
        require(
            !(isSanctioned[from] || isSanctioned[to]),
            "Sanctioned address detected"
        );
        return super.transferFrom(from, to, amount);
    }

    function updateAdmin(address newAdmin) external onlyGOD {
        require(address(0) == newAdmin, "Address 0 cant't be admin");
        admin = newAdmin;
    }
}
