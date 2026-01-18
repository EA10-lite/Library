// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {MemberContract} from "./Member.sol";

contract BookContract {
    bool private locked;
    uint256 private bookCounter;

    MemberContract public memberContract; // reference to member contract
    address payable public libraryAdmin;   // address of library admin contract is created the non member fee is added
    uint256 public nonMemberBorrowFee; // fee for borrowing a book for non-members

    constructor(
        address _memberContract,
        address payable _libraryAdmin,
        uint256 _nonMemberBorrowFee
    ) {
        memberContract = MemberContract(_memberContract);
        libraryAdmin = _libraryAdmin;
        nonMemberBorrowFee = _nonMemberBorrowFee;
    }

    struct Book {
        uint256 ID;
        string title;
        string author;
        string genre;
        uint256 quantity;
        uint256 price; // amount in wei
        uint256 borrowFee; // amount in wei
        bool exists;
        uint256 date;
    }

    struct Transaction {
        address user;
        uint256 timestamp;
    }

    uint256[] public bookIds;
    mapping(uint256 => Book) public books;  // mapping book ids to books
    mapping(bytes32 => bool) private bookExist; // mapping to see if book exist
    mapping(uint256 => Transaction[]) public borrowedHistory; // mapping to keep all borrowed history
    mapping(uint256 => Transaction[]) public purchaseHistory; // mapping to keep all purchase history

    // bookId => address => currently borrowing ?
    // This is to keep track that one user cannot a borrow the same book more than once;
    mapping(uint256 => mapping(address => bool)) public isBorrowing;


    function addBook(
        string memory _title,
        string memory _author,
        string memory _genre,
        uint256 _quantity,
        uint256 _price,
        uint256 _borrowFee
    ) public onlyLibraryAdmin{
        require(bytes(_title).length > 0, "Title cannot be empty!");
        require(bytes(_author).length > 0, "Author cannot be empty!");
        require(bytes(_genre).length > 0, "Genre cannot be empty!");
        require(_quantity > 0, "Quantity must be greater than 0");
        require(_price > 0, "Price must be greater than 0");
        require(_borrowFee > 0, "Price must be greater than 0");

        bytes32 key = keccak256(abi.encodePacked(_title, _author));
        require(!bookExist[key], "This book by this author already exists!");
        bookExist[key] = true;

        bookCounter += 1;
        uint256 _ID = bookCounter;

        books[_ID] = Book(
            _ID,
            _title,
            _author,
            _genre,
            _quantity,
            _price,
            _borrowFee,
            true,
            block.timestamp
        );

        bookIds.push(_ID);
    }

    function restock(uint256 _ID, uint256 _quantity) public onlyLibraryAdmin {
        require(_quantity > 0, "Quantity must be greater than 0");

        Book storage book = books[_ID];
        require(book.exists, "Book not found");
        book.quantity += _quantity;
    } 

    function getBooks() public view returns (Book[] memory) {
        Book[] memory allBooks = new Book[](bookIds.length);
        for (uint256 i = 0; i < bookIds.length; i++) {
            allBooks[i] = books[bookIds[i]];
        }
        return allBooks;
    }

    function getBookById(uint256 _ID)  public view returns (Book memory) {
        require(books[_ID].exists, "Book not found");
        return books[_ID];
    }

    function borrowBook(uint256 _ID) public payable nonReentract {
        require(books[_ID].exists, "Book not found!");
        require(books[_ID].quantity > 0, "Book not available!");
        require(isBorrowing[_ID][msg.sender], "Already borrowed!");

        Book storage myBook = books[_ID];

        bool isMember = memberContract.memberExist(msg.sender);
        uint256 requiredPayment = isMember
            ? myBook.borrowFee 
            : nonMemberBorrowFee;
        require(msg.value >= requiredPayment, "Not enough ETH sent");

        isBorrowing[_ID][msg.sender] = true;
        borrowedHistory[_ID].push(
            Transaction({
                user: msg.sender,
                timestamp: block.timestamp
            })
        );
        myBook.quantity -= 1;

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

    function returnBook(uint256 _ID) public {
        require(books[_ID].exists, "Book not found");
        require(isBorrowing[_ID][msg.sender], "You did not borrow this book");

        isBorrowing[_ID][msg.sender] = false;
        books[_ID].quantity += 1;
    }

    function buyBook(uint256 _ID) public payable nonReentract {
        Book storage myBook = books[_ID];
        require(myBook.exists, "Book not found");
        require(myBook.quantity > 0, "Book out of stock");
        require(msg.value >= myBook.price, "Insufficient payment");

        // Reduce Book
        myBook.quantity -= 1;
        purchaseHistory[_ID].push(
            Transaction({
                user: msg.sender,
                timestamp: block.timestamp
            })
        );

        // Forward ETH to library admin using call (safe method)
        (bool sent, ) = libraryAdmin.call{value: msg.value}("");
        require(sent, "Failed to send ETH to library");

        // Refund excess ETH
        uint256 excess = msg.value - myBook.price;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "Failed to refund excess ETH");
        }
        
    }


    modifier onlyLibraryAdmin() {
        require(msg.sender == libraryAdmin, "Not library admin");
        _; // insert the body of the function
    }

    modifier nonReentract() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }
}