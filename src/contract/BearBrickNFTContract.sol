// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IERC7765.sol";
import "../interfaces/IERC7765Metadata.sol";
import "../interfaces/IMetadataRenderer.sol";

contract BearBrickNFTContract is
    Initializable,
    ERC721Upgradeable,
    IERC7765,
    IERC7765Metadata,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    address public metadataRenderer;
    address public privilegeMetadataRenderer;

    address public constant PAYMENT_RECEIPIENT_ADDRESS =
        0x3De70dA882f101b4b3d5f3393c7f90e00E64edB9;
    address public constant POSTAGE_RECEIPIENT_ADDRESS =
        0xC565FC29F6df239Fe3848dB82656F2502286E97d;
    address public constant USDT_ADDRESS =
        0xED85184DC4BECf731358B2C63DE971856623e056;
    address public constant USDC_ADDRESS =
        0xBAfC2b82E53555ae74E1972f3F25D8a0Fc4C3682;

    uint256 public constant MINT_PRICE = 998 * 10 ** 6;

    uint256 public constant PRIVILEGE_ID = 1;

    uint256 public constant TOTAL_SUPPLY = 30;
    uint256[] private TOKEN_ID_ARR = [
        1,
        21,
        3,
        41,
        5,
        61,
        7,
        81,
        9,
        12,
        2,
        32,
        4,
        52,
        6,
        72,
        8,
        92,
        1,
        25,
        3,
        45,
        5,
        65,
        7,
        85,
        9,
        15,
        19,
        10
    ];
    uint256 private _nextTokenIndex;

    mapping(uint256 tokenId => address to) public tokenPrivilegeAddress;
    mapping(address to => uint256[] tokenIds) public addressPrivilegedUsedToken;
    mapping(uint256 tokenId => uint256 postage) public postageMessage;

    struct ExercisePrivilegeData {
        address _to;
        uint256 _tokenId;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __ERC721_init(unicode"BE@RBRICK-清明上河圖1000%", "BEARBRCIK_QM");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    modifier checkPrivilegeId(uint256 _privilegeId) {
        require(_privilegeId == PRIVILEGE_ID, "Invalid _privilegeId");
        _;
    }

    function mint(address payTokenAddress, uint256 amounts) external {
        address sender = _msgSender();
        require(
            payTokenAddress == USDT_ADDRESS || payTokenAddress == USDC_ADDRESS,
            "Only support USDT/USDC"
        );
        require(
            amounts > 0 && _nextTokenIndex + amounts <= TOTAL_SUPPLY,
            "Invalid amounts"
        );
        IERC20 erc20Token = IERC20(payTokenAddress);
        uint256 payPrice = MINT_PRICE * amounts;
        require(
            erc20Token.balanceOf(sender) >= payPrice,
            "Insufficient USD balance"
        );
        require(
            erc20Token.allowance(sender, address(this)) >= payPrice,
            "Allowance not set for USD"
        );

        erc20Token.safeTransferFrom(
            sender,
            PAYMENT_RECEIPIENT_ADDRESS,
            payPrice
        );

        for (uint256 i = 0; i < amounts; ) {
            _mint(sender, TOKEN_ID_ARR[_nextTokenIndex++]);
            unchecked {
                ++i;
            }
        }
    }

    function exercisePrivilege(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId,
        bytes calldata _data
    ) external override checkPrivilegeId(_privilegeId) {
        address tokenOwner = _requireOwned(_tokenId);
        address sender = _msgSender();

        (address payTokenAddress, uint256 postage) = abi.decode(
            _data,
            (address, uint256)
        );
        require(
            payTokenAddress == USDT_ADDRESS || payTokenAddress == USDC_ADDRESS,
            "Only support USDT/USDC"
        );

        require(
            sender == tokenOwner,
            "Invalid address: sender must be owner of tokenID"
        );
        require(
            _to == tokenOwner,
            "Invalid address: _to must be owner of _tokenId"
        );

        require(
            tokenPrivilegeAddress[_tokenId] == address(0),
            "The tokenID has been exercised"
        );

        if (postage > 0) {
            IERC20 erc20Token = IERC20(payTokenAddress);
            erc20Token.safeTransferFrom(
                sender,
                POSTAGE_RECEIPIENT_ADDRESS,
                postage
            );
            postageMessage[_tokenId] = postage;
        }

        tokenPrivilegeAddress[_tokenId] = _to;
        addressPrivilegedUsedToken[_to].push(_tokenId);

        emit PrivilegeExercised(sender, _to, _tokenId, _privilegeId);
    }

    function isExercisable(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    )
        external
        view
        override
        checkPrivilegeId(_privilegeId)
        returns (bool _exercisable)
    {
        address tokenOwner = _requireOwned(_tokenId);

        return
            _to == tokenOwner && tokenPrivilegeAddress[_tokenId] == address(0);
    }

    function isExercised(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    )
        external
        view
        override
        checkPrivilegeId(_privilegeId)
        returns (bool _exercised)
    {
        _requireOwned(_tokenId);

        return
            tokenPrivilegeAddress[_tokenId] != address(0) &&
            tokenPrivilegeAddress[_tokenId] == _to;
    }

    function hasBeenExercised(
        uint256 _tokenId,
        uint256 _privilegeId
    ) external view checkPrivilegeId(_privilegeId) returns (bool _exercised) {
        _requireOwned(_tokenId);

        return tokenPrivilegeAddress[_tokenId] != address(0);
    }

    function getPrivilegeIds(
        uint256 _tokenId
    ) external view returns (uint256[] memory privilegeIds) {
        _requireOwned(_tokenId);
        privilegeIds = new uint256[](1);
        privilegeIds[0] = PRIVILEGE_ID;
    }

    function setMetadataRenderer(address _metadataRenderer) external onlyOwner {
        require(_metadataRenderer != address(0), "Invalid address");
        metadataRenderer = _metadataRenderer;
    }
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _requireOwned(_tokenId);
        return IMetadataRenderer(metadataRenderer).tokenURI(_tokenId);
    }

    function setPrivilegeMetadataRenderer(
        address _privilegeMetadataRenderer
    ) external onlyOwner {
        require(_privilegeMetadataRenderer != address(0), "Invalid address");
        privilegeMetadataRenderer = _privilegeMetadataRenderer;
    }

    function privilegeURI(
        uint256 _privilegeId
    )
        external
        view
        override
        checkPrivilegeId(_privilegeId)
        returns (string memory)
    {
        return
            IERC7765Metadata(privilegeMetadataRenderer).privilegeURI(
                _privilegeId
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IERC7765).interfaceId ||
            interfaceId == type(IERC7765Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
