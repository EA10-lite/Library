// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {MemberContract} from "./Member.sol";

contract BookContract {
    struct Book {
        uint256 ID;
        string title;
        string author;
        string genre;
        bool available;
        bool exists;
        uint256 date;
    }

    MemberContract public memberContract; // reference to member contract
    address payable public libraryAdmin;   // address of library admin

    Book[] public listOfBooks;
    uint256[] public bookIds;
    mapping(uint256 => Book) public books;  // mapping book ids to books
    mapping(bytes32 => bool) private bookExist; // mapping to see if book exist
    mapping(uint256 => address[]) public borrowedHistory; // mpaaing to keep all borrowed history

    constructor(address _memberContract, address payable _libraryAdmin) {
        memberContract = MemberContract(_memberContract);
        libraryAdmin = _libraryAdmin;
    }


    function addBook(
        string memory _title,
        string memory _author,
        string memory _genre
    ) public {
        require(bytes(_title).length > 0, "Title cannot be empty!");
        require(bytes(_author).length > 0, "Author cannot be empty!");
        require(bytes(_genre).length > 0, "Genre cannot be empty!");

        bytes32 key = keccak256(abi.encodePacked(_title, _author));
        require(!bookExist[key], "This book by this author already exists!");
        bookExist[key] = true;

        uint256 _ID = listOfBooks.length + 1;
        books[_ID] = Book(
            _ID,
            _title,
            _author,
            _genre,
            true,
            true,
            block.timestamp
        );

        listOfBooks.push(books[_ID]);
        bookIds.push(_ID);
    }

    function getBookById(uint256 _ID)  public view returns (Book memory) {
        require(books[_ID].exists, "Book not found");
        return books[_ID];
    }

    function borrowBook(uint256 _ID) public payable {
        require(books[_ID].available, "Book not available!");

        bool isMember = memberContract.memberExist(msg.sender);
        uint256 requiredPayment = isMember ? 1000 wei :  2000 wei;
        require(msg.value >= requiredPayment, "Not enough ETH sent");

        Book storage myBook = books[_ID];
        myBook.available = false;
        borrowedHistory[_ID].push(msg.sender);

        // Forward ETH to library admin using call (safe method)
        (bool sent, ) = libraryAdmin.call{value: requiredPayment}("");
        require(sent, "Failed to send ETH to library");

        // Refund excess ETH
        uint256 excess = msg.value - requiredPayment;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "Failed to refund excess ETH");
        }
    }
}