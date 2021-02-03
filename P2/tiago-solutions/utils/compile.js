const solc = require("solc");
const fs = require("fs");
const { promisify } = require("util");

function resolveImports(path) {
    return fs.existsSync(path) ?
        { contents: fs.readFileSync(path, "utf-8") } :
        { error: "File not found" };
}

async function compile(fileName, source) {
    const loadLegacySolc = promisify(solc.loadRemoteVersion);
    try {
        const legacySolc = await loadLegacySolc("v0.5.4+commit.9549d8ff");
        const input = {
            language: "Solidity",
            sources: {
                [fileName]: {
                    content: source,
                },
            },
            settings: {
                outputSelection: {
                    "*": {
                        "*": ["*"],
                    },
                },
            },
        };
        const output = JSON.parse(legacySolc.compile(JSON.stringify(input), { import: resolveImports }));
        return output.contracts[fileName];
    } catch (err) {
        console.error(err);
        return null;
    }
}

module.exports = compile;
