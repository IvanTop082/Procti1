// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ITokenMessenger
 * @dev Interface for Circle's CCTP TokenMessengerV2 contract
 */
interface ITokenMessenger {
    /**
     * @dev Deposits and burns tokens from sender to be minted on destination domain
     * @param amount Amount of tokens to deposit and burn
     * @param destinationDomain Destination domain
     * @param mintRecipient Address to receive minted tokens on destination domain
     * @param burnToken Address of token to burn
     * @return nonce Nonce of the burn message
     */
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

