//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Market {
    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    struct Listing {
        ListingStatus status;
        address seller;
        address token;
        uint256 tokenId;
        uint256 price;
    }

    //event to emit when nft is listed
    event Listed(
        uint256 listingId,
        address seller,
        address token,
        uint256 tokenId,
        uint256 price
    );

    //event to emit when nft is sold
    event Sale(
        uint256 listingId,
        address buyer,
        address token,
        uint256 tokenId,
        uint256 price
    );

    //event to emit when an nft is cancelled
    event Cancel(uint256 listingId, address seller);

    uint256 private _listingId = 0;

    mapping(uint256 => Listing) private _listings;

    function getListing(uint256 listingId)
        public
        view
        returns (Listing memory)
    {
        return _listings[listingId];
    }

    //function to create and list tokens
    function listToken(
        address token,
        uint256 tokenId,
        uint256 price
    ) external {
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);

        Listing memory listing = Listing(
            ListingStatus.Active,
            msg.sender,
            token,
            tokenId,
            price
        );

        //increment listing id after each function call
        _listingId++;

        _listings[_listingId] = listing;

        //emit Listed event after listing
        emit Listed(_listingId, msg.sender, token, tokenId, price);
    }

    //function to buy token
    function buyToken(uint256 listingId) external payable {
        Listing storage listing = _listings[listingId];

        //check to see if listing is active
        require(
            listing.status == ListingStatus.Active,
            "Listing is not active"
        );

        //ensure buyer is not seller
        require(msg.sender != listing.seller, "Seller cannot be buyer");

        //ensure buyer has enough funds
        require(msg.value >= listing.price, "Insufficient funds");

        //transfer ownership
        IERC721(listing.token).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
        payable(listing.seller).transfer(listing.price);

        //emit Sale even after sale
        emit Sale(
            listingId,
            msg.sender,
            listing.token,
            listing.tokenId,
            listing.price
        );
    }

    function cancel(uint256 listingId) public {
        Listing storage listing = _listings[listingId];

        //ensure only seller can cancel lisiting
        require(msg.sender == listing.seller, "Only seller can cancel listing");
        //check if listing is active
        require(
            listing.status == ListingStatus.Active,
            "Listing is not active"
        );

        //cancel listing
        listing.status = ListingStatus.Cancelled;

        IERC721(listing.token).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        //emit Cancel event after cancellation
        emit Cancel(listingId, listing.seller);
    }
}
