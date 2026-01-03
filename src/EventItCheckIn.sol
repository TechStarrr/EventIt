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
}
