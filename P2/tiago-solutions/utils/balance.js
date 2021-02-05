const Web3 = require("web3");

const { MY_ADDR, PROVIDER_URL } = require("../config/dotenv");

const w3 = new Web3(PROVIDER_URL);
const myAddr = w3.utils.toChecksumAddress(MY_ADDR);

async function getBalance(address) {
    const checksum_addr = w3.utils.toChecksumAddress(address);
    return w3.utils.fromWei(await w3.eth.getBalance(checksum_addr), "ether");
}

function getMyBalance() {
    return getBalance(myAddr);
}

module.exports = {
    getBalance,
    getMyBalance,
};
