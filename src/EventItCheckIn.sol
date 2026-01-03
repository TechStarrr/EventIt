// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {EventItTicket} from "./EventItTicket.sol";
import {EventItEventManager} from "./EventItEventManager.sol";

contract EventItCheckIn is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    EventItTicket public ticket;
    EventItEventManager public manager;

    mapping(uint256 eventId => mapping(uint256 tokenId => bool)) public usedTickets;
    mapping(uint256 eventId => mapping(address operator => bool)) public operators;

    event CheckedIn(
        uint256 indexed eventId,
        uint256 indexed tokenId,
        address indexed operator,
        bool burnAfter
    );
    event OperatorSet(uint256 indexed eventId, address indexed operator, bool allowed);

    modifier onlyOperator(uint256 eventId) {
        address creator = manager.events(eventId).creator;
        require(
            msg.sender == creator || operators[eventId][msg.sender],
            "EventItCheckIn: not operator"
        );
        _;
    }

    function initialize(address ticket_, address manager_) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        ticket = EventItTicket(ticket_);
        manager = EventItEventManager(manager_);
    }

    function setOperator(uint256 eventId, address operator, bool allowed)
        external
        onlyOperator(eventId)
    {
        operators[eventId][operator] = allowed;
        emit OperatorSet(eventId, operator, allowed);
    }

    function checkIn(uint256 eventId, uint256 tokenId, bool burnAfter)
        external
        onlyOperator(eventId)
    {
        require(!usedTickets[eventId][tokenId], "EventItCheckIn: used");
        require(ticket.ownerOf(tokenId) != address(0), "EventItCheckIn: missing");
        require(ticket.eventOf(tokenId) == eventId, "EventItCheckIn: wrong event");

        usedTickets[eventId][tokenId] = true;

        if (burnAfter) {
            ticket.burn(tokenId);
        }

        emit CheckedIn(eventId, tokenId, msg.sender, burnAfter);
    }
}
