// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract EventItTicket is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address public eventManager;
    address public checkIn;
    uint256 private _nextTokenId;

    mapping(uint256 tokenId => uint256 eventId) private _tokenEvent;
    mapping(uint256 eventId => bool) public soulbound;

    event TicketMinted(uint256 indexed eventId, uint256 indexed tokenId, address indexed owner);
    event TicketBurned(uint256 indexed eventId, uint256 indexed tokenId);
    event EventManagerUpdated(address indexed eventManager);
    event CheckInUpdated(address indexed checkIn);
    event SoulboundSet(uint256 indexed eventId, bool enabled);

    modifier onlyEventManager() {
        require(msg.sender == eventManager, "EventItTicket: not manager");
        _;
    }

    modifier onlyMinterOrBurner() {
        require(msg.sender == eventManager || msg.sender == checkIn, "EventItTicket: not authorized");
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address eventManager_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        eventManager = eventManager_;
        _nextTokenId = 1;
        emit EventManagerUpdated(eventManager_);
    }

    function setEventManager(address eventManager_) external onlyOwner {
        eventManager = eventManager_;
        emit EventManagerUpdated(eventManager_);
    }

    function setCheckIn(address checkIn_) external onlyOwner {
        checkIn = checkIn_;
        emit CheckInUpdated(checkIn_);
    }

    function setSoulbound(uint256 eventId, bool enabled) external onlyEventManager {
        soulbound[eventId] = enabled;
        emit SoulboundSet(eventId, enabled);
    }

    function eventOf(uint256 tokenId) external view returns (uint256) {
        return _tokenEvent[tokenId];
    }

    function mintTicket(
        address to,
        uint256 eventId,
        string calldata tokenURI_
    ) external onlyEventManager returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _tokenEvent[tokenId] = eventId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        emit TicketMinted(eventId, tokenId, to);
    }

    function burn(uint256 tokenId) external onlyMinterOrBurner {
        uint256 eventId = _tokenEvent[tokenId];
        _burn(tokenId);
        emit TicketBurned(eventId, tokenId);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable) returns (address from) {
        from = super._update(to, tokenId, auth);
        if (from != address(0) && to != address(0)) {
            uint256 eventId = _tokenEvent[tokenId];
            require(!soulbound[eventId], "EventItTicket: soulbound");
        }
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
        delete _tokenEvent[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
