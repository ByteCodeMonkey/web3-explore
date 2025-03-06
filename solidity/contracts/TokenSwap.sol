// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is ReentrancyGuard, Ownable {
    // 状态变量
    uint256 public constant PRECISION = 1e18;  // 精度控制
    uint256 public swapFee;                    // 交易手续费（基点：1/10000）
    uint256 public rate;                       // 交易对的汇率
    IERC20 public immutable tokenA;           // 使用 immutable 优化 gas
    IERC20 public immutable tokenB;
    
    // 事件优化：indexed 参数便于查询
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event FeeUpdated(uint256 newFee);
    event RateUpdated(uint256 newRate);

    constructor(
        address _tokenA,
        address _tokenB,
        uint256 _rate,
        uint256 _swapFee
    ) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid tokens");
        require(_rate > 0, "Invalid rate");
        require(_swapFee <= 1000, "Fee too high"); // 最大 10% 手续费
        
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rate = _rate;
        swapFee = _swapFee;
    }

    // 内部函数：计算手续费
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        return (amount * swapFee) / 10000;
    }

    // 内部函数：执行代币交换
    function _executeSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        bool isAToB
    ) internal returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");
        
        // 计算输出金额
        amountOut = isAToB 
            ? (amountIn * rate) / PRECISION
            : (amountIn * PRECISION) / rate;
            
        require(amountOut > 0, "Output amount too small");
        
        // 扣除手续费
        uint256 fee = _calculateFee(amountOut);
        amountOut -= fee;
        
        // 检查合约余额
        require(
            tokenOut.balanceOf(address(this)) >= amountOut,
            "Insufficient liquidity"
        );

        // 执行转账
        require(
            tokenIn.transferFrom(msg.sender, address(this), amountIn),
            "TransferFrom failed"
        );
        require(tokenOut.transfer(msg.sender, amountOut), "Transfer failed");

        emit SwapExecuted(
            msg.sender,
            address(tokenIn),
            address(tokenOut),
            amountIn,
            amountOut
        );
    }

    // 公开的交换函数
    function swapAToB(uint256 amountA) external nonReentrant {
        _executeSwap(tokenA, tokenB, amountA, true);
    }

    function swapBToA(uint256 amountB) external nonReentrant {
        _executeSwap(tokenB, tokenA, amountB, false);
    }

    // 管理员功能
    function updateRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Invalid rate");
        rate = _newRate;
        emit RateUpdated(_newRate);
    }

    function updateFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee too high"); // 最大 10%
        swapFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }
} 