var app = artifacts.require("ZoidsNFT");

module.exports = function (deployer) {
    require("dotenv").config();
    const ver = process.env.CONTRACT_VERSION;
    const name = process.env.CONTRACT_NAME;
    const symbol = process.env.CONTRACT_SYMBOL;
    const baseUri = process.env.TOKEN_BASE_URI;
    const erc20 = process.env.ERC20_CONTRACT_ADDRESS;
    deployer.deploy(app, ver, name, symbol, baseUri, erc20);
};
