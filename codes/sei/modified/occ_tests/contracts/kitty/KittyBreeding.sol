pragma solidity ^0.8.17;

contract KittyBreeding
{
    struct KittyInfo
    {
        bool gender;
        uint birthTime;
        address owner;
    }
    struct Kitty
    {
        uint id;
        uint genes;
        uint matronId;
        uint sireId;
        uint lastBreed;
    }
    KittyInfo[] allKitties;
    KittyInfo[] newBorns;
    uint32 newBornNums;
    mapping(address=>mapping(uint=>Kitty)) myKitties;
    
    function create(bool gender, address owner) internal returns (uint)
    {
        uint id = allKitties.length;
        KittyInfo memory n;
        n.gender = gender;
        n.birthTime = block.number;
        n.owner = owner;
        allKitties.push(n);
        return id;
    }
    
    function mint(address owner, uint genes, bool gender) public
    {
        _mint(owner, genes, gender);
    }
    
    function _mint(address owner, uint genes, bool gender) public
    {
        uint id = create(gender, owner);
        _addNewKittyToAddr(owner, genes, id);
    }
    
    function _addNewKittyToAddr(address _scope, uint genes, uint id) public
    {
        _addNewKittyToAddr(_scope, genes, id, type(uint256).max, type(uint256).max);
    }
    
    function _addNewKittyToAddr(address _scope, uint genes, uint id, uint matronId, uint sireId) public
    {
        Kitty memory newKitty;
        newKitty.id = id;
        newKitty.genes = genes;
        newKitty.matronId = matronId;
        newKitty.sireId = sireId;
        newKitty.lastBreed = block.number;
        myKitties[_scope][id] = newKitty;
    }
    
    function sqrt(uint x) pure internal returns (uint)
    {
        uint z = (x + 1) / 2;
        uint y = x;
        while (z < y)
        {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
    
    function genesMix(uint m_genes, uint s_gengs) pure internal returns (uint)
    {
        uint new_genes = sqrt(m_genes) * sqrt(s_gengs);
        new_genes = sqrt(m_genes) * sqrt(s_gengs);
        new_genes = sqrt(m_genes) * sqrt(s_gengs);
        new_genes = sqrt(m_genes) * sqrt(s_gengs);
        new_genes = sqrt(m_genes) * sqrt(s_gengs);
        new_genes = sqrt(m_genes) * sqrt(s_gengs);
        return new_genes;
    }
    
    function breed(address _scope, uint m, uint s, bool gender) public
    {
        require(m < allKitties.length);
        require(s < allKitties.length);
        require(allKitties[m].gender);
        require(!allKitties[s].gender);
        addMGenes(allKitties[m].owner, m, s, gender);
    }
    
    function addMGenes(address _scope, uint m, uint s, bool gender) public
    {
        myKitties[_scope][m].lastBreed = block.number;
        addSGenes(allKitties[s].owner, myKitties[_scope][m].genes, m, s, gender);
    }
    
    function addSGenes(address _scope, uint m_genes, uint m, uint s, bool gender) public
    {
        uint new_genes = genesMix(m_genes, myKitties[_scope][s].genes);
        addNewBorn(tx.origin, m, s, gender, new_genes);
    }
    
    function addNewBorn(address _scope, uint m, uint s, bool gender, uint new_genes) public
    {
        uint birth_time = block.number;
        uint id_nb = newBorns.length | (1 << 255);
        _addNewKittyToAddr(_scope, new_genes, id_nb, m, s);
        KittyInfo memory n;
        n.gender = gender;
        n.birthTime = birth_time;
        n.owner = tx.origin;
        newBornNums++;
    }
}