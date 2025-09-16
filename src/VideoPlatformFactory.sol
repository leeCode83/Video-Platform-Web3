// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Video} from "./Video.sol";
import {VideoPlatformPayment} from "./VideoPlatformPayment.sol";

error InsufficientGas(address sender, uint256 send, uint256 require);
error InvalidVideoAddress(address video);

contract VideoPlatformFactory is Ownable, ReentrancyGuard {
    mapping(address => address[]) public userVideos;
    mapping(address => bool) public isValidVideoContract;
    uint256 public videoCreationFee;
    address public immutable videoPayment;

    event VideoContractCreated(
        address indexed newVideoContract,
        address indexed owner,
        uint256 viewingFee,
        string videoURI
    );

    constructor(address _tokenAddress) Ownable(msg.sender) ReentrancyGuard() {
        require(_tokenAddress != address(0), "Alamat token tidak boleh nol.");
        videoPayment = address(
            new VideoPlatformPayment(_tokenAddress, address(this))
        );
    }

    function createVideoContract(
        uint256 _viewingFee,
        string memory _videoURI
    ) public nonReentrant returns (address) {
        require(_viewingFee > 0, "Biaya menonton harus lebih besar dari nol.");
        require(bytes(_videoURI).length > 0, "URI video tidak boleh kosong.");

        Video newVideo = new Video(
            msg.sender,
            _viewingFee,
            _videoURI,
            address(this),
            videoPayment
        );

        userVideos[msg.sender].push(address(newVideo));
        isValidVideoContract[address(newVideo)] = true;

        emit VideoContractCreated(
            address(newVideo),
            msg.sender,
            _viewingFee,
            _videoURI
        );

        return address(newVideo);
    }

    function findValidVideoAddress(address _video) public view returns (bool) {
        if (!isValidVideoContract[_video]) return false;

        return true;
    }
}
