pragma solidity ^0.5.11;

import "ds-test/test.sol";

import "./Hadaiken.sol";

contract HadaikenTest is DSTest {
    Hadaiken hadaiken;

    function setUp() public {
        hadaiken = new Hadaiken();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
