// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TokenMarketPlace is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public tokenPrice = 2e16 wei; // 0.02 ether per GLD token
    uint256 public sellerCount = 1;
    uint256 public buyerCount = 1;
    uint256 public prevAdjustedRatio;

    IERC20 public Bees;

    constructor(address _BeesToken) Ownable(msg.sender) {
        Bees = IERC20(_BeesToken);
    }

    event TokenPriceUpdated(uint256 newPrice);
    event TokenBought(address indexed buyer, uint256 amount, uint256 totalCost);
    event TokenSold(
        address indexed seller,
        uint256 amount,
        uint256 totalEarned
    );
    event TokensWithdrawn(address indexed owner, uint256 amount);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    event CalculateTokenPrice(uint256 priceToPay);

    // Updated logic for token price calculation with safeguards
    function adjustTokenPriceBasedOnDemand() public {
        uint256 marketDemandRatio = buyerCount.mul(1e18).div(sellerCount);
        uint256 smoothingFactor = 1e18;
        uint256 adjustedRatio = marketDemandRatio.add(smoothingFactor).div(2);
        if (prevAdjustedRatio != adjustedRatio) {
            uint256 newTokenPrice = tokenPrice.mul(adjustedRatio).div(
                smoothingFactor
            );
            uint256 minimumPrice = 2e18;
            if (newTokenPrice < minimumPrice) {
                tokenPrice = minimumPrice;
            }
            tokenPrice = newTokenPrice;
            emit TokenPriceUpdated(tokenPrice);
        }
    }

    // Buy tokens from the marketplace
    function buyGLDToken(uint256 _amountOfToken) public payable {
        require(_amountOfToken > 0, "Amount of token greater than zero");
        uint256 requiredTokenPrice = calculateTokenPrice(_amountOfToken);
        require(requiredTokenPrice == msg.value, "Incorrect amount paid ");
        (bool success, ) = payable(msg.sender).call{value: requiredTokenPrice}(
            ""
        );
        require(success, "Token trasfered succesfull");
        Bees.safeTransfer(msg.sender, _amountOfToken);
        buyerCount += 1;
    }

    function calculateTokenPrice(uint256 _amountOfToken)
        public
        returns (uint256)
    {
        require(_amountOfToken > 0, "Amount of token greater than zero");
        adjustTokenPriceBasedOnDemand();
        uint256 amountToPay = _amountOfToken.mul(tokenPrice).div(1e18);
        console.log("amountToPay", amountToPay);
        emit CalculateTokenPrice(amountToPay);
        return amountToPay;
    }

    // Sell tokens back to the marketplace
    function sellGLDToken(uint256 _amountOfToken) public {
        require(_amountOfToken > 0, "Amount of token greater than zero");
        require(
            Bees.balanceOf(msg.sender) >= _amountOfToken,
            "Insufficent Funds"
        );
        uint256 priceToPayUser = calculateTokenPrice(_amountOfToken);
        (bool success, ) = payable(msg.sender).call{value: priceToPayUser}("");
        require(success, "Transaction failed");
        Bees.safeTransferFrom(msg.sender,address(this),_amountOfToken);
        sellerCount += 1;
        emit TokenSold(msg.sender, _amountOfToken, priceToPayUser);
    }

    // Owner can withdraw excess tokens from the contract
    function withdrawTokens(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount of token greater than zero");
        require(Bees.balanceOf(address(this)) >= amount, "Out of balance");
        Bees.safeTransfer(msg.sender, amount);
        emit TokensWithdrawn(msg.sender, amount);
    }

    // Owner can withdraw accumulated Ether from the contract
    function withdrawEther(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount of token greater than zero");
        require(
            address(this).balance >= amount,
            "Contract doesn't have Enough Balance"
        );
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit EtherWithdrawn(msg.sender, amount);
    }

    function BalanceOfToken() public view returns (uint256) {
        uint256 balance = Bees.balanceOf(msg.sender);
        console.log(" Token Balance of Contract is : ", balance);
        return balance;
    }

    function BalanceOfEther() public view returns (uint256) {
        uint256 balance = address(this).balance;
        console.log("balance of ether", balance);
        return balance;
    }
}
