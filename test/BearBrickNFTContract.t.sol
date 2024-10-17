// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MockUSD.sol";
import "../src/contract/BearBrickNFTContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TestBearBrickNFTContract is Test {
    using SafeERC20 for IERC20;

    address constant SENDER_ADDRESS =
        0x3De70dA882f101b4b3d5f3393c7f90e00E64edB9;

    address constant SOME_ADDRESS = 0xC0f068774D46ba26013677b179934Efd7bdefA3F;
    address constant MULTIPLE_SIGNATURE_ADDRESS =
        0xC0f068774D46ba26013677b179934Efd7bdefA3F;

    address constant OWNER_ADDRESS = 0xC565FC29F6df239Fe3848dB82656F2502286E97d;
    address constant SINGER_ADDRESS =
        0xC565FC29F6df239Fe3848dB82656F2502286E97d;

    address constant usdtToken = 0xED85184DC4BECf731358B2C63DE971856623e056;
    uint256 constant mintPrice = 60 * 10 ** 6;
    MockUSD _usdtToken;
    MockUSD _usdcToken;

    address private proxy;
    BearBrickNFTContract private instance;

    function setUp() public {
        console.log("=======setUp============");

        proxy = Upgrades.deployUUPSProxy(
            "BearBrickNFTContract.sol",
            abi.encodeCall(BearBrickNFTContract.initialize, OWNER_ADDRESS)
        );

        console.log("uups proxy -> %s", proxy);

        instance = BearBrickNFTContract(proxy);
        assertEq(instance.owner(), OWNER_ADDRESS);

        address implAddressV1 = Upgrades.getImplementationAddress(proxy);

        console.log("impl proxy -> %s", implAddressV1);

        _usdtToken = new MockUSD("Mock USDT", "USDT");
        _usdcToken = new MockUSD("Mock USDC", "USDC");

        console.log("_usdtToken address -> %s", address(_usdtToken));
        console.log("_usdcToken address -> %s", address(_usdcToken));
        _usdtToken.transfer(SENDER_ADDRESS, mintPrice);
        _usdcToken.transfer(SENDER_ADDRESS, mintPrice);
    }
    function testSetConstantAddress_local() public {
        vm.startPrank(OWNER_ADDRESS);

        //Local test
        //move to ImKeyNFTContract
        // address public _usdtToken;
        // address public _usdcToken;
        // address public _moneyAddress;

        //      function setAddress(
        //     address usdtToken,
        //     address usdcToken,
        //     address moneyAddress
        // ) external onlyOwner {
        //     _usdtToken = usdtToken;
        //     _usdcToken = usdcToken;
        //     _moneyAddress = moneyAddress;
        // }

        // instance.setAddress(
        //     address(_usdtToken),
        //     address(_usdcToken),
        //     SOME_ADDRESS
        // );
        vm.stopPrank();
    }
    function testMint() public {
    }
}
