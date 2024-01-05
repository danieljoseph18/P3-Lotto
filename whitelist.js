const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

const whitelists = {
    0: [],
    1: [],
    2: [],
    3: [],
    4: [],
    5: [],
    6: [],
    7: [],
    8: [],
    9: []
}

// Function to create a Merkle Tree and get its root
function createMerkleTree(addresses) {
    const leafNodes = addresses.map(addr => keccak256(addr));
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
    return merkleTree;
}

// Creating Merkle trees for each token ID and storing their roots
const merkleRoots = {};
for (let tokenId = 0; tokenId <= 9; tokenId++) {
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
const addressToProve = "0xAddressToProve";
const proof = generateProof(addressToProve, tokenId);
