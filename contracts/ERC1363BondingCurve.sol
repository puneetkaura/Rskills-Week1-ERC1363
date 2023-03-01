// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "hardhat/console.sol";

import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/ERC1363.sol";
import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Receiver.sol";
import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Spender.sol";

/**
 * @title ERC1363BondingCurve
 * @dev Token with god mode. A special address is able to transfer tokens between addresses at will.
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

/// Sanction can be made by an address can be sactioner , cannot sanction GOD
/// GOD can change sanctioner
contract ERC1363BondingCurve is ERC20, ERC1363, IERC1363Receiver {
    address payable public owner;
    uint256 public constant basePrice = 0.0001 ether; // 1 ETH  = 10,000 CTKN
    uint256 public constant priceIncreasePerToken = 1000 gwei;

    constructor() ERC20("CTKN", "CTKN") ERC1363() {
        owner = payable(msg.sender);
    }

    function getCurrentPrice() public view returns (uint) {
        return basePrice + totalSupply() * priceIncreasePerToken;
    }

    function estimateBuyETHAmount(uint amount) public view returns (uint) {
        return
            (getCurrentPrice() * amount) +
            ((priceIncreasePerToken * amount * amount) / 2);
    }

    function simulateAmount(
        uint amount,
        uint totalSupply,
        bool amountInceasesSupply
    ) public pure returns (uint) {
        if (amountInceasesSupply) {
            return (((basePrice + (priceIncreasePerToken * totalSupply)) *
                amount) + ((priceIncreasePerToken * amount * amount) / 2));
        } else {
            return (((basePrice + (priceIncreasePerToken * totalSupply)) *
                amount) - ((priceIncreasePerToken * amount * amount) / 2));
        }
    }

    function estimatSellETHAmount(uint amount) public view returns (uint) {
        return
            (getCurrentPrice() * amount) -
            ((priceIncreasePerToken * amount * amount) / 2);
    }

    function buy(uint _amount) public payable {
        require(
            msg.value == estimateBuyETHAmount(_amount),
            "Supply the right amount, use estimateBuyETHAmount"
        );
        _mint(msg.sender, _amount);
    }

    function sell(uint _amount) public {
        require(_amount > 0 && _amount < totalSupply(), "Invalid amount");
        uint ethAmount = estimatSellETHAmount(_amount);
        console.log((ethAmount / 10) ^ 18);
        _burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Sale failed");
    }

    function withdraw() external returns (bool) {
        require(msg.sender == owner, "Only Owner can withdraw");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
        return success;
    }

    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        console.log(spender);
        console.log(sender);
        require(amount > 0 && amount <= totalSupply(), "Invalid amount");
        uint ethAmount = estimatSellETHAmount(amount);
        console.log((ethAmount / 10) ^ 18);
        _burn(msg.sender, amount);
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "Sale failed");

        return
            bytes4(
                keccak256("onTransferReceived(address,address,uint256,bytes)")
            );
    }
}
