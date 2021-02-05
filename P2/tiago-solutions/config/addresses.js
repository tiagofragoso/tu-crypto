const fs = require("fs");
const { ADDRESSES_FILE } = require("./dotenv");

const file = fs.readFileSync(ADDRESSES_FILE, "utf-8");

const addresses = {};

file.split("\n").forEach((line) => {
    const [key, addr] = line.split("=");
    addresses[key.trim()] = addr.trim();
});

module.exports = {
    NOTAWALLET_ADDR: addresses["notawallet_addr"],
    BADPARITY_ADDR: addresses["badparity_addr"],
    DAODOWN_ADDR: addresses["daodown_addr"],
    FAILDICE_ADDR: addresses["faildice_addr"],
};
