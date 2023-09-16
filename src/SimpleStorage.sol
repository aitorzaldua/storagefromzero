///////////////////
/// VERSION   ////
//////////////////

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

///////////////////
/// IMPORTS   ////
//////////////////

///////////////////////////////
/// INTERFACES, LIBRARIES   ///
///////////////////////////////

///////////////////
/// CONTRACT   ////
//////////////////
contract SimpleStorage {
    ///////////////////
    /// ERRORS   ////
    //////////////////

    //////////////////////////////
    /// TYPE DECLARATIONS   ??////
    //////////////////////////////

    //////////////////////////
    /// STATE VARIABLES   ///
    /////////////////////////

    ///////////////////////////////
    //   State Variables        //
    /////////////////////////////

    uint256 myFavoriteNumber;
    address public owner;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] public listOfPeople;

    mapping(string => uint256) public nameToFavoriteNumber;

    ///////////////////
    // Events        //
    ///////////////////

    /////////////////////////
    //   Modifiers        //
    ///////////////////////

    ///////////////////////////////
    //   Functions  public      //
    /////////////////////////////
    constructor() {
        owner = msg.sender;
    }

    function store(uint256 _favoriteNumber) public {
        myFavoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    ///////////////////////////////
    //   Functions  view         //
    /////////////////////////////

    function retrieve() public view returns (uint256) {
        return myFavoriteNumber;
    }
}
