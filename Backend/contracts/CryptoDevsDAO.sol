//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

         interface IFakeNFTMarketplace {

            function getPrice() external view returns (uint256);
            function available(uint256 _tokenId) external view returns(bool);
            function purchase( uint256 _tokenId) external payable;
         }

         interface ICryptoDevsNFT {

            function balanceOf(address owner) external view returns(uint256);
            function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

         }

         contract CryptoDevsDAO is Ownable {

          enum Vote {
                YAY,
                NAY
             }
            
             struct Proposal {
                // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
                    uint256 nftTokenId;
                    // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
                    uint256 deadline;
                    // yayVotes - number of yay votes for this proposal
                    uint256 yayVotes;
                    // nayVotes - number of nay votes for this proposal
                    uint256 nayVotes;
                    // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
                    bool executed;
                    // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
                    mapping(uint256 => bool) voters;
                   }   

                 mapping(uint256 => Proposal) public proposals;
                 uint256 public numProposals;

                IFakeNFTMarketplace nftMarketplace;
                ICryptoDevsNFT cryptoDevsNFT;

                constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
                    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
                    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
                }
            
              modifier nftHolderOnly() {
                 require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT A DAO MEMBER");
                _;
              }

             function createProposal(uint256 _nfttokenId) external nftHolderOnly returns(uint256){

                require(nftMarketplace.available(_nfttokenId), "NFT NOT FOR SALE");
                Proposal storage proposal = proposals[numProposals];
                proposal.nftTokenId = _nfttokenId;
                proposal.deadline = block.timestamp + 5 minutes; 
                numProposals++;
                return numProposals - 1;
             }

             modifier activeProposalOnly(uint256 proposalIndex) {
                require(proposals[proposalIndex].deadline > block.timestamp, "DEADLINE EXCEEDED");
                _;
             }

             function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
                Proposal storage proposal = proposals[proposalIndex];
                uint256 voteNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
                uint256 numVotes = 0;
                // Calculating how many NFTs are owned by the voter
                // that haven't already been used for voting on this proposal
                for(uint256 i = 0; i < voteNFTBalance; i++){
                    uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
                    if(proposal.voters[tokenId] == false){
                        numVotes++;
                        proposal.voters[tokenId] = true;
                    }
                }
                require(numVotes > 0, "ALREADY VOTED");
                if(vote == Vote.YAY){
                    proposal.yayVotes += numVotes;
                } else {
                    proposal.nayVotes += numVotes;
                }
            }

            modifier inactiveProposalOnly(uint256 proposalIndex){
                require(proposals[proposalIndex].deadline <= block.timestamp, "DEADLINE NOT EXCEEDED");
                require(proposals[proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");
                _;
            }

            function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex){
                Proposal storage proposal = proposals[proposalIndex];
                if(proposal.yayVotes > proposal.nayVotes){
                    uint256 nftPrice = nftMarketplace.getPrice();
                    require(address(this).balance >= nftPrice, "NOT ENOUGH ETHER");
                    nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
                }
                proposal.executed = true;
            }

            function withdrawEther() external onlyOwner {
                payable(owner()).transfer(address(this).balance);
            }
            // The following two functions allow the contract to accept ETH deposits
            // directly from a wallet without calling a function
            receive() external payable {}

            fallback() external payable {}

        }