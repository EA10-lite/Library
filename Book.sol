// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract BookContract {
    struct Book {
        uint256 ID;
        string title;
        string author;
        string genre;
        bool available;
    }

    Book[] public listOfBooks;
    mapping(string => Book[]) public genreToBooks;

    function addBook(
        string memory _title,
        string memory _author,
        string memory _genre
    ) public {
        uint256 _ID = listOfBooks.length + 1;
        Book memory newBook = Book(
            _ID,
            _title,
            _author,
            _genre,
            true
        );

        listOfBooks.push(newBook);
        genreToBooks[_genre].push(newBook);
    }
}