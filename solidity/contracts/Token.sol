// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract CustomToken is ERC20, ReentrancyGuard, Ownable, Pausable {
    // 状态变量
    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;    // 最小充值金额
    uint256 public constant DEPOSIT_RATE = 1000;            // 充值比率：1 ETH = 1000 token
    mapping(address => bool) public blacklist;              // 黑名单
    
    // 事件
    event Deposited(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event Withdrawn(address indexed user, uint256 tokenAmount, uint256 ethAmount);
    event BlacklistUpdated(address indexed user, bool status);

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {}

    // 充值 ETH 获取代币
    function deposit() external payable nonReentrant whenNotPaused {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit too small");
        require(!blacklist[msg.sender], "Address blacklisted");

        uint256 tokenAmount = msg.value * DEPOSIT_RATE;
        _mint(msg.sender, tokenAmount);
        
        emit Deposited(msg.sender, msg.value, tokenAmount);
    }

    // 销毁代币提取 ETH
    function withdraw(uint256 tokenAmount) external nonReentrant whenNotPaused {
        require(tokenAmount > 0, "Amount must be positive");
        require(!blacklist[msg.sender], "Address blacklisted");
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");

        uint256 ethAmount = tokenAmount / DEPOSIT_RATE;
        require(address(this).balance >= ethAmount, "Insufficient ETH in contract");

        _burn(msg.sender, tokenAmount);
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(msg.sender, tokenAmount, ethAmount);
    }

    // 管理员功能
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(!blacklist[to], "Address blacklisted");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        require(from != address(0), "Invalid address");
        _burn(from, amount);
    }

    function updateBlacklist(address user, bool status) external onlyOwner {
        blacklist[user] = status;
        emit BlacklistUpdated(user, status);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // 紧急提取合约中的 ETH（仅管理员）
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ETH transfer failed");
    }

    // 接收 ETH 的回退函数
    receive() external payable {}
}