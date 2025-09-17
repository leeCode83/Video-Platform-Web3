// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {IVideoPlatformPayment} from "./interface/IVideoPlatformPayment.sol";

error UnauthorizedCall(address caller);
error EmptyFactoryAddress();
error EmptyPaymentAddress();
error EmptyOwnerAddress();
error EmptyStringError();
error ZeroValueError();

contract Video is ReentrancyGuard, Context {
    address public immutable owner;
    uint256 public immutable viewingFee;
    string public videoURI;
    address public immutable factoryAddress;
    IVideoPlatformPayment public immutable paymentAddress;

    uint256 public viewer = 0;

    event VideoWatched(address indexed viewer, address indexed video);

    constructor(
        address _owner,
        uint256 _viewingFee,
        string memory _videoURI,
        address _factoryAddress,
        address _paymentAddress
    ) ReentrancyGuard() {
        if(_owner == address(0)) revert EmptyOwnerAddress();
        if(_viewingFee == 0) revert ZeroValueError();
        if(bytes(_videoURI).length <= 0) revert EmptyStringError();
        if(_factoryAddress == address(0)) revert EmptyFactoryAddress();
        if(_paymentAddress == address(0)) revert EmptyPaymentAddress();

        owner = _owner;
        viewingFee = _viewingFee;
        videoURI = _videoURI;
        factoryAddress = _factoryAddress;
        paymentAddress = IVideoPlatformPayment(_paymentAddress);
    }

    function watchVideo() external nonReentrant returns (string memory) {
        // Panggil fungsi _payOwner untuk memproses pembayaran
        _payOwner();
        viewer++;

        emit VideoWatched(msg.sender, address(this));

        return videoURI;
    }

    function _payOwner() internal {
        paymentAddress.updateDeposit(msg.sender, viewingFee, owner);
    }
}
