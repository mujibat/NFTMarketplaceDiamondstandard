// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import { LibDiamond } from "../libraries/LibDiamond.sol";
import "forge-std/console2.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
contract ERC721Facet {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/


    function tokenURI(uint256 id) public view virtual returns (string memory) {
        return "string";
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/
    constructor() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.name = 'DOLAPO';
        ds.symbol = 'DLP';
    }
       function name() public view virtual returns (string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.name;
    }

    function symbol() public view virtual returns (string memory) {
      LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.symbol;  
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require((owner = ds._ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(owner != address(0), "ZERO_ADDRESS");

        return ds._balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

  

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address owner = ds._ownerOf[id];

        require(msg.sender == owner || ds.isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        ds.getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function checkIsApprovedForAll(address origin, address operator) public view returns (bool){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.isApprovedForAll[origin][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(from == ds._ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || ds.isApprovedForAll[from][msg.sender] || msg.sender == ds.getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            ds._balanceOf[from]--;

            ds._balanceOf[to]++;
        }

        ds._ownerOf[id] = to;

        delete ds.getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     bytes calldata data
    // ) public virtual {
    //     transferFrom(from, to, id);

    //     require(
    //         to.code.length == 0 ||
    //             ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
    //             ERC721TokenReceiver.onERC721Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    // function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    //     return
    //         interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
    //         interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
    //         interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    // }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    function mint(address to, uint256 id) public{
        _mint(to, id);
    }

    function _mint(address to, uint256 id) internal virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(to != address(0), "INVALID_RECIPIENT");

        require(ds._ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            ds._balanceOf[to]++;
        }

        ds._ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }
     function burn(uint256 id) public {
        _burn(id);
    }
    function _burn(uint256 id) internal virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address owner = ds._ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            ds._balanceOf[owner]--;
        }

        delete ds._ownerOf[id];

        delete ds.getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function safeMint(address to, uint256 id) public {
        _safeMint(to, id);
    }
    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // function _safeMint(
    //     address to,
    //     uint256 id,
    //     bytes memory data
    // ) internal virtual {
       
    //     _mint(to, id);

    //     require(
    //         to.code.length == 0 ||
    //             ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
    //             ERC721TokenReceiver.onERC721Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
