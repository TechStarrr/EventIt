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
}
