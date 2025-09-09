// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

error InsufficientBalance(address sender, uint256 available, uint256 require);
error UnauthorizedCall(address caller);

contract VideoPlatformPayment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    mapping(address => uint256) public deposits;
    address public immutable videoFactory;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OwnerPaid(address indexed viewer, uint256 amount);

    constructor(
        address _tokenAddress,
        address _videoFactory
    ) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Alamat token tidak boleh nol.");
        require(
            _videoFactory != address(0),
            "Alamat pabrik video tidak boleh nol."
        );
        token = IERC20(_tokenAddress);
        videoFactory = _videoFactory;
    }

    modifier onlyFactory() {
        if (msg.sender != videoFactory) {
            revert UnauthorizedCall(msg.sender);
        }
        _;
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Jumlah deposit harus lebih besar dari nol.");
        uint256 approveAmount = token.allowance(msg.sender, address(this));

        if (approveAmount < _amount)
            revert InsufficientBalance(msg.sender, approveAmount, _amount);

        deposits[msg.sender] += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Jumlah penarikan harus lebih besar dari nol.");
        if (deposits[msg.sender] < _amount)
            revert InsufficientBalance(
                msg.sender,
                deposits[msg.sender],
                _amount
            );

        deposits[msg.sender] -= _amount;
        token.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    function updateDeposit(
        address _viewer,
        uint256 _amount,
        address _videoOwner
    ) external onlyFactory nonReentrant {
        if (deposits[_viewer] < _amount)
            revert InsufficientBalance(_viewer, deposits[_viewer], _amount);

        deposits[_viewer] -= _amount;
        deposits[_videoOwner] += _amount;

        emit OwnerPaid(_viewer, _amount);
    }
}
