//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
/**
    Collects Fees And Distributes To Listed Projects' Paths
 */
contract FeeCollector {

    struct ListedProject {
        uint256 amountToDistribute;
        uint256 swapFee;
        address caller;
    }
    mapping ( address => ListedProject ) public listedProject;
    uint256 public FEE_DENOMINATOR;

    function getFeeForProject(address project) external view returns (uint256) {
        return listedProject[project].swapFee;
    }

    function listProject(address project, address caller, uint256 swapFee_) external onlyOwner {
        listedProject[project].caller = caller;
        listedProject[project].swapFee = swapFee_;
    }

    function registerFee(address project) external payable {
        listedProject[project].amountToDistribute += msg.value;
    }

    function distributeFee(address[] calldata destinations, uint256[] calldata percentages) external {
        require(
            destinations.length == percentages.length,
            'Invalid Length'
        );
        uint amount = listedProject[msg.sender].amountToDistribute;
        require(
            amount > 0,
            'Zero Amount To Distribute'
        );

        uint total = 0;
        for (uint i = 0; i < percentages.length; i++) {
            total += percentages[i];
        }

        for (uint i = 0; i < destinations.length; i++) {
            _send(destinations[i], (( percentages[i] * amount ) / total) - 1);
        }
    }

    function _send(address project, address to, uint256 amount) internal {
        listedProject[project].amountToDistribute = listedProject[project].amountToDistribute.sub(amount, 'Underflow');
        (bool s,) = payable(to).transfer(amount);
    }

    receive() external payable {
        payable(getOwner()).transfer(msg.value);
    }
}