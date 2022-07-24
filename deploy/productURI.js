import { NFTStorage, File } from "nft.storage";
import mime from "mime";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
dotenv.config();

const NFT_STORAGE_KEY = process.env.NFT_STORAGE_KEY;

async function storeNFT(
  name,
  imagePath,
  serialNumber,
  productLink,
  description,
  price
) {
  const image = await fileFromPath(imagePath);

  const nftstorage = new NFTStorage({ token: NFT_STORAGE_KEY });

  return nftstorage.store({
    image,
    name,
    serialNumber,
    productLink,
    description,
    price,
  });
}

async function fileFromPath(filePath) {
  const content = await fs.promises.readFile(filePath);
  const type = mime.getType(filePath);
  return new File([content], path.basename(filePath), { type });
}

async function main() {
  const name =
    "LG OLED A1 Series 164 cm (65 inch) OLED Ultra HD (4K) Smart WebOS TV";

  //PATH GOES HERE
  const imagePath = "";

  const serialNumber = "TVSG3UW3RV7DFYUW";
  const productLink =
    "https://www.flipkart.com/lg-oled-a1-series-164-cm-65-inch-ultra-hd-4k-smart-webos-tv/p/itm951bbb2181b16";
  const description =
    "Supported Apps: Netflix|Prime Video|Disney+Hotstar|Youtube, Operating System: WebOS, Resolution: Ultra HD (4K) 3840 x 2160 Pixels, Sound Output: 20 W";
  const price = "1,64,900 INR";

  const result = await storeNFT(
    name,
    imagePath,
    serialNumber,
    productLink,
    description,
    price
  );
  console.log(result);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
