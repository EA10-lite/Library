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
    mapping(address => bool) private libraryExist;

    function registerLibrary(
        string memory _name,
        string memory _location
    ) public {
        require(!libraryExist[msg.sender], "Library registered!");
        libraryExist[msg.sender] = true;
        MemberContract member = new MemberContract();
        BookContract book = new BookContract(
            address(member),
            payable(msg.sender)
        );

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

    function addNewMember(
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

    function borrowFromLibrary(uint256 _libraryId, uint256 _bookId) public payable {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.borrowBook{value: msg.value}(_bookId);
    }

    function getLibraryBooks() public view {
        Library memory myLibrary = _getMyLibrary(1);
        myLibrary.book.getBooks();
    }
}