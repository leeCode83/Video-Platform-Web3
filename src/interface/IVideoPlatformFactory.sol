// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IVideoPlatformFactory {
    function findValidVideoAddress(address _video) external  view returns (bool);
}