// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReentrancyGuard}from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Context} from"../lib/openzeppelin-contracts/contracts/utils/Context.sol";

/**
 * @title Video
 * @dev Kontrak untuk satu video. Mengelola kepemilikan dan logika pembayaran.
 */
contract Video is ReentrancyGuard, Context {
    // Alamat pemilik video
    address public immutable owner;
    
    // Biaya yang harus dibayar untuk menonton video ini
    uint256 public immutable viewingFee;
    
    // Link atau URI tempat video disimpan (di luar blockchain)
    string public  videoURI;
    
    // Alamat kontrak pabrik untuk berinteraksi dengan deposit
    address public immutable factoryAddress;

    // Interface untuk kontrak token
    IERC20 public immutable token;
    
    // Event yang dipicu saat video ditonton
    event VideoWatched(address indexed viewer);
    
    /**
     * @dev Konstruktor untuk menginisialisasi kontrak video.
     * @param _owner Alamat pemilik video.
     * @param _viewingFee Biaya untuk menonton video.
     * @param _videoURI Link video.
     * @param _factoryAddress Alamat kontrak VideoPlatformFactory.
     * @param _tokenAddress Alamat kontrak token ERC20.
     */
    constructor(
        address _owner,
        uint256 _viewingFee,
        string memory _videoURI,
        address _factoryAddress,
        address _tokenAddress
    ) ReentrancyGuard() {
        require(_owner != address(0), "Alamat pemilik tidak boleh nol.");
        require(_viewingFee > 0, "Biaya menonton harus lebih besar dari nol.");
        require(bytes(_videoURI).length > 0, "URI video tidak boleh kosong.");
        require(_factoryAddress != address(0), "Alamat pabrik tidak boleh nol.");
        require(_tokenAddress != address(0), "Alamat token tidak boleh nol.");

        owner = _owner;
        viewingFee = _viewingFee;
        videoURI = _videoURI;
        factoryAddress = _factoryAddress;
        token = IERC20(_tokenAddress);
    }
    
    /**
     * @dev Fungsi untuk "menonton" video. Mengonsumsi token dari deposit pengguna
     * dan mengirimkannya ke pemilik video.
     * @return videoURI Link video yang bisa diakses di luar rantai.
     */
    function watchVideo() public nonReentrant returns (string memory) {
        // Mendapatkan saldo deposit pengguna dari kontrak pabrik
        // Note: Kita harus menggunakan `abi.encodeWithSignature` untuk memanggil fungsi `deposits` 
        // yang bersifat `public` dari kontrak lain.
        // Cara yang lebih aman dan terstruktur adalah dengan membuat fungsi `view` 
        // di factory untuk membaca saldo. Mari kita tambahkan itu di factory.
        
        // Contoh di bawah ini mengasumsikan ada fungsi `getUserDeposit` di factory
        // yang bisa kita panggil.
        
        // (Asumsi) Mengambil saldo pengguna dari kontrak VideoPlatformFactory
        uint256 userDeposit = _getUserDeposit(msg.sender);

        require(userDeposit >= viewingFee, "Saldo deposit tidak cukup untuk menonton video ini.");
        
        // Transfer biaya dari penonton ke pemilik video
        // Perhatikan bahwa transfer ini dilakukan melalui token, dan kontrak pabrik
        // akan mengelola saldo internalnya.
        // Kita perlu memanggil fungsi di kontrak pabrik untuk melakukan transfer saldo internal.
        _payOwner();
        
        emit VideoWatched(msg.sender);
        
        return videoURI;
    }

    /**
     * @dev Fungsi internal untuk memanggil fungsi di kontrak pabrik guna
     * mengurangi saldo penonton dan menambahkannya ke pemilik video.
     */
    function _payOwner() internal {
        (bool success, ) = factoryAddress.call(
            abi.encodeWithSignature("payOwner(address,address,uint256)", _msgSender(), owner, viewingFee)
        );
        require(success, "Pembayaran ke pemilik video gagal.");
    }

    /**
     * @dev Fungsi internal untuk memanggil fungsi di kontrak pabrik guna
     * mendapatkan saldo deposit pengguna.
     */
    function _getUserDeposit(address _user) internal view returns (uint256) {
        (bool success, bytes memory result) = factoryAddress.staticcall(
            abi.encodeWithSignature("deposits(address)", _user)
        );
        require(success, "Gagal mendapatkan saldo deposit dari pabrik.");
        
        // Decode hasil untuk mendapatkan saldo
        return abi.decode(result, (uint256));
    }
}