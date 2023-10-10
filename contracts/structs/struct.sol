 // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
 struct Order {
        address seller;
        address token;
        uint256 tokenId;
        uint256 price;
        bytes signature;
        uint256 deadline;
        bool isActive;
    }