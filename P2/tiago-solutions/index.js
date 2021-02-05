const {
    BadParitySolution,
    DaodownSolution,
    FailDiceSolution,
    NotAWalletSolution,
} = require("./solutions/index");

const solutions = {
    "badparity": BadParitySolution,
    "daodown": DaodownSolution,
    "faildice": FailDiceSolution,
    "notawallet": NotAWalletSolution,
};

const args = process.argv.slice(2);
main();

async function main() {
    try {
        if (args.length > 0) {
            if (solutions[args[0]]) {
                await (new solutions[args[0]]()).run();
            } else {
                console.log("Invalid solution", Object.keys(solutions).join(", "));
                process.exit(1);
            }
        } else {
            for (const sol in solutions) {
                await (new solutions[sol]()).run();
            }
        }
    } catch (err) {
        console.log(err);
    }
}
