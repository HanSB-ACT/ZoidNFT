var app = artifacts.require("NFTV1");

module.exports = function (deployer) {
    require("dotenv").config();
    const name = process.env.CONTRACT_NAME;
    const symbol = process.env.CONTRACT_SYMBOL;
    deployer.deploy(app, name, symbol);
};
