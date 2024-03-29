const { ethers} = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS} = require("../constants");

async function main() {
    const FakeNFTMarketplace = await ethers.getContractFactory(
        "FakeNFTMarketPlace"
    );
    const fakeNftMarketplace = await FakeNFTMarketplace.deploy();
    await fakeNftMarketplace.deployed();
    console.log("FakeNFTMarkeplace deployed to:", fakeNftMarketplace.address);

    const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
    const cryptoDevsDAO = await CryptoDevsDAO.deploy(
        fakeNftMarketplace.address,CRYPTODEVS_NFT_CONTRACT_ADDRESS,{
            value: ethers.utils.parseEther("0.05")
        }
    );
    await cryptoDevsDAO.deployed();
    console.log("CryptoDevsDAO deployed to ", cryptoDevsDAO.address);
}
main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});