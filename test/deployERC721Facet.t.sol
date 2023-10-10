// SPDX-License-Identifier: MIT
pragma solidity <0.9.20;
//FOR ERC721 FACET
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
// import "../contracts/facets/NFT.sol";
import "../contracts/facets/ERC721Facet.sol";
// import ".././lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./helpers/DiamondUtils.sol";

contract DiamondERC is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
     ERC721Facet erc721facet;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), 'DOLAPO', 'DLP');
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
         erc721facet = new ERC721Facet();

        //upgrade diamond with facets

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
                facetAddress: address(erc721facet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Facet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }
       function testName() public {
        assertEq(ERC721Facet(address(diamond)).name(), 'DOLAPO');
    }
       function testSymbol() public {
        assertEq(ERC721Facet(address(diamond)).symbol(), 'DLP');
    }
      function testMint() public {
         vm.startPrank(address(0x1111));
        ERC721Facet(address(diamond)).mint(address(0x1111), 1);
        assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1111)), 1);
    }
    function testBalanceOf() public {
         vm.startPrank(address(0x1111));
        ERC721Facet(address(diamond)).mint(address(0x1111), 1);
        assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1111)), 1);
    }
    function testBurn() public {
       vm.startPrank(address(0x1111));
        ERC721Facet(address(diamond)).mint(address(0x1111), 1);
        ERC721Facet(address(diamond)).burn (1); 
    }
    function testTransferFrom() public {
         vm.startPrank(address(0x1111));
        ERC721Facet(address(diamond)).mint(address(0x1111), 1);
        ERC721Facet(address(diamond)).approve(address(diamond), 1);
        vm.startPrank(address(diamond));
        ERC721Facet(address(diamond)).transferFrom(address(0x1111), address(0x2222), 1);
    }
    function testApprove() public {
             vm.startPrank(address(0x1111));
        ERC721Facet(address(diamond)).mint(address(0x1111), 1);
        ERC721Facet(address(diamond)).approve(address(0x2222), 1);
    }
    function testSafeTransferFrom() public {
        vm.startPrank(address(0xA003A9A2E305Ff215F29fC0b7b4E2bb5a8C2F3e1));
        ERC721Facet(address(diamond)).mint(address(0xA003A9A2E305Ff215F29fC0b7b4E2bb5a8C2F3e1), 1);
        ERC721Facet(address(diamond)).approve(address(diamond), 1);
        vm.startPrank(address(diamond));
        ERC721Facet(address(diamond)).transferFrom(address(0xA003A9A2E305Ff215F29fC0b7b4E2bb5a8C2F3e1), address(0x2222), 1);
    }
    function testOwnerOf() public {
        vm.startPrank(address(0x1111));
     ERC721Facet(address(diamond)).mint(address(0x1111), 1);  
     ERC721Facet(address(diamond)).ownerOf(1);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
