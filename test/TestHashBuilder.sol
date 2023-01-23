// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ERC20} from "@oz/token/ERC20/ERC20.sol";
import "@oz/token/ERC20/extensions/draft-ERC20Permit.sol";

import "src/HashBuilder.sol";

// transferrable rewards token for testing
contract MockRewardsToken is ERC20("Reward", "RWD"), ERC20Permit("Reward") {
    function mint(address to, uint256 quantity) external returns (bool) {
        _mint(to, quantity);
        return true;
    }

    function burn(address from, uint256 quantity) external returns (bool) {
        _burn(from, quantity);
        return true;
    }
}

contract TestPermit is Test {
    MockRewardsToken public token;

    function setUp() public {
        // instantiate a fresh instance of the token and mint the full supply to
        // the test contract
        token = new MockRewardsToken();
        token.mint(address(this), type(uint256).max);
    }

    function testPermit(
        uint128 _pk,
        address _receiver,
        uint256 _deadline,
        uint256 _value
    ) public {
        // valid private keys are bounded 1 <= key <= type(uint128).max
        vm.assume(_pk > 0);

        // derive the user from the Private Key
        address user = vm.addr(_pk);

        // 3 cases will cause a fail:
        //      1: transfer to zero address (OZ)
        //      2: transfer to this address (already has tokens)
        //      3: transfer to the original user (already has tokens)
        vm.assume(
            _receiver != address(0) &&
                _receiver != address(this) &&
                _receiver != user
        );

        // deadline must be in the future
        vm.assume(_deadline > 0);

        // make sure the user has enough tokens
        token.transfer(user, _value);

        // generate a valid permit message
        bytes32 permitMessage = EIP712HashBuilder.generateTypeHashPermit(
            user,
            _receiver,
            _value,
            _deadline,
            token
        );

        // sign it with the user's private key - in reality you'd do this
        // on the client side
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_pk, permitMessage);

        // the _receiver (or anyone else can call permit with the message
        // and then transfer tokens from the user
        // in a real application, you'd add this to some deposit function
        // to avoid having to pay gas for an ERC20 approval
        vm.startPrank(_receiver);
        {
            token.permit(user, _receiver, _value, _deadline, v, r, s);
            token.transferFrom(user, _receiver, _value);
        }
        vm.stopPrank();

        // user will now have their balance emptied to the _receiver
        assertEq(token.balanceOf(user), 0);
        assertEq(token.balanceOf(_receiver), _value);
    }
}
