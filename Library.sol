// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {BookContract} from "./Book.sol";
import {MemberContract} from "./Member.sol";

contract LibraryContract {
    struct Library {
        uint256 ID;
        string name;
        string location;
        address admin;
        BookContract book;
        MemberContract member;
    }

    Library[] public libraries;
    mapping(bool => string) private libraryExist;

    function registerLibrary(
        string memory _name,
        string memory _location
    ) public {
        BookContract book = new BookContract();
        MemberContract member = new MemberContract();

        uint256 _ID = libraries.length + 1;

        Library memory newLibrary = Library(
            _ID,
            _name,
            _location,
            msg.sender,
            book,
            member
        );

        libraries.push(newLibrary);
    }

    function addNewBook(
        uint256 _libraryId,
        string memory _title,
        string memory _author,
        string memory _genre
    ) public {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.addBook(_title, _author, _genre);
    }

    function addNeMember(
        uint256 _libraryId,
        string memory _name,
        uint256 _age,
        address _wallet
    ) public {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.member.registerMember(_name, _age, _wallet);
    }

    function _getMyLibrary(uint256 _libraryId) internal view returns (Library storage) {
        for(uint256 i = 0; i < libraries.length; i++) {
            if(libraries[i].ID == _libraryId) {
                require(
                    libraries[i].admin == msg.sender,
                    "Library not found!"
                );

                return libraries[i];
            }
        }

        revert("Library not found!");
    }
}