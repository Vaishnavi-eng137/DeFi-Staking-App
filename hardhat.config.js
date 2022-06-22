require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");


module.exports = {
  solidity: "0.8.7",
  namedAccounts:{
    deployer:{
      default:0, // ethers built in accounts at index 0
    },
  },
};
