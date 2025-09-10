// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IVideoPlatformPayment {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function updateDeposit(address _viewer, uint256 _amount, address _videoOwner) external;
}