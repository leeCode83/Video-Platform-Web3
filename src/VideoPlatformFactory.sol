// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Video} from "./Video.sol";

/**
 * @title VideoPlatformFactory
 * @dev Kontrak pabrik untuk mengelola deposit token dan membuat kontrak video baru.
 */
contract VideoPlatformFactory is Ownable, ReentrancyGuard {
    IERC20 public immutable token;
    mapping(address => uint256) public deposits;
    address[] public deployedVideos;

    // Tambahan: mapping untuk melacak video yang dimiliki setiap pengguna
    mapping(address => address[]) public userVideos;

    event VideoContractCreated(
        address indexed newVideoContract,
        address indexed owner,
        uint256 viewingFee,
        string videoURI
    );
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OwnerPaid(
        address indexed viewer,
        address indexed videoOwner,
        uint256 amount
    );

    constructor(address _tokenAddress) Ownable(msg.sender) ReentrancyGuard() {
        require(_tokenAddress != address(0), "Alamat token tidak boleh nol.");
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Jumlah deposit harus lebih besar dari nol.");
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Gagal mentransfer token dari pengirim.");
        deposits[msg.sender] += _amount;
        emit Deposited(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Jumlah penarikan harus lebih besar dari nol.");
        require(deposits[msg.sender] >= _amount, "Saldo tidak cukup.");
        deposits[msg.sender] -= _amount;
        bool success = token.transfer(msg.sender, _amount);
        require(success, "Gagal mentransfer token ke pengirim.");
        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Fungsi yang dapat dipanggil oleh kontrak Video untuk memproses pembayaran.
     * @param _viewer Alamat penonton.
     * @param _videoOwner Alamat pemilik video.
     * @param _amount Jumlah token yang akan ditransfer.
     */
    function payOwner(
        address _viewer,
        address _videoOwner,
        uint256 _amount
    ) public nonReentrant {
        // Memastikan yang memanggil fungsi ini adalah kontrak video yang valid
        bool isDeployedVideo = false;
        for (uint i = 0; i < deployedVideos.length; i++) {
            if (deployedVideos[i] == msg.sender) {
                isDeployedVideo = true;
                break;
            }
        }
        require(
            isDeployedVideo,
            "Hanya kontrak video yang terdaftar yang bisa memanggil fungsi ini."
        );

        require(deposits[_viewer] >= _amount, "Saldo penonton tidak cukup.");
        deposits[_viewer] -= _amount;
        deposits[_videoOwner] += _amount;

        emit OwnerPaid(_viewer, _videoOwner, _amount);
    }

    function createVideoContract(
        uint256 _viewingFee,
        string memory _videoURI
    ) public nonReentrant {
        require(_viewingFee > 0, "Biaya menonton harus lebih besar dari nol.");
        require(bytes(_videoURI).length > 0, "URI video tidak boleh kosong.");

        Video newVideo = new Video(
            msg.sender,
            _viewingFee,
            _videoURI,
            address(this),
            address(token)
        );

        deployedVideos.push(address(newVideo));
        userVideos[msg.sender].push(address(newVideo));

        emit VideoContractCreated(
            address(newVideo),
            msg.sender,
            _viewingFee,
            _videoURI
        );
    }
}
