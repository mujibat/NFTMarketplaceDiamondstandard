// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/NFT.sol";
import "../contracts/structs/struct.sol";
import { ERC721Facet } from "../contracts/facets/ERC721Facet.sol";
import { Helpers } from "../test/Helpers.sol";
import {Test, console2} from "forge-std/Test.sol";
import "./helpers/DiamondUtils.sol";
import "../contracts/libraries/SignUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Marketplace _erc721marketplace;
    ERC721Facet erc721facet;
    Order _order;
     address _userA;
    address _userB;

    uint256 _privKeyA;
    uint256 _privKeyB;


    // uint256 user
    function mkaddr(
        string memory name
    ) public returns (address addr, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        // address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))))
        addr = vm.addr(privateKey);
        vm.label(addr, name);
    }

    function constructSig(
        address seller,
        address token,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint256 privKey
    ) public pure returns (bytes memory sig) {
        bytes32 mHash = keccak256(
            abi.encodePacked(seller, token, tokenId, price, deadline)
        );

        mHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", mHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, mHash);
        sig = getSig(v, r, s);
    }

    function getSig(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory sig) {
        sig = bytes.concat(r, s, bytes1(v));
    }

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), 'DOLAPO', 'DLP');
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        _erc721marketplace = new ERC721Marketplace();
        erc721facet = new ERC721Facet();
        //upgrade diamond with facets
        (_userA, _privKeyA) = mkaddr("USERA");
        (_userB, _privKeyB) = mkaddr("USERB");

        _order = Order({
            seller: _userA,
            token: address(erc721facet),
            tokenId: 1,
            price: 5 ether,
            signature: bytes(""),
            deadline: 0,
            isActive: true
        });

        erc721facet.mint(_userA, 1);

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
     
        cut[2] = (
            FacetCut({
                facetAddress: address(_erc721marketplace),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Marketplace")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    // function testName() public {
    //     assertEq(ERC721Facet(address(diamond)).name(), 'DOLAPO');
    // }

 function testNotOwner() public {
        _order.seller = _userB;
        vm.expectRevert(ERC721Marketplace.NotOwner.selector);
        _erc721marketplace.createOrder(_order);
    }

    function testNotApproved() public {
        // switchSigner(_userA);
        vm.startPrank(_userA);
        vm.expectRevert(ERC721Marketplace.NotApproved.selector);
        _erc721marketplace.createOrder(_order);
    }

    function testDeadline() public {
        vm.startPrank(_userA);
        erc721facet.setApprovalForAll(address(_erc721marketplace), true);
        vm.expectRevert(ERC721Marketplace.DeadlinePassed.selector);
        _erc721marketplace.createOrder(_order);
    }

    function testPrice() public {
        vm.startPrank(_userA);
        erc721facet.setApprovalForAll(address(_erc721marketplace), true);
        _order.deadline = 200;
        _order.price = 0.001 ether;
        vm.expectRevert(ERC721Marketplace.InvalidPrice.selector);
        _erc721marketplace.createOrder(_order);
    }

    function testCreateOrder() public {
        vm.startPrank(_userA);
        erc721facet.setApprovalForAll(address(_erc721marketplace), true);
        _order.deadline = 200;

        uint currentCount = ds.listingId();
        uint id = _erc721marketplace.createOrder(_order);

        assertEq(currentCount, id);
    }

     function testOrderIsActive() public {
        uint orderId = _preExecute();
        _erc721marketplace.executeOrder{value: 5 ether}(orderId);
        vm.expectRevert();
         _erc721marketplace.executeOrder{value: 5 ether}(orderId);

        
    }

    function testIncorrectPrice() public {
        uint orderId = _preExecute();
        vm.expectRevert(ERC721Marketplace.IncorrectPrice.selector);
        _erc721marketplace.executeOrder{value: 4 ether}(orderId);
    }

    function testOrderExpired() public {
        uint orderId = _preExecute();
        vm.warp(250);
        vm.expectRevert(ERC721Marketplace.OrderExpired.selector);
        _erc721marketplace.executeOrder{value: 5 ether}(orderId);
    }
    function testExecute() public {
        uint orderId = _preExecute();
        _erc721marketplace.executeOrder{value: 5 ether}(orderId);

        // vm.expectRevert(ERC721Marketplace.InvalidSignature.selector);
    }

    function _preExecute() internal returns (uint _orderId) {
        vm.startPrank(_userA);
        vm.deal(_userA, 10 ether);
        erc721facet.setApprovalForAll(address(_erc721marketplace), true);
        _order.deadline = 200;

        _order.signature = constructSig(
            _order.seller,
            _order.token,
            _order.tokenId,
            _order.price,
            _order.deadline,
            _privKeyA
        );

        _orderId = _erc721marketplace.createOrder(_order);
        vm.stopPrank();
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
