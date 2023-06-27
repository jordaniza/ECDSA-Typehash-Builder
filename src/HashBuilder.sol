// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@oz/utils/cryptography/ECDSA.sol";
import {IERC20Permit} from "@oz/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IERC20Metadata} from "@oz/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @notice EIP712-signature-compliant hash generator that can be signed by a user
 * @dev use in foundry tests with `vm.sign(pk, EIP712HashBuilder.generateTypeHashPermit( ...args));`
 */
library EIP712HashBuilder {
    bytes32 public constant VERSION_HASH = keccak256(bytes("1"));

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    bytes32 public constant typeHash =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @param _nameHash bytes32 hashedName = keccak256(bytes(_name)); Will be the name of the target contract
    /// @param _target address of the target contract
    function buildDomainSeparator(bytes32 _nameHash, address _target)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    _nameHash,
                    VERSION_HASH,
                    block.chainid,
                    _target
                )
            );
    }

    /// @notice generate the signature for permit (off-chain approval)
    function generateTypeHashPermit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        IERC20Permit _contract
    ) external view returns (bytes32) {
        string memory name = IERC20Metadata(address(_contract)).name();
        bytes32 nameHash = keccak256((bytes(name)));
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                _owner,
                _spender,
                _value,
                _contract.nonces(_owner),
                _deadline
            )
        );
        return
            ECDSA.toTypedDataHash(
                buildDomainSeparator(nameHash, address(_contract)),
                structHash
            );
    }

    /// @notice generate the signature for delegation
    function generateTypeHashDelegate(
        address _delegatee,
        uint256 _deadline,
        IERC20Permit _contract
    ) external view returns (bytes32) {
        string memory name = IERC20Metadata(address(_contract)).name();
        bytes32 nameHash = keccak256((bytes(name)));
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                _delegatee,
                _contract.nonces(_delegatee),
                _deadline
            )
        );
        return
            ECDSA.toTypedDataHash(
                buildDomainSeparator(nameHash, address(_contract)),
                structHash
            );
    }
}
