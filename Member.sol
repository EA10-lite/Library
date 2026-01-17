// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract MemberContract {
    struct Member {
        uint256 ID;
        string name;
        uint256 age;
        address wallet;
    }

    Member[] public members;
    mapping(address => bool) public memberExist;

    function registerMember(
        string memory _name,
        uint256 _age,
        address _wallet
    ) public {
        require(bytes(_name).length > 0, "User name cannot be empty!");
        require(_age > 15, "User must be older than 15");
        require(!memberExist[_wallet], "User registered!");
        memberExist[_wallet] = true;

        uint256 _ID = members.length + 1;
        Member memory newMember = Member(
            _ID,
            _name,
            _age,
            _wallet
        );

        members.push(newMember);
    }
}