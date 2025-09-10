// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {IVideoPlatformPayment} from "./interface/IVideoPlatformPayment.sol";

error UnauthorizedCall(address caller);

contract Video is ReentrancyGuard, Context {
    address public immutable owner;
    uint256 public immutable viewingFee;
    string public videoURI;
    address public immutable factoryAddress;
    IVideoPlatformPayment public immutable paymentAddress;

    event VideoWatched(address indexed viewer, address indexed video);

    constructor(
        address _owner,
        uint256 _viewingFee,
        string memory _videoURI,
        address _factoryAddress,
        address _paymentAddress
    ) ReentrancyGuard() {
        require(_owner != address(0), "Alamat pemilik tidak boleh nol.");
        require(_viewingFee > 0, "Biaya menonton harus lebih besar dari nol.");
        require(bytes(_videoURI).length > 0, "URI video tidak boleh kosong.");
        require(
            _factoryAddress != address(0),
            "Alamat pabrik tidak boleh nol."
        );
        require(
            _paymentAddress != address(0),
            "Alamat pembayaran tidak boleh nol."
        );

        owner = _owner;
        viewingFee = _viewingFee;
        videoURI = _videoURI;
        factoryAddress = _factoryAddress;
        paymentAddress = IVideoPlatformPayment(_paymentAddress);
    }

    function watchVideo() external nonReentrant returns (string memory) {
        // Panggil fungsi _payOwner untuk memproses pembayaran
        _payOwner();

        emit VideoWatched(msg.sender, address(this));

        return videoURI;
    }

    function _payOwner() internal {
        paymentAddress.updateDeposit(msg.sender, viewingFee, owner);
    }
}
