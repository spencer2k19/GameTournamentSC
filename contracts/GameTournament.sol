// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GameTournament is Ownable {
    struct Tournament {
        uint256 minimumBet;
        bool isStarted;
        uint256 minimumUserNumber;
        uint256 winnerNumber;
        uint[] percents;
        mapping(string => address) users;
        mapping(address =>uint) winners;
        mapping(address => bool) rewardsClaimed;
        uint totalPrice;

    }


    //Mapping to keep track of which tournaments
    mapping(uint256 => uint256) public indexTournaments;
    Tournament[] public allTournaments;

    //Mapping to keep track of owner of tournaments
    mapping(uint256 => address) public ownerTournaments;

    uint numTournaments;


    //event when creating new tournament
    event TournamentAdded(uint256 tournamentId,address user);



    //add tournament
    function addTournament(uint256 tournamentId,uint256 minimumBet,
        uint256 minimumUserNumber,
        uint256 winnerNumber,
        uint256[] memory percents
    ) external {

        require(winnerNumber > 0,"Number of winner must be greater than zero");
        require(minimumUserNumber >0, "Number of users must be greater than zero");
        Tournament storage tournament = allTournaments.push();
        tournament.minimumBet = minimumBet;
        tournament.isStarted = false;
        tournament.minimumUserNumber = minimumUserNumber;
        tournament.winnerNumber = winnerNumber;
        tournament.percents = percents;
        indexTournaments[tournamentId] = allTournaments.length-1;
        ownerTournaments[tournamentId] = msg.sender;
        emit TournamentAdded(tournamentId,msg.sender);
    }

    //start tournament
    function startTournament(uint256 tournamentId) public {
        require(msg.sender == ownerTournaments[tournamentId],"You are not the owner of tournament");
        Tournament storage tournament = allTournaments[indexTournaments[tournamentId]];
        tournament.isStarted = true;
    }

    //register user to tournament
    function registerToTournament(uint256 tournamentId,string memory nickname) public payable {
        Tournament storage tournament = allTournaments[indexTournaments[tournamentId]];
        require(msg.value >= tournament.minimumBet,"Ether sent is not correct");
        tournament.users[nickname] = msg.sender;
        tournament.totalPrice += msg.value;
    }





    //to abandon
    function abandon(uint256 tournamentId,string memory nickname) public payable {
        Tournament storage tournament = allTournaments[indexTournaments[tournamentId]];
        tournament.users[nickname] = address(0);

    }

    //One winner
    function addWinner(uint256 tournamentId,string memory winnerNickname) external {
        Tournament storage tournament = allTournaments[indexTournaments[tournamentId]];
        address userAddress = tournament.users[winnerNickname];
        tournament.winners[userAddress] = (tournament.totalPrice *98) /100;

    }


    //cash prices
    function addWinners(uint256 tournamentId,string[] memory nicknames) external {
        Tournament storage tournament = allTournaments[indexTournaments[tournamentId]];
        require(tournament.percents.length == nicknames.length,"Le nombre de vainqueur doit correspondre aux pourcentages");
        for(uint256 i = 0; i< nicknames.length;i++) {
            address userAddress = tournament.users[nicknames[i]];
            tournament.winners[userAddress] = ((tournament.totalPrice * tournament.percents[i]) *(tournament.totalPrice *98) )/10000;
        }

    }

    //claim rewards
    function claimRewards(uint256 tournamentId,string memory nickname) public payable {

        Tournament storage tournament = allTournaments[indexTournaments[tournamentId]];
        address userAddress = tournament.users[nickname];
        require(tournament.winners[userAddress] >0, "You are not one of the winners");
        require(!tournament.rewardsClaimed[userAddress],"You have already claimed your rewards");
        tournament.rewardsClaimed[userAddress] = true;

        //make the payment
        (bool sent, ) =  userAddress.call{value: tournament.winners[userAddress]}("");
        require(sent,"Failed to sent Ether");
    }



    /**
  * @dev withdraw sends all the ether in the contract
  * to the owner of the contract
   */

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent,"Failed to sent Ether");
    }


// Function to receive Ether. msg.data must be empty
receive() external payable {}

// Fallback function is called when msg.data is not empty
fallback() external payable {}


}
