// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract Voting{
    /*errors*/
    error voting__onlyChairPerson();
    error voting__alreadyVoted();
    error voting__alreadyGivenVotingRights(); 
    error voting__noVotingRights();
    error voting__cannotDelegateOneself(); 
    error voting__loopInDelegation(); 
    error voting__proposalNotFound(); 
    error voting__thereIsATie(); 

    /*Structs*/
    struct Voter{
        uint weight; // the weight of their vote
        bool voted; // true if already voted
        address delegate; // to whom they delegated their vote
        uint vote; // index of the proposal they voted for
    }

    struct Proposal{
        bytes32 name; // the name of the proposal 
        uint voteCount; // the number of accumulated votes
    }

    /*Variables*/
    address private chairPerson; //assigns the person who owns the contract and can give voting rights

    mapping (address => Voter) private voters; //connects an address to a voter struct

    Proposal[] private proposals; //list the number of proposals

    /*Functions*/
    constructor(bytes32[] memory proposalNames){
        chairPerson = msg.sender; //sets the deployer as the chairperson
        voters[chairPerson].weight = 1; //gives voting power to the chairperson

        for(uint i=0 ; i< proposalNames.length; i++){
            // this for loop populates the Proposal array with the proposal names provided in the input of the constructor
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
        }));
        }
    }

    function giveRightToVote(address _voter) public onlyChairPerson{ // gives votes to a certain voter
        require(!voters[_voter].voted, voting__alreadyVoted()); //prevents giving votes to people who has voted
        require(voters[_voter].weight == 0, voting__alreadyGivenVotingRights()); //prevents giving votes to people who alredy has voting rights
        voters[_voter].weight = 1; // sets the voting weight of the voter to 1 
    }

    function delegate(address _delegated) public{ // delegates a vote to a person 
        require(voters[msg.sender].weight > 0, voting__noVotingRights()); //prevents a person without voting rights to delegate
        require(!voters[msg.sender].voted, voting__alreadyVoted()); //prevents a person who has already voted to delegate
        require(_delegated != msg.sender, voting__cannotDelegateOneself()); //preventas a person to delegate to him/herself

        //a while loop to allow a chain of delegations
        while(voters[_delegated].delegate != address(0)){
            //while a voter has a delegate the while loop will keep assigning the _delegated as the next delegate
            //until the loop finds a delegate that doesn't have another delegate
            _delegated = voters[_delegated].delegate; 

            // this require function prevents a loop in a delegation
            require(msg.sender != _delegated, voting__loopInDelegation()); 
        }

        voters[msg.sender].voted = true; // indicates that the voter already voted
        voters[msg.sender].delegate = _delegated; //sets the delegate of a voter

        if(voters[_delegated].voted){
            // if the delegate have already voted than the voter weigth will be added to the proposal's voteCount
            proposals[voters[_delegated].vote].voteCount += voters[msg.sender].weight;
        } else {
            // if the delegate have not voted than the voter weigth will be added to the delegate's weight
            voters[_delegated].weight += voters[msg.sender].weight;
        }
    }

    function vote(uint256 _vote) public{ // allows a voter to vote
        require(voters[msg.sender].weight > 0, voting__noVotingRights()); // prevents a person without a voting right to vote
        require(!voters[msg.sender].voted, voting__alreadyVoted());// prevents a person that has already voted to vote
        require(_vote < proposals.length, voting__proposalNotFound());// prevents a person to vote for an invalid proposal

        voters[msg.sender].vote = _vote; // sets the voter of the voter to the proposal index

        proposals[_vote].voteCount += voters[msg.sender].weight; // adds the weight of the vote to the proposal's vote count

        voters[msg.sender].voted = true; // sets the voted of the voter to true, indicating that the voter has already voted
    }

    function winningProposal() internal view returns(uint proposalIndex){
        require(!tie(), voting__thereIsATie());
        // this function finds the index of the winning proposal 
        uint highestVoteCount = 0; //keep track of the proposal with the most vote count
        uint winnerIndex = 0; // keep track of the index of the proposal with the most vote count
        for(uint i=0 ; i < proposals.length; i++){
            // this for loop finds the index of the proposal with the highest voteCount
            if(proposals[i].voteCount > highestVoteCount){
                highestVoteCount = proposals[i].voteCount; 
                winnerIndex = i; 
            }
        }
        return winnerIndex;
    }

    function winnerName() public view returns(bytes32 WinnerName){
        // returns the name of the proposal with the most voteCount
        // uses the winningProposal() function to get the index of the winning proposal 
        WinnerName = proposals[winningProposal()].name; 
    }

    function tie() internal view returns(bool){
        uint256 highestVoteCount;
        uint256 NumberOfProposalWithHighestVoteCount; 
        for(uint i=0 ; i < proposals.length; i++){
            // this for loop finds the index of the proposal with the highest voteCount
            if(proposals[i].voteCount > highestVoteCount){
                highestVoteCount = proposals[i].voteCount; 
            }
        }
        for(uint i=0 ; i < proposals.length; i++){
            // this for loop finds the index of the proposal with the highest voteCount
            if(proposals[i].voteCount == highestVoteCount){
                NumberOfProposalWithHighestVoteCount++;
            }
        }
        return NumberOfProposalWithHighestVoteCount > 1;
    }

    /*Getters*/
    function getChairPerson() public view returns(address) {
        return chairPerson; 
    }

    function getVoter(address _voterAddress) public onlyChairPerson view returns(Voter memory) {
        return voters[_voterAddress]; 
    }

    function getProposal(uint _proposalIndex) public view returns(Proposal memory){
        return proposals[_proposalIndex]; 
    }

    /*modifiers*/
    modifier onlyChairPerson(){
        require(msg.sender == chairPerson, voting__onlyChairPerson());
        _;
    }
}