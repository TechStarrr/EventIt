// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {EventItTicket} from "./EventItTicket.sol";

contract EventItEventManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    struct EventData {
        address creator;
        uint96 price;
        uint32 maxSupply;
        uint32 minted;
        uint64 startTime;
        uint64 endTime;
        bool paused;
        bool soulbound;
        string metadataURI;
    }

    EventItTicket public ticket;
    uint256 public nextEventId;
    mapping(uint256 eventId => EventData) public events;
    mapping(uint256 eventId => uint256) public balances;

    event EventCreated(uint256 indexed eventId, address indexed creator);
    event EventPaused(uint256 indexed eventId, bool paused);
    event EventMetadataUpdated(uint256 indexed eventId, string metadataURI);
    event TicketPurchased(
        uint256 indexed eventId,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );
    event Withdrawal(uint256 indexed eventId, address indexed to, uint256 amount);

    modifier onlyCreator(uint256 eventId) {
        require(events[eventId].creator == msg.sender, "EventIt: not creator");
        _;
    }

    function initialize(address ticket_) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        ticket = EventItTicket(ticket_);
        nextEventId = 1;
    }

    function createEvent(
        uint96 price,
        uint32 maxSupply,
        uint64 startTime,
        uint64 endTime,
        bool soulbound,
        string calldata metadataURI
    ) external returns (uint256 eventId) {
        require(maxSupply > 0, "EventIt: supply 0");
        require(endTime > startTime, "EventIt: invalid time");

        eventId = nextEventId++;
        events[eventId] = EventData({
            creator: msg.sender,
            price: price,
            maxSupply: maxSupply,
            minted: 0,
            startTime: startTime,
            endTime: endTime,
            paused: false,
            soulbound: soulbound,
            metadataURI: metadataURI
        });

        if (soulbound) {
            ticket.setSoulbound(eventId, true);
        }

        emit EventCreated(eventId, msg.sender);
    }
}
