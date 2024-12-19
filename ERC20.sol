// SPDX-License-Identifier: GPL-3.0

pragma solidity <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract ERC20 is IERC20 {
    uint256 public totalSupply;
    string public tokenName;
    string public symbol;
    address public owner;

    constructor(
        string memory _TokenName,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        totalSupply = _totalSupply;
        tokenName = _TokenName;
        symbol = _symbol;
        owner = msg.sender;
    }

    modifier onlyowner() {
        require(owner == msg.sender, "You are not Owner");
        _;
    }
    mapping(address => uint256) public balanceOfUser;
    mapping(address => mapping(address => uint256)) public allowenceToken;

    function balanceOf(address account) external view returns (uint256) {
        return balanceOfUser[account];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOfUser[msg.sender] >= value, "Insufficent Funds");
        balanceOfUser[msg.sender] -= value;
        balanceOfUser[to] += value;

        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256)
    {
        require(
            spender != address(0) && _owner != address(0),
            "Invalid address"
        );
        return allowenceToken[_owner][spender];
    }

    function approve(address spender, uint256 value)
        external
        onlyowner
        returns (bool)
    {
        require(spender != address(0), "Invalid address");
        require(balanceOfUser[msg.sender] >= value, "Insufficent Funds");
        allowenceToken[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(from != address(0) && to != address(0), "Invalid address");
        require(
            allowenceToken[from][to] >= value,
            "Insufficent Funds in owner Account"
        );
        balanceOfUser[from] -= value;
        balanceOfUser[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function Tokenname() public view returns (string memory) {
        return tokenName;
    }

    function TokenSymbol() public view returns (string memory) {
        return symbol;
    }
}
