import contractAbi from "../contracts/market/Item.sol/Item.json";
import { ethers } from "ethers";
import {React, useState} from "react";

export const MintItem = () =>{
    const [fileImg, setFileImg] = useState(null);
    const [name, setName] = useState("");
    const [desc, setDesc] = useState("");
    const contractAddress = "0x0e63D4f4190653D684C8795d8D7Fa35369AB47CE";
    
    const mint = async() =>{
       if(!window.ethereum){
        console.log("No wallet installed");
       }

       const provider = new ethers.providers.Web3Provider(window.ethereum);
       const signer = await provider.getSigner();
       const contract = new ethers.Contract(contractAddress,contractAbi.abi,signer);

       const tx = await contract.mintNFT();
    }
}
