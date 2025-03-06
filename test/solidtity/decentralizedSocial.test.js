const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DecentralizedSocial", function () {
  let DecentralizedSocial;
  let decentralizedSocial;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    // 获取合约工厂
    DecentralizedSocial = await ethers.getContractFactory(
      "DecentralizedSocial"
    );

    // 获取测试账户
    [owner, user1, user2] = await ethers.getSigners();

    // 部署合约
    decentralizedSocial = await DecentralizedSocial.deploy();
    await decentralizedSocial.deployed();
  });

  describe("用户资料管理", function () {
    it("应该能够创建用户资料", async function () {
      await decentralizedSocial
        .connect(user1)
        .createProfile("Alice", "我是Alice", "ipfs://avatar1");

      const profile = await decentralizedSocial.getProfile(user1.address);
      expect(profile.username).to.equal("Alice");
      expect(profile.bio).to.equal("我是Alice");
      expect(profile.avatar).to.equal("ipfs://avatar1");
    });

    it("不能创建重复的用户名", async function () {
      await decentralizedSocial
        .connect(user1)
        .createProfile("Alice", "我是Alice", "ipfs://avatar1");

      await expect(
        decentralizedSocial
          .connect(user2)
          .createProfile("Alice", "另一个Alice", "ipfs://avatar2")
      ).to.be.revertedWith("用户名已存在");
    });
  });

  describe("发帖功能", function () {
    beforeEach(async function () {
      await decentralizedSocial
        .connect(user1)
        .createProfile("Alice", "我是Alice", "ipfs://avatar1");
    });

    it("应该能够发布帖子", async function () {
      await decentralizedSocial
        .connect(user1)
        .createPost("这是我的第一条帖子", "ipfs://content1");

      const post = await decentralizedSocial.getPost(0);
      expect(post.author).to.equal(user1.address);
      expect(post.content).to.equal("这是我的第一条帖子");
      expect(post.mediaUrl).to.equal("ipfs://content1");
    });

    it("未注册用户不能发帖", async function () {
      await expect(
        decentralizedSocial.connect(user2).createPost("未注册用户的帖子", "")
      ).to.be.revertedWith("用户未注册");
    });
  });

  describe("关注功能", function () {
    beforeEach(async function () {
      await decentralizedSocial
        .connect(user1)
        .createProfile("Alice", "我是Alice", "ipfs://avatar1");
      await decentralizedSocial
        .connect(user2)
        .createProfile("Bob", "我是Bob", "ipfs://avatar2");
    });

    it("应该能够关注其他用户", async function () {
      await decentralizedSocial.connect(user1).followUser(user2.address);

      const isFollowing = await decentralizedSocial.isFollowing(
        user1.address,
        user2.address
      );
      expect(isFollowing).to.be.true;
    });

    it("应该能够取消关注", async function () {
      await decentralizedSocial.connect(user1).followUser(user2.address);
      await decentralizedSocial.connect(user1).unfollowUser(user2.address);

      const isFollowing = await decentralizedSocial.isFollowing(
        user1.address,
        user2.address
      );
      expect(isFollowing).to.be.false;
    });
  });

  describe("点赞功能", function () {
    beforeEach(async function () {
      await decentralizedSocial
        .connect(user1)
        .createProfile("Alice", "我是Alice", "ipfs://avatar1");
      await decentralizedSocial.connect(user1).createPost("测试帖子", "");
    });

    it("应该能够给帖子点赞", async function () {
      await decentralizedSocial.connect(user2).likePost(0);

      const likes = await decentralizedSocial.getPostLikes(0);
      expect(likes).to.equal(1);
    });

    it("同一用户不能重复点赞", async function () {
      await decentralizedSocial.connect(user2).likePost(0);

      await expect(
        decentralizedSocial.connect(user2).likePost(0)
      ).to.be.revertedWith("已经点赞过了");
    });
  });
});
