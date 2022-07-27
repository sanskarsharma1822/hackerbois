import Moralis from "moralis";
import dotenv from "dotenv";
dotenv.config();

async function storeData(
  name,
  imageData,
  serialNumber,
  productLink,
  description,
  price
) {
  const serverUrl = process.env.SERVER_URL;
  const appId = process.env.APP_ID;
  const masterKey = process.env.MASTER_KEY;

  Moralis.start({ serverUrl, appId, masterKey });

  const web3 = await Moralis.Web3.enable();
  const chainIdDec = await web3.eth.getChainId();
  await Moralis.enableWeb3({ chainId: chainIdDec });

  const image = await uploadImage(imageData);
  const result = [];
  const tokenURI = await uploadMetaData(
    name,
    image,
    serialNumber,
    productLink,
    description,
    price
  );

  result.push(tokenURI);

  const historyURI = await storeHistory(image);
  result.push(historyURI);

  return result;
}

async function storeHistory(image) {
  metaData = {
    name: "History",
    image: image,
    description:
      "This JSON Data shows the Repair History and Owner History for NFT",
    repairHistory: [],
    ownerHistory: [],
  };
  const file = new Moralis.File("file.json", {
    base64: btoa(JSON.stringify(metaData)),
  });
  await file.saveIPFS();

  console.log("History : ", file.ipfs());
  return file.ipfs();
}

async function uploadMetaData(
  name,
  imageData,
  serialNumber,
  productLink,
  description,
  price
) {
  const image = uploadImage(imageData);
  metaData = {
    name: name,
    image: image,
    serialNumber: serialNumber,
    productLink: productLink,
    description: description,
    price: price,
  };
  const file = new Moralis.File("file.json", {
    base64: btoa(JSON.stringify(metaData)),
  });
  await file.saveIPFS();
  console.log(file.ipfs());
  return file.ipfs();
}

async function uploadImage(fileInput) {
  const data = fileInput.files[0];
  console.log(data);
  const file = new Moralis.File(data.name, data);
  console.log(file);
  await file.saveIPFS();
  return file.ipfs();
}

storeData().catch((err) => {
  console.error(err);
  process.exit(1);
});
