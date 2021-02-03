const Web3 = require("web3");

const PASSWORD = "habhmen9MnF73UkVqY7zLeJiTfX9TAiP";
const ALICE_ADDR = "50445bd057143483c88a01594e088320d815eEc3";
const BOB_ADDR = "66f48D08DBf8AE9c354dEbd1FC031C733A77d817";
const w3 = new Web3("http://localhost:55003");

async function getBalance(address) {
    const checksum_addr = w3.utils.toChecksumAddress(address);
    return w3.utils.fromWei(await w3.eth.getBalance(checksum_addr), "ether");
}

async function setup() {
    console.log(await getBalance(BOB_ADDR));
    // sendToBob(16*10**18);
}

async function sendToBob(amount) {
    const alice_checksum = w3.utils.toChecksumAddress(ALICE_ADDR);
    const bob_checksum = w3.utils.toChecksumAddress(BOB_ADDR);
    console.log(await w3.eth.sendTransaction({
        "from": alice_checksum,
        "to": bob_checksum,
        "value": amount,
    }));
}

setup();
