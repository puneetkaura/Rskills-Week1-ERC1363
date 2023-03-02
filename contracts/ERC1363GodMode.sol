// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

/**
 * @title ERC1363GodMode
 * @author pkaura
 * @notice Token with god mode - A special address is able to transfer tokens between addresses at will.
 * Token with sanctions- A fungible token that allows an admin to ban specified addresses from sending and receiving tokens.
 * Token with sanctions- A fungible token that allows an admin to ban specified addresses from sending and receiving tokens.
 * GodTxfer does not need/affect Approvals
 * Sanction means - Cannot accept or Send tokens
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract ERC1363GodMode is ERC20, ERC20Capped, ERC1363 {
    uint private constant SUPPLY_CAP = 100_000_000;
    address public immutable GOD;
    address public admin;

    mapping(address => bool) public isSanctioned;

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

    /**
     * @notice Emitted when God address txfers tokens.
     */
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

        emit AddressSanctioned(_address, msg.sender);
    }

    /**
     * @dev allow any address to mint tokens
     * @param _address to sanction
     */

    function unsanction(address _address) external adminAndAbove {
        isSanctioned[_address] = false;
        emit AddressUnscantioned(_address, msg.sender);
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
     */
    function godTransfer(address from, address to, uint amount) public onlyGOD {
        _transfer(from, to, amount);
        emit GodTxfer(from, to, amount);
    }

    /**
     * @notice - `to` cannot be a sanctioned address
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
        require(address(0) != newAdmin, "Address 0 cant't be admin");
        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminChanged(oldAdmin, newAdmin);
    }
}
