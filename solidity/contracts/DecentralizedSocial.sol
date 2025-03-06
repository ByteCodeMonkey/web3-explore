// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 代币合约
contract SocialToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("SocialToken", "SCT") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10 ** decimals()); // 初始铸造 100 万 SCT
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

// 社交平台合约
contract DecentralizedSocial {
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 likes;
        uint256 timestamp;
    }

    SocialToken public token;
    uint256 public postCount;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => mapping(address => bool)) public liked;

    event PostCreated(uint256 id, address author, string content, uint256 timestamp);
    event PostLiked(uint256 id, address liker, uint256 newLikeCount);

    constructor(address tokenAddress) {
        token = SocialToken(tokenAddress);
    }

    function initializeOwnership() external {
        require(token.owner() == msg.sender, "Only the current owner can transfer ownership");
        token.transferOwnership(address(this));
    }

    function createPost(string memory _content) external {
        require(bytes(_content).length > 0, "Content cannot be empty");
        postCount++;
        posts[postCount] = Post(postCount, msg.sender, _content, 0, block.timestamp);
        emit PostCreated(postCount, msg.sender, _content, block.timestamp);
    }

    function likePost(uint256 _id) external {
        require(posts[_id].id != 0, "Post does not exist");
        require(!liked[_id][msg.sender], "You already liked this post");

        posts[_id].likes++;
        liked[_id][msg.sender] = true;

        // 给予作者奖励
        token.mint(posts[_id].author, 10 * 10 ** token.decimals());

        emit PostLiked(_id, msg.sender, posts[_id].likes);
    }

    function getPost(uint256 _id) external view returns (Post memory) {
        return posts[_id];
    }
}
