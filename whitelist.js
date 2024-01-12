const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

const whitelists = {
    0: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    1: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    2: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    3: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    4: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    5: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    6: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6", "0x556e99A195CEd41C0bdB86d57Ee204451a0449fc"],
    7: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6"],
    8: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6"],
    9: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6"],
    10: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6"],
    11: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6"],
    12: ["0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6"]
}

// Function to create a Merkle Tree and get its root
function createMerkleTree(addresses) {
    const leafNodes = addresses.map(addr => keccak256(addr));
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
    return merkleTree;
}

// Creating Merkle trees for each token ID and storing their roots
const merkleRoots = {};
for (let tokenId = 0; tokenId <= 11; tokenId++) {
    const merkleTree = createMerkleTree(whitelists[tokenId] || []);
    merkleRoots[tokenId] = merkleTree.getHexRoot();
}

// Function to generate a proof for a specific address for a specific token ID
function generateProof(address, tokenId) {
    const merkleTree = createMerkleTree(whitelists[tokenId] || []);
    const leaf = keccak256(address);
    const proof = merkleTree.getHexProof(leaf);
    return proof;
}

// Example usage
const tokenId = 0; // Token ID for which you want to generate the proof
const addressToProve = "0x02A2012c36644f4e4b36A14EBe13E23c96f4C5b6";
// const proof = generateProof(addressToProve1, tokenId);

// Set Up 1
for(let i = 0; i < 12; i++) {
    console.log(i);
    console.log(`Merkle Root ${i}: `, merkleRoots[i]);
    console.log(`Proof For Token ID ${i}: `, generateProof(addressToProve, i));
}
