// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { AutomationCompatibleInterface } from './AutomationCompatibleInterface.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';

contract ETHBank is AutomationCompatibleInterface {
    address admin;

    mapping(address => uint) internal balances;

    // add interval control
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    error DepositCanotBeZero();
    error AdminWithdrawOnly();

    constructor(address _admin, uint256 refreshInterval) {
        admin = _admin;

        interval = refreshInterval;
        lastTimeStamp = block.timestamp;
    }

    // Receive ETH
    receive() external payable {
        // Call deposit function
        deposit();
    }

    function deposit() public payable {
        // Revert if deposit amount is 0
        if (msg.value == 0) {
            revert DepositCanotBeZero();
        }
        balances[msg.sender] += msg.value;
    }
    function withdraw(uint256 amount) external {
        // Revert if caller is not admin
        if (msg.sender != admin) {
            revert AdminWithdrawOnly();
        }
        if (amount != 0) {
            Address.sendValue(payable(admin), amount);
        }
    }

    // chainlink Automation checkUpkeep
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        bool timePassed = (block.timestamp - lastTimeStamp) > interval;

        uint256 threshold = 0.0001 ether;
        bool balanceReachThreshold = address(this).balance > threshold;
        upkeepNeeded = timePassed && balanceReachThreshold;
    }

    function performUpkeep(bytes calldata) external override {
        lastTimeStamp = block.timestamp;

        uint256 amountToTransfer = address(this).balance / 2;
        Address.sendValue(payable(admin), amountToTransfer);
    }
}
