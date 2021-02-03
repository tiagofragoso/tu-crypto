const Web3 = require("web3");

const BOB_ADDR = "66f48D08DBf8AE9c354dEbd1FC031C733A77d817";
const w3 = new Web3("http://localhost:55007");
const BADDR_CS = w3.utils.toChecksumAddress(BOB_ADDR);

async function getBalance(address) {
    const checksum_addr = w3.utils.toChecksumAddress(address);
    return w3.utils.fromWei(await w3.eth.getBalance(checksum_addr), "ether");
}

function getMyBalance() {
    return getBalance(BADDR_CS);
}

module.exports = {
    getBalance,
    getMyBalance,
};
