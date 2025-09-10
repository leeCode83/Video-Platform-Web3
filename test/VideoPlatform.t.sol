// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {VideoPlatformFactory} from "../src/VideoPlatformFactory.sol";
import {VideoPlatformPayment} from "../src/VideoPlatformPayment.sol";
import {Video} from "../src/Video.sol";
import {WUSDT} from "../src/WUSDT.sol";
import {InsufficientGas} from "../src/VideoPlatformFactory.sol";
import {UnauthorizedCall, InsufficientBalance} from "../src/VideoPlatformPayment.sol";

contract VideoPlatformTest is Test {
    VideoPlatformFactory public factory;
    VideoPlatformPayment public payment;
    WUSDT public usdt;

    address public deployer;
    address public creator1;
    address public creator2;
    address public viewer1;

    // Menentukan konstanta untuk biaya dan jumlah token
    uint256 public constant VIDEO_CREATION_FEE = 0.01 ether;
    uint256 public constant MINT_AMOUNT = 1000 * 10 ** 6;
    uint256 public constant VIEWING_FEE = 10 * 10 ** 6;

    // Fungsi `setUp` akan dijalankan sebelum setiap tes
    function setUp() public {
        deployer = makeAddr("deployer");
        creator1 = makeAddr("creator1");
        creator2 = makeAddr("creator2");
        viewer1 = makeAddr("viewer1");

        // Deploy kontrak WUSDT (token ERC20)
        usdt = new WUSDT();
        // Mint sejumlah token ke akun creator dan viewer untuk pengujian
        usdt.mint(creator1, MINT_AMOUNT);
        usdt.mint(viewer1, MINT_AMOUNT);

        // Deploy kontrak VideoPlatformFactory
        factory = new VideoPlatformFactory(
            address(usdt),
            VIDEO_CREATION_FEE
        );
        // Dapatkan alamat kontrak pembayaran dari factory
        payment = VideoPlatformPayment(factory.videoPayment());
    }

    // Menguji apakah fungsi minting WUSDT berfungsi dengan benar
    function test_WUSDTMinting() public view {
        assertEq(usdt.balanceOf(creator1), MINT_AMOUNT);
        assertEq(usdt.balanceOf(viewer1), MINT_AMOUNT);
    }

    // Menguji fungsionalitas deposit pada kontrak VideoPlatformPayment
    function test_VideoPlatformPaymentDeposit() public {
        // Beri izin (approve) kontrak pembayaran untuk memindahkan dana viewer
        vm.prank(viewer1);
        usdt.approve(address(payment), MINT_AMOUNT);

        // Deposit sejumlah dana
        vm.prank(viewer1);
        payment.deposit(100 * 10 ** 6);

        // Verifikasi saldo deposit internal dan saldo token di kontrak
        assertEq(payment.deposits(viewer1), 100 * 10 ** 6);
        assertEq(usdt.balanceOf(address(payment)), 100 * 10 ** 6);
    }

    // Menguji fungsionalitas penarikan (withdraw) dari kontrak VideoPlatformPayment
    function test_VideoPlatformPaymentWithdraw() public {
        // Siapkan deposit untuk penarikan
        vm.prank(viewer1);
        usdt.approve(address(payment), 200 * 10 ** 6);

        vm.prank(viewer1);
        payment.deposit(200 * 10 ** 6);

        uint256 initialUSDTBalance = usdt.balanceOf(viewer1);

        // Lakukan penarikan
        vm.prank(viewer1);
        payment.withdraw(50 * 10 ** 6);

        // Verifikasi saldo deposit dan saldo token setelah penarikan
        assertEq(payment.deposits(viewer1), 150 * 10 ** 6);
        assertEq(usdt.balanceOf(viewer1), initialUSDTBalance + 50 * 10 ** 6);
    }

    // Menguji pembuatan kontrak video baru melalui VideoPlatformFactory
    function test_VideoPlatformFactoryCreateVideo() public {
        uint256 initialFactoryETHBalance = address(factory).balance;
        
        // creator1 membuat kontrak video
        vm.prank(creator1);
        factory.createVideoContract{value: VIDEO_CREATION_FEE}(
            VIEWING_FEE,
            "ipfs://video1"
        );

        // Periksa bahwa biaya pembuatan dibayarkan ke factory
        assertEq(address(factory).balance, initialFactoryETHBalance + VIDEO_CREATION_FEE);

        // Verifikasi array `deployedVideos` dan `userVideos`
        assertEq(factory.deployedVideos(0), factory.userVideos(creator1, 0));
        assertEq(factory.userVideos(creator1, 0) != address(0), true);
    }

    // Menguji skenario menonton video dan pembayaran biaya menonton
    function test_WatchVideoAndPay() public {
        // Siapkan viewer dengan deposit yang cukup
        vm.prank(viewer1);
        usdt.approve(address(payment), VIEWING_FEE);
        vm.prank(viewer1);
        payment.deposit(VIEWING_FEE);
        
        // Periksa saldo deposit awal
        assertEq(payment.deposits(viewer1), VIEWING_FEE);
        assertEq(payment.deposits(creator1), 0);

        // Creator1 membuat video baru
        vm.prank(creator1);
        factory.createVideoContract{value: VIDEO_CREATION_FEE}(
            VIEWING_FEE,
            "ipfs://video1"
        );
        address newVideoAddress = factory.userVideos(creator1, 0);
        Video videoContract = Video(newVideoAddress);

        // Viewer menonton video (melakukan pembayaran)
        vm.prank(viewer1);
        videoContract.watchVideo();

        // Verifikasi saldo deposit setelah pembayaran
        assertEq(payment.deposits(viewer1), 0);
        assertEq(payment.deposits(creator1), VIEWING_FEE);
    }

    // Menguji skenario kegagalan karena gas tidak mencukupi
    function test_RevertInsufficientGas() public {
        vm.prank(creator2);
        vm.expectRevert(
            InsufficientGas.selector
        );
        factory.createVideoContract{value: 0}(
            VIEWING_FEE,
            "ipfs://video2"
        );
    }

    // Menguji skenario kegagalan karena saldo deposit tidak mencukupi
    function test_RevertInsufficientBalance() public {
        vm.prank(viewer1);
        usdt.approve(address(payment), 10 * 10 ** 6);

        // Deposit sejumlah 10, tetapi coba tarik sejumlah 20
        vm.prank(viewer1);
        payment.deposit(10 * 10 ** 6);

        vm.prank(viewer1);
        vm.expectRevert(
            InsufficientBalance.selector
        );
        payment.withdraw(20 * 10 ** 6);
    }

    // Menguji skenario kegagalan karena panggilan tidak sah (bukan dari factory)
    function test_RevertUnauthorizedCall() public {
        // Siapkan deposit untuk viewer
        vm.prank(viewer1);
        usdt.approve(address(payment), VIEWING_FEE);
        vm.prank(viewer1);
        payment.deposit(VIEWING_FEE);

        // Coba panggil `updateDeposit` dari akun yang bukan factory
        vm.prank(creator1);
        vm.expectRevert(UnauthorizedCall.selector);
        payment.updateDeposit(viewer1, VIEWING_FEE, creator1);
    }
}