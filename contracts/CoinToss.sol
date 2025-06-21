// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CoinToss {
    address public owner;
    uint256 public minimumBet;
    uint256 public houseEdge;

    enum Side { Heads, Tails }

    struct Game {
        address player;
        uint256 betAmount;
        Side choice;
        Side result;
        bool won;
        uint256 timestamp;
    }

    Game[] public gameHistory;
    mapping(address => uint256) public playerWins;
    mapping(address => uint256) public playerLosses;

    event BetPlaced(address indexed player, uint256 amount, Side choice, uint256 gameId);
    event BetResult(address indexed player, bool won, uint256 amountWon, Side result, uint256 gameId);
    event ContractFunded(uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    /// @notice Initializes contract with default parameters (no inputs required)
    constructor() {
        owner = msg.sender;
        minimumBet = 0.01 ether;      // Default minimum bet of 0.01 CORE
        houseEdge   = 5;              // Default house edge of 5%
    }

    receive() external payable {
        emit ContractFunded(msg.value);
    }

    function bet(Side _choice) external payable {
        require(msg.value >= minimumBet, "Bet amount too low");
        require(address(this).balance >= msg.value * 2, "Insufficient contract balance");

        uint256 gameId = gameHistory.length;
        emit BetPlaced(msg.sender, msg.value, _choice, gameId);

        Side result = _randomSide();
        bool won = (_choice == result);

        gameHistory.push(Game({
            player: msg.sender,
            betAmount: msg.value,
            choice: _choice,
            result: result,
            won: won,
            timestamp: block.timestamp
        }));

        if (won) {
            uint256 commission = (msg.value * houseEdge) / 100;
            uint256 payout     = (msg.value * 2) - commission;
            payable(msg.sender).transfer(payout);
            playerWins[msg.sender]++;
            emit BetResult(msg.sender, true, payout, result, gameId);
        } else {
            playerLosses[msg.sender]++;
            emit BetResult(msg.sender, false, 0, result, gameId);
        }
    }

    function fundContract() external payable onlyOwner {
        emit ContractFunded(msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }

    function _randomSide() private view returns (Side) {
    uint256 hash = uint256(keccak256(abi.encodePacked(
        block.timestamp,
        block.prevrandao,  // ✅ Use prevrandao instead of deprecated block.difficulty
        msg.sender,
        block.number
    )));
    return (hash % 2 == 0 ? Side.Heads : Side.Tails);
}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner"); 
        _;
    }
}
