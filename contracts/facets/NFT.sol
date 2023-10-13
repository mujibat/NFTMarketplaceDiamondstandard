// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./ERC721Facet.sol";
import {SignUtils} from "../libraries/SignUtils.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { Order } from "../structs/struct.sol";
contract ERC721Marketplace  {
 

    error NotOwner();
    error DeadlinePassed();
    error InvalidPrice();
    error InvalidSignature();
    error OrderExpired();
    error IncorrectPrice();
    error NotApproved();
    error InactiveOrder();


    function createOrder(Order calldata order) external returns (uint256 orderId){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if(ERC721Facet(order.token).ownerOf(order.tokenId) != msg.sender) revert NotOwner();
        console2.logBool(ERC721Facet(order.token).checkIsApprovedForAll(msg.sender, address(this)));
        if(!ERC721Facet(order.token).checkIsApprovedForAll(msg.sender, address(this))) revert NotApproved();        
        if(block.timestamp > order.deadline) revert DeadlinePassed();
        if (order.price < 0.01 ether) revert InvalidPrice();

        Order storage _order = ds.orders[ds.listingId];
         _order.seller = order.seller;
         _order.token = order.token;
         _order.tokenId = order.tokenId;
         _order.price = order.price;
         _order.signature = order.signature;
         _order.deadline = order.deadline;
         _order.isActive = order.isActive;

         orderId = ds.listingId;
         ds.listingId++;
         return orderId;
    }
   

    function executeOrder(uint256 orderId) external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        Order storage order = ds.orders[orderId];
        if (!order.isActive) revert InactiveOrder();
        if(msg.value != order.price) revert IncorrectPrice();
        if(block.timestamp > order.deadline) revert OrderExpired();

            if (
            !SignUtils.isValid(
                SignUtils.constructMessageHash(
                    order.seller,
                    order.token,
                    order.tokenId,
                    order.price,
                    order.deadline
                ),
                order.signature,
               order.seller
            )
        ) revert InvalidSignature();
    
        ERC721Facet(order.token).transferFrom(order.seller, msg.sender, order.tokenId);
        payable(order.seller).transfer(order.price);

        order.isActive = false;
    }

   
}




