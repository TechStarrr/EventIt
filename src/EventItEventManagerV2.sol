// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {EventItEventManager} from "./EventItEventManager.sol";

contract EventItEventManagerV2 is EventItEventManager {
    mapping(uint256 eventId => string) public venueName;
}
