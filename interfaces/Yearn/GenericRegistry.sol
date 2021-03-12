pragma solidity ^0.8.2;

interface GenericRegistry {
    function getAssets() external view returns (address[] memory);
}