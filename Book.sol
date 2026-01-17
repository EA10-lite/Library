// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import {MemberContract} from "./Member.sol";

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

    Book[] public listOfBooks;
    uint256[] public bookIds;
    mapping(uint256 => Book) public books;  // mapping book ids to books
    mapping(bytes32 => bool) private bookExist; // mapping to see if book exist
    mapping(uint256 => address[]) public borrowedHistory; // mpaaing to keep all borrowed history

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

    function borrowBook(uint256 _ID) public {
        require(books[_ID].available, "Book not available!");

        Book storage myBook = books[_ID];
        myBook.available = false;

        borrowedHistory[_ID].push(msg.sender);
    }
}