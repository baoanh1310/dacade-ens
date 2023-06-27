// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

contract DacadeENS is ERC721URIStorage {

  using Counters for Counters.Counter;

  /**
  * @dev Counter variable from the Counters library to keep track of token IDs.
  */
  Counters.Counter private _tokenIds;

  /**
  * @dev The top-level domain for the contract.
  */
  string public tld;

  /**
  * @dev SVG string representing the first part of an SVG image used for domain tokens.
  */
  string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';

  /**
  * @dev SVG string representing the second part of an SVG image used for domain tokens.
  */
  string svgPartTwo = '</text></svg>';


  /**
  * @dev Mapping that stores the owner address for each registered domain.
  *    The key is the domain name.
  *    The value is the address of the domain owner.
  */
  mapping(string => address) public domains;
  

  /**
  * @dev Mapping that stores additional records associated with each domain.
  *  The key is the domain name.
  *  The value is the record associated with the domain.
  */
  mapping(string => string) public records;

  /**
  * @dev Mapping that stores the name associated with each token ID.
  * The key is the token ID.
  * The value is the name of the corresponding domain.
  */
  mapping (uint => string) public names;

  /**
  * @dev The address of the contract owner.
  */
  address payable public owner;

  /**
  * @dev Error indicating an unauthorized action.
  */
  error Unauthorized();

  /**
  * @dev Error indicating that a domain is already registered.
  */
  error AlreadyRegistered();

  /**
  * @dev Error indicating an invalid domain name.
  * @param name The invalid domain name.
  */
  error InvalidName(string name);

  /**
  * @dev Constructor function that initializes the Dacade Name Service contract.
  * @param _tld The top-level domain for the contract.
  */
  constructor(string memory _tld) ERC721 ("Dacade Name Service", "DNS") payable {
    owner = payable(msg.sender);
    tld = _tld;
  }

  /**
   * @dev Calculates the price for registering a domain with the given name.
   * @param name The name of the domain.
   * @return The price in CELO for registering the domain.
   * Reverts if the name is empty.
  */
  function price(string calldata name) public pure returns(uint) {
    uint len = StringUtils.strlen(name);
    require(len > 0);
    if (len == 3) {
      return 5 * 10**17; // 0.5 CELO
    } else if (len == 4) {
      return 3 * 10**17; // 0.3 CELO
    } else {
      return 1 * 10**17; // 0.1 CELO
    }
  }

  /**
  * @dev Constant representing the duration of one year in seconds.
  */
  uint256 private constant ONE_YEAR_IN_SECONDS = 365 days;

  /**
   * @dev Mapping that stores the expiration date for each domain.
   * @dev The key is the domain name.
   * @dev The value is the expiration date in Unix timestamp format.
   * @dev Access modifier set to private.
   */
  mapping(string => uint256) private domainExpiration;

  /**
   * @dev Sets the expiration date for a domain.
   * @param name The name of the domain.
   * @param expirationDate The desired expiration date for the domain.
   *                      Expressed as a Unix timestamp (number of seconds since January 1, 1970).
   *                      Must be a future date.
   *                      Use `block.timestamp` to get the current timestamp.
   */

  function setDomainExpiration(string calldata name, uint256 expirationDate) public {
    require(domains[name] == msg.sender, "Only the domain owner can set the expiration date");

    domainExpiration[name] = expirationDate;
  }

  /**
  * @dev Checks if a domain has expired based on its expiration date.
  * @param name The name of the domain.
  * @return A boolean indicating whether the domain has expired (true) or not (false).
  */
  function isDomainExpired(string calldata name) public view returns (bool) {
    uint256 expirationDate = domainExpiration[name];
    if (expirationDate == 0) {
      // Domain expiration date not set
      return false;
    }
    return block.timestamp > expirationDate;
  }


  /**
  * @dev Registers a new domain with the provided name.
  * @param name The name of the domain to register.
  */
  function register(string calldata name) public payable {
    require(bytes(name).length > 0, "Name cannot be empty");\
    require(msg.value >= price(name), "Not enough CELO");
    if (domains[name] != address(0)) revert AlreadyRegistered();
    if (!valid(name)) revert InvalidName(name);

    uint256 _price = price(name);
    
    string memory _name = string(abi.encodePacked(name, ".", tld));
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    uint256 newRecordId = _tokenIds.current();
    uint256 length = StringUtils.strlen(name);
    string memory strLen = Strings.toString(length);

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        _name,
        '", "description": "A domain on the Dacade Name Service", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(finalSvg)),
        '","length":"',
        strLen,
        '"}'
      )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;
    names[newRecordId] = name;
    _tokenIds.increment();
    uint256 expirationDate = block.timestamp + ONE_YEAR_IN_SECONDS;
    domainExpiration[name] = expirationDate;
  }

  /**
  * @dev Returns the address associated with a registered domain.
  * @param name The name of the domain.
  * @return The address associated with the domain.
  */
  function getAddress(string calldata name) public view returns (address) {
      return domains[name];
  }


  /**
  * @dev Sets the record associated with a registered domain.
  * @param name The name of the domain.
  * @param record The record to set for the domain.
  */
  function setRecord(string calldata name, string calldata record) public {
      address domainOwner = domains[name];
      require(domainOwner != address(0), "Domain does not exist");
      require(domainOwner == msg.sender, "Only the domain owner can set the record");
      if (isDomainExpired(name)) {
      domainExpiration[name] = block.timestamp + ONE_YEAR_IN_SECONDS;
      }
      records[name] = record;
  }

  /**
  * @dev Retrieves the record associated with a registered domain.
  * @param name The name of the domain.
  * @return The record associated with the domain.
  */
  function getRecord(string calldata name) public view returns(string memory) {
      return records[name];
  }

  /**
  * @dev Retrieves an array of all registered domain names.
  * @return An array of strings containing all registered domain names.
  */
  function getAllNames() public view returns (string[] memory) {
    string[] memory allNames = new string[](_tokenIds.current());
    for (uint i = 0; i < _tokenIds.current(); i++) {
      allNames[i] = names[i];
    }

    return allNames;
  }

  /**
  * @dev Checks if a domain name is valid.
  * @param name The domain name to validate.
  * @return A boolean indicating whether the domain name is valid or not.
  */
  function valid(string calldata name) public pure returns(bool) {
    return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
  }

  /**
  * @dev Modifier to restrict access to only the contract owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @dev Checks whether the caller is the owner of the contract.
  * @return A boolean indicating whether the caller is the owner.
  */
  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  /**
  * @dev Allows the contract owner to withdraw the contract's CELO balance.
  * @dev The function can only be called by the contract owner.
  * @dev Emits a `Withdraw` event on successful withdrawal.
  * @dev Reverts if the withdrawal fails.
  */
  function withdraw() public onlyOwner {
    uint amount = address(this).balance;
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to withdraw CELO");
  } 

  /**
  * @dev Allows the domain owner to transfer the ownership of a domain to a new address.
  * @param name The name of the domain to transfer.
  * @param newOwner The address of the new owner.
  * @dev Reverts if the caller is not the current domain owner or if the new owner address is invalid.
  */
  function transferDomainOwnership(string calldata name, address newOwner) public {
    require(domains[name] == msg.sender, "Only the domain owner can transfer ownership");
    require(newOwner != address(0), "Invalid new owner address");

    domains[name] = newOwner;
  }



}
