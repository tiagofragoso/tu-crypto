const Web3 = require("web3");

const { getBalance, getMyBalance } = require("../utils/balance");
const { MY_ADDR, PASSWORD, PROVIDER_URL } = require("../config/dotenv");

class Solution {
    constructor(_challengeAddr) {
        this.w3 = new Web3(PROVIDER_URL);
        this.myAddr = this.w3.utils.toChecksumAddress(MY_ADDR);
        this.challengeAddr = this.w3.utils.toChecksumAddress(_challengeAddr);
        this.w3.eth.defaultAccount = this.myAddr;
    }

    unlock() {
        return this.w3.eth.personal.unlockAccount(this.myAddr, PASSWORD, 0);
    }

    async printBalances() {
        const [myBalance, challangeBallance] = await Promise.all([getMyBalance(), getBalance(this.challengeAddr)]);
        console.log("My balance:", myBalance);
        console.log("Challenge balance:", challangeBallance);
        return Promise.resolve();
    }
}

module.exports = Solution;
