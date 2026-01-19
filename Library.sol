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

    uint256 public constant MINIMUM_PRICE = 2000 wei;
    Library[] public libraries;
    mapping(address => bool) private libraryExist;
    mapping(string => bool) private libraryNameTaken;

    function registerLibrary(
        string memory _name,
        string memory _location
    ) public {
        require(!libraryExist[msg.sender], "Library registered!");
        libraryExist[msg.sender] = true;

        require(!libraryNameTaken[_name], "Library name already exists");
        libraryNameTaken[_name] = true;

        MemberContract member = new MemberContract();
        BookContract book = new BookContract(
            address(member),
            payable(msg.sender),
            MINIMUM_PRICE
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
        string memory _genre,
        uint256 _quantity,
        uint256 _price,
        uint256 _borrowFee
    ) public {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.addBook(
            _title,
            _author,
            _genre,
            _quantity,
            _price,
            _borrowFee
        );
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

    function restockBook(uint256 _libraryId, uint256 _bookId, uint256 _quantity) public {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.restock(_bookId, _quantity);
    }

    function buyBookFromLibrary(uint256 _libraryId, uint256 _bookId) public payable {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.buyBook{value: msg.value}(_bookId);
    }

    function borrowFromLibrary(uint256 _libraryId, uint256 _bookId) public payable {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.borrowBook{value: msg.value}(_bookId);
    }

    function returnBorrowedBookg(uint256 _libraryId, uint256 _bookId) public {
        Library storage myLibrary = _getMyLibrary(_libraryId);
        myLibrary.book.returnBook(_bookId);
    }

    function getLibraryBooks() public view {
        Library memory myLibrary = _getMyLibrary(1);
        myLibrary.book.getBooks();
    }
}