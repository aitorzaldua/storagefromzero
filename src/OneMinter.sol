// SPDX-License-Identifier: MIT

/*
 * @audit-qa [QA-01]
 * Description: Floating Pragma Solidity Version could lead to a potential vulnerability.
 * Attack Vector: Uncontroled version.
 * Mitigation: Set the solidity version
 */
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@solidity-campaignable/Campaignable.sol";

interface IERC721Contract {
    function earlyMint(address to, uint8 quantity, uint256 campaignId) external payable;
}

contract OneMinter is ReentrancyGuard, Ownable, Campaignable {
    ///////////////////////////////
    //   State Variables        //
    /////////////////////////////

    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public campaignCounter = 0;
    address public authorizerAddress;
    mapping(uint256 => Campaign) public campaignList;
    mapping(uint256 => mapping(address => uint8)) public paidOrders;
    mapping(uint256 => address[]) public paidOrdersAddresses;

    /////////////////////////
    //   Modifiers        //
    ///////////////////////

    modifier ensureUniqueCampaignExternalId(string memory _externalId) {
        for (uint256 i = 0; i < campaignCounter; i++) {
            require(
                keccak256(abi.encodePacked(campaignList[i].externalId)) != keccak256(abi.encodePacked(_externalId)),
                "External ID already exists"
            );
        }
        _;
    }

    /////////////////////////
    //   Functions        //
    ///////////////////////

    constructor() {
        authorizerAddress = msg.sender;
    }

    ////////////////////////////////
    //   Public Functions        //
    ////////////////////////////////

    function updateAuthorizerAddress(address _authorizerAddress) public onlyOwner {
        authorizerAddress = _authorizerAddress;
    }

    function requestRefund(uint256 _campaignId) public nonReentrant {
        Campaign storage campaign = campaignList[_campaignId];
        uint8 walletOrders = paidOrders[_campaignId][msg.sender];
        require(campaign.minted == false, "This campaign has already been minted");
        require(walletOrders > 0, "You don't hold any orders in this campaign");
        uint256 refundAmount = walletOrders * campaign.price;
        payable(msg.sender).transfer(refundAmount);
        campaign.ordersTotal -= walletOrders;
        campaign.campaignBalance -= refundAmount;
        paidOrders[_campaignId][msg.sender] = 0;
        emit OrderRefunded(
            Order({
                campaignId: _campaignId,
                purchaserAddress: msg.sender,
                quantity: walletOrders,
                campaignOrdersTotal: campaign.ordersTotal,
                walletOrdersTotal: 0,
                externalId: campaign.externalId
            })
        );
    }

    function createCampaign(Campaign memory _campaign, bytes memory _signature)
        public
        isValidCreate(_signature, _campaign.externalId, _campaign.fee, address(this), authorizerAddress)
        ensureUniqueCampaignExternalId(_campaign.externalId)
        nonReentrant
        returns (uint256)
    {
        require(_campaign.ordersPerWallet > 0, "You must allow at least 1 order per wallet");
        require(_campaign.maxOrders > 0, "You must allow at least 1 order");
        require(_campaign.paymentAddress != address(0), "NFT contract address cannot be 0x0");

        campaignList[campaignCounter] = Campaign({
            id: campaignCounter,
            externalId: _campaign.externalId,
            creator: _campaign.creator,
            paymentAddress: _campaign.paymentAddress,
            minted: false,
            fee: _campaign.fee,
            price: _campaign.price,
            maxOrders: _campaign.maxOrders,
            ordersTotal: 0,
            ordersPerWallet: _campaign.ordersPerWallet,
            campaignBalance: 0
        });
        emit CampaignCreated(campaignList[campaignCounter]);
        campaignCounter++;
        return campaignCounter - 1;
    }

    function deleteCampaign(uint256 _campaignId) public onlyOwner {
        delete campaignList[_campaignId];
    }

    function setUnMinted(uint256 _campaignId) public onlyOwner {
        campaignList[_campaignId].minted = false;
    }

    function updatePaymentAddress(uint256 _campaignId, address _paymentAddress) public {
        require(_paymentAddress != address(0), "Contract address cannot be 0");
        require(
            campaignList[_campaignId].creator == msg.sender || msg.sender == owner(),
            "You must be the creator of this campaign to update the address"
        );
        campaignList[_campaignId].paymentAddress = _paymentAddress;
    }

    function executeMintForCampaigns(uint256[] memory _campaignIds) public nonReentrant {
        for (uint256 i = 0; i < _campaignIds.length; i++) {
            executeMintForCampaign(_campaignIds[i]);
        }
    }

    function reserveOrder(uint256 _campaignId, uint8 _requestedOrderQuantity, bytes memory _signature)
        public
        payable
        isValidReserve(_signature, _campaignId, address(this), authorizerAddress)
    {
        Campaign storage campaign = campaignList[_campaignId];
        uint256 totalPrice = campaignList[_campaignId].price * _requestedOrderQuantity;
        require(msg.value >= totalPrice, "Not enough ETH sent");
        require(
            paidOrders[_campaignId][msg.sender] + _requestedOrderQuantity <= campaign.ordersPerWallet,
            "You cannot own more than the max orders per wallet"
        );
        require(campaign.maxOrders >= campaign.ordersTotal + _requestedOrderQuantity, "No more orders available");

        paidOrders[_campaignId][msg.sender] += _requestedOrderQuantity;
        uint8 walletOrders = paidOrders[_campaignId][msg.sender];
        addPaidOrdersAddress(_campaignId, msg.sender);
        campaign.ordersTotal += _requestedOrderQuantity;
        campaign.campaignBalance += campaign.price * _requestedOrderQuantity;
        emit OrderCreated(
            Order({
                campaignId: _campaignId,
                purchaserAddress: msg.sender,
                quantity: _requestedOrderQuantity,
                campaignOrdersTotal: campaign.ordersTotal,
                walletOrdersTotal: walletOrders,
                externalId: campaign.externalId
            })
        );
    }

    function updateWalletAddress(uint256 _campaignId, address _newAddress) public nonReentrant {
        require(paidOrders[_campaignId][msg.sender] > 0, "You must own at least 1 order to update your address");
        paidOrders[_campaignId][_newAddress] = paidOrders[_campaignId][msg.sender];
        delete paidOrders[_campaignId][msg.sender];
    }

    function withdraw() public onlyOwner {
        (bool owner,) = payable(owner()).call{value: address(this).balance}("");
        require(owner);
    }

    function withdrawAmount(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough funds");
        (bool owner,) = payable(owner()).call{value: _amount}("");
        require(owner);
    }

    ////////////////////////////////
    //   Internal Functions       //
    ////////////////////////////////

    function executeMintForCampaign(uint256 _campaignId) internal {
        require(
            campaignList[_campaignId].creator == msg.sender || msg.sender == owner(),
            "You must be the creator of this campaign to trigger the mint"
        );
        require(campaignList[_campaignId].minted == false, "This campaign has already been minted");
        require(
            campaignList[_campaignId].paymentAddress != address(0),
            "You must set the address of the mint contract before minting"
        );
        campaignList[_campaignId].minted = true;
        for (uint256 i = 0; i < paidOrdersAddresses[_campaignId].length; i++) {
            address key = paidOrdersAddresses[_campaignId][i];
            uint8 orders = paidOrders[_campaignId][key];
            uint256 value = (orders * campaignList[_campaignId].price)
                - (orders * campaignList[_campaignId].price * campaignList[_campaignId].fee / 100);
            if (orders > 0) {
                IERC721Contract(campaignList[_campaignId].paymentAddress).earlyMint{value: value}(
                    key, orders, _campaignId
                );
            }
        }
    }

    function addPaidOrdersAddress(uint256 _campaignId, address _paidOrdersAddress) internal {
        bool exists = false;
        for (uint256 i = 0; i < paidOrdersAddresses[_campaignId].length; i++) {
            if (paidOrdersAddresses[_campaignId][i] == _paidOrdersAddress) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            paidOrdersAddresses[_campaignId].push(_paidOrdersAddress);
        }
    }

    ///////////////////////////
    //    VIEW FUNCTIONS  /////
    //////////////////////////

    function getPriceToReserveOrders(uint256 _campaignId, uint8 _quantity) public view returns (uint256) {
        return campaignList[_campaignId].price * _quantity;
    }

    function getCampaignByExternalId(string memory _externalId) public view returns (Campaign memory) {
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (keccak256(abi.encodePacked(campaignList[i].externalId)) == keccak256(abi.encodePacked(_externalId))) {
                return campaignList[i];
            }
        }
        revert("Campaign not found");
    }

    function getPaymentAddress(uint256 _campaignId) public view returns (address) {
        return campaignList[_campaignId].paymentAddress;
    }

    function getPaidOrdersByCampaignId(uint256 _campaignId) public view returns (address[] memory) {
        return paidOrdersAddresses[_campaignId];
    }

    function getMyCampaignIDs() public view returns (uint256[] memory) {
        uint256[] memory campaigns = new uint256[](campaignCounter);
        uint256 counter = 0;
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (campaignList[i].creator == msg.sender) {
                campaigns[counter] = i;
                counter++;
            }
        }
        return campaigns;
    }

    function getCampaignsManagedByAddress(address _creator) public view returns (uint256[] memory) {
        uint256[] memory campaigns = new uint256[](campaignCounter);
        uint256 counter = 0;
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (campaignList[i].creator == _creator) {
                campaigns[counter] = i;
                counter++;
            }
        }
        return campaigns;
    }
}
