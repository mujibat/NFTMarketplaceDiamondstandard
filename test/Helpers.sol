// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../contracts/libraries/SignUtils.sol";


abstract contract Helpers is Test {
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
}
    // function switchSigner(address _newSigner) public {
    //     address foundrySigner = 
    //     if(msg.sender == foundrySigner) {
    //         vm.startPrank(_newSigner);
    //     } else {
    //        vm.stopPrank(); 
    //     vm.startPrank(_newSigner);
    //     }
    // }
