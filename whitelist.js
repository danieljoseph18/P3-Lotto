const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

/**
 * 
 *  0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
 */

const whitelists = {
    0: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    1: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    2: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    3: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    4: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    5: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    6: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    7: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    8: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    9: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    10: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"],
    11: ["0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496", "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D"]
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
const addressToProve1 = "0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496";
const addressToProve2 = "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D";
// const proof = generateProof(addressToProve1, tokenId);

// Set Up 1
for(let i = 0; i < 12; i++) {
    console.log(i);
    console.log(`Merkle Root ${i}: `, merkleRoots[i]);
    console.log(`Proof For Address 1 Token ID ${i}: `, generateProof(addressToProve1, i));
    console.log(`Proof For Address 2 Token ID ${i}: `, generateProof(addressToProve2, i));
}
