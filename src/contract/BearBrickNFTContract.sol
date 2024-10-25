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
        0x6414Cf36cb225c333C670b32f41578397843E9b1;
    address public constant POSTAGE_RECEIPIENT_ADDRESS =
        0xC34f5933785B6cAB6bE046649D6702358323Bc2A;
    address public constant USDT_ADDRESS =
        0x05D032ac25d322df992303dCa074EE7392C117b9;
    address public constant USDC_ADDRESS =
        0xb62F35B9546A908d11c5803ecBBA735AbC3E3eaE;

    uint256 public constant MINT_PRICE = 988 * 10 ** 6;

    uint256 public constant PRIVILEGE_ID = 1;

    uint256 public constant TOTAL_SUPPLY = 30;
    uint256[] private TOKEN_ID_ARR;
    uint256 private _nextTokenIndex;

    mapping(address => bool) public mintedAddress;
    mapping(uint256 tokenId => address to) public tokenPrivilegeAddress;
    mapping(address to => uint256[] tokenIds) public addressPrivilegedUsedToken;
    mapping(uint256 tokenId => uint256 postage) public postageMessage;

    mapping(address => bool) public whitelist;

    mapping(address => bool) public wlMinted;
    bool public saleStatus;

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

        TOKEN_ID_ARR = [
            12,
            21,
            26,
            70,
            78,
            80,
            118,
            148,
            298,
            328,
            65,
            96,
            87,
            79,
            72,
            131,
            192,
            147,
            167,
            126,
            289,
            259,
            216,
            211,
            206,
            357,
            337,
            325,
            314,
            310
        ];
    }

    modifier checkPrivilegeId(uint256 _privilegeId) {
        require(_privilegeId == PRIVILEGE_ID, "Invalid _privilegeId");
        _;
    }
    function updateSaleStatus(bool _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }
    function mint(address payTokenAddress) external {
        require(saleStatus == true, "Not yet available for sale");

        address sender = _msgSender();

        require(
            whitelist[sender] == true,
            "Invalid address: Only white address can be mint"
        );
        require(
            wlMinted[sender] == false,
            "Invalid address: An address can only be mint once"
        );

        require(
            payTokenAddress == USDT_ADDRESS || payTokenAddress == USDC_ADDRESS,
            "Only support USDT/USDC"
        );
        require(_nextTokenIndex < TOTAL_SUPPLY, "Exceed maximum limit");
        IERC20 erc20Token = IERC20(payTokenAddress);
        require(
            erc20Token.balanceOf(sender) >= MINT_PRICE,
            "Insufficient USD balance"
        );
        require(
            erc20Token.allowance(sender, address(this)) >= MINT_PRICE,
            "Allowance not set for USD"
        );

        erc20Token.safeTransferFrom(
            sender,
            PAYMENT_RECEIPIENT_ADDRESS,
            MINT_PRICE
        );
        wlMinted[sender] = true;
        _mint(sender, TOKEN_ID_ARR[_nextTokenIndex++]);
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

    function addWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
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
