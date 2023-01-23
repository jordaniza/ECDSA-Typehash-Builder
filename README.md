# ECDSA-Typehash-Builder

Create EIP712 Compliant typehashes in foundry tests

Foundry utility to help test Permit signatures.

These are fiddly and a bit of a pain to get right - in no large part because it's
tough to work out WHERE the signature has gone wrong.

This lib contains a simple utility for OZ delegation and, probably more usefully, EIP712 permit for an ERC20 token.

Please see the [./test](./test/TestHashBuilder.sol) file for usage instructions.
