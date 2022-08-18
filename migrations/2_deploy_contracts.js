var app = artifacts.require("ZoidsNFT");

module.exports = function (deployer) {
    require("dotenv").config();
    const name = process.env.CONTRACT_NAME;
    const symbol = process.env.CONTRACT_SYMBOL;
    const baseUri = process.env.TOKEN_BASE_URI;
    const coinContractAddress = process.env.COIN_CONTRACT_ADDRESS;
    const coinWalletAddress = process.env.COIN_WALLET_ADDRESS;
    deployer.deploy(app, name, symbol, baseUri, coinContractAddress, coinWalletAddress);
};
