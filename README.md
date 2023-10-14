# ERC721 Marketplace Contract

This is a Solidity smart contract for an ERC721 marketplace. It allows users to create and execute orders for ERC721 tokens, facilitating the exchange of these tokens for a specified price.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Contract Overview](#contract-overview)
- [Error Handling](#error-handling)
- [Functions](#functions)
  - [createOrder](#createorder)
  - [executeOrder](#executeorder)

## Prerequisites
- This contract is developed using Solidity version 0.8.19.
- It relies on various libraries and structs, including `ERC721Facet`, `SignUtils`, and `LibDiamond`.

## Contract Overview
The ERC721 marketplace contract enables users to create and execute orders for ERC721 tokens. Users can create an order specifying the token to be sold, the price, a deadline, and a cryptographic signature. Once created, the order can be executed by another user who pays the specified price, and the ERC721 token is transferred to the buyer, while the payment goes to the seller.

## Error Handling
The contract includes several custom error types to handle different scenarios:
- `NotOwner`: Thrown when the order creator does not own the specified ERC721 token.
- `DeadlinePassed`: Thrown when the deadline for executing an order has passed.
- `InvalidPrice`: Thrown when the specified price in the order is less than 0.01 ether.
- `InvalidSignature`: Thrown when the order's cryptographic signature is invalid.
- `OrderExpired`: Thrown when an order has passed its deadline and cannot be executed.
- `IncorrectPrice`: Thrown when the value sent with an execution request does not match the order price.
- `NotApproved`: Thrown when the contract is not approved to operate on the seller's ERC721 token.
- `InactiveOrder`: Thrown when trying to execute an order that is not active.

## Functions

### createOrder
```solidity
function createOrder(Order calldata order) external returns (uint256 orderId)
```
Creates a new order for an ERC721 token.

- `order`: An order struct specifying the seller, ERC721 token address, token ID, price, deadline, signature, and whether the order is active.
- Returns the unique order ID.

### executeOrder
```solidity
function executeOrder(uint256 orderId) external payable
```
Executes an existing order by transferring the specified amount of Ether and the corresponding ERC721 token to the buyer.

- `orderId`: The unique ID of the order to be executed.
- Requires the specified price to be sent with the execution request.

---
Please ensure that you have the required libraries and structs referenced correctly to use this contract. Additionally, make sure to handle the error scenarios described in the contract for a secure and reliable marketplace operation.
