// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import { Base64 } from "./libraries/Base64.sol";

/**
 * @title DacadeENS
 * @dev A decentralized domain name service contract that allows users to register, transfer, renew, and resolve domain names.
 */
contract DacadeENS is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint => string) public names;
    address payable public owner;

    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);
    error InvalidToken(uint tokenId);

    constructor(string memory _tld) ERC721("Dacade Name Service", "DNS") payable {
        owner = payable(msg.sender);
        tld = _tld;
    }

    /**
     * @dev Calculates the registration price for a given domain name.
     * @param name The domain name to calculate the price for.
     * @return The registration price in wei.
     */
    function price(string calldata name) public pure returns (uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);

        if (len == 1) {
            return 1 ether;
        } else if (len == 2) {
            return 0.5 ether;
        } else if (len == 3) {
            return 0.1 ether;
        } else {
            return 0.01 ether;
        }
    }

    /**
     * @dev Registers a new domain name.
     * @param name The domain name to register.
     */
    function register(string calldata name) external payable {
        require(msg.value >= price(name), "Insufficient funds.");
        require(domains[name] == address(0), "Domain already registered.");

        // Generate a new token ID for the domain name
        _tokenIds.increment();
        uint tokenId = _tokenIds.current();

        // Mint the token and set the token URI
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, name);

        // Store the domain ownership and emit an event
        domains[name] = msg.sender;
        names[tokenId] = name;
        emit Registered(msg.sender, name, tokenId);
    }

    /**
     * @dev Transfers ownership of a domain name to a new address.
     * @param name The domain name to transfer.
     * @param to The address to transfer ownership to.
     */
    function transfer(string calldata name, address to) external {
        require(domains[name] == msg.sender, "You do not own this domain.");
        require(domains[name] != address(0), "Domain does not exist.");

        // Transfer ownership and emit an event
        domains[name] = to;
        emit Transferred(msg.sender, to, name);
    }

    /**
     * @dev Checks if a domain name is available for registration.
     * @param name The domain name to check.
     * @return A boolean indicating if the domain name is available.
     */
    function isAvailable(string calldata name) external view returns (bool) {
        return domains[name] == address(0);
    }

    /**
     * @dev Extends the registration duration of a domain name by one year.
     * @param tokenId The token ID of the domain name.
     */
    function renew(uint tokenId) external payable {
        require(_exists(tokenId), "Token does not exist.");
        require(ownerOf(tokenId) == msg.sender, "You do not own this domain.");

        // Calculate the renewal price
        uint renewalPrice = price(names[tokenId]);

        // Check if the sent value is enough for renewal
        require(msg.value >= renewalPrice, "Insufficient funds for renewal.");

        // Emit an event
        emit Renewed(msg.sender, names[tokenId], tokenId);
    }

    /**
     * @dev Resolves a domain name by returning its associated record.
     * @param name The domain name to resolve.
     * @return The resolved record.
     */
    function resolve(string calldata name) external view returns (string memory) {
        require(domains[name] != address(0), "Domain does not exist.");
        return records[name];
    }

    /**
     * @dev Sets the record for a domain name.
     * @param name The domain name to set the record for.
     * @param record The record to set.
     */
    function setRecord(string calldata name, string calldata record) external {
        require(domains[name] == msg.sender, "You do not own this domain.");
        require(domains[name] != address(0), "Domain does not exist.");

        // Set the record and emit an event
        records[name] = record;
        emit RecordSet(msg.sender, name, record);
    }

    /**
     * @dev Calculates the SVG image for a given domain name.
     * @param name The domain name to generate the SVG for.
     * @return The SVG image as a string.
     */
    function generateSVG(string calldata name) external pure returns (string memory) {
        string memory base64Name = Base64.encode(bytes(name));
        string memory svg = string(abi.encodePacked(svgPartOne, base64Name, svgPartTwo));
        return svg;
    }

    /**
     * @dev Withdraws the contract balance to the owner's address.
     */
    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        uint balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param tokenId The token ID to get the URI for.
     * @return The token URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked("https://example.com/token/", StringUtils.uint2str(tokenId)));
    }

    /**
     * @dev Returns the base URI for all token URIs.
     * @return The base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return "https://example.com/";
    }

    event Registered(address indexed owner, string name, uint indexed tokenId);
    event Transferred(address indexed from, address indexed to, string name);
    event Renewed(address indexed owner, string name, uint indexed tokenId);
    event RecordSet(address indexed owner, string name, string record);
}
