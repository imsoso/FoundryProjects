// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { AutomationCompatibleInterface } from './AutomationCompatibleInterface.sol';

contract ETHBank is AutomationCompatibleInterface {
    address admin;

    mapping(address => uint) internal balances;

    // add interval control
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    error DepositCanotBeZero();

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

    // chainlink Automation checkUpkeep
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        bool timePassed = (block.timestamp - lastTimeStamp) > interval;

        uint256 threshold = 0.0001 ether;
        bool balanceReachThreshold = address(this).balance > threshold;
        upkeepNeeded = timePassed && balanceReachThreshold;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;

        uint256 amountToTransfer = address(this).balance / 2;

        (bool success, ) = admin.call{ value: amountToTransfer }('');
        require(success, 'Failed to transfer to admin');
    }
}
