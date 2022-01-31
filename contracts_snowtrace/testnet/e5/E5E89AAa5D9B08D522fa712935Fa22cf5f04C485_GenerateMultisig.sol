/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

// Add Members
// Working consensus setting
// Optional joining

contract Multisig {
    event Propose(address indexed proposer, uint256 indexed proposal);
    event Sign(address indexed signer, uint256 indexed proposal);
    event Execute(uint256 indexed proposal);

    error NoArrayParity();
    error NotSigner();
    error Signed();
    error InsufficientSigs();
    error ExecuteFailed();

    uint8 sigsRequired;
    uint256 proposalCounter;

    mapping(address => bool) public signer;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public signed;

    struct Proposal {
        address[] targets;
        uint256[] values;
        bytes[] payloads;
        uint8 sigs;
    }

    constructor(address[] memory signers_, uint8 sigsRequired_) {
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < signers_.length; i++) {
                signer[signers_[i]] = true;
            }
        }     
        sigsRequired = sigsRequired_;
    }

    function getProposal(uint256 proposal) public view virtual returns 
        (   address[] memory targets, 
            uint256[] memory values, 
            bytes[] memory payloads, 
            uint8 sigs
        ) 
    {
        Proposal storage prop = proposals[proposal];

        (targets, values, payloads, sigs) = (prop.targets, prop.values, prop.payloads, prop.sigs);
    }

    function propose(
        address[] calldata targets, 
        uint256[] calldata values, 
        bytes[] calldata payloads
    ) public virtual {
        if (targets.length != values.length || values.length != payloads.length) revert NoArrayParity();

        // cannot realistically overflow on human timescales
        unchecked {
            uint256 proposal = proposalCounter++;

            proposals[proposal] = Proposal({
                targets: targets,
                values: values,
                payloads: payloads,
                sigs: 0
            });

            emit Propose(msg.sender, proposal);
        }
    }

    function sign(uint256 proposal) public virtual {
        if (!signer[msg.sender]) revert NotSigner();
        if (signed[proposal][msg.sender]) revert Signed();
        
        // cannot realistically overflow on human timescales
        unchecked {
            proposals[proposal].sigs++;
        }

        signed[proposal][msg.sender] = true;

        emit Sign(msg.sender, proposal);
    }

    function execute(uint256 proposal) public virtual {
        Proposal storage prop = proposals[proposal];

        if (prop.sigs < sigsRequired) revert InsufficientSigs();

        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < prop.targets.length; i++) {
                (bool success, ) = prop.targets[i].call{value: prop.values[i]}(prop.payloads[i]);

                if (!success) revert ExecuteFailed();
            }
        }

        delete proposals[proposal];

        emit Execute(proposal);
    }

    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();
                    
                    assembly {
                        result := add(result, 0x04)
                    }
                    
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }

    receive() external payable virtual {}
}


/// @notice Allows user to create a multisig wallet
contract GenerateMultisig {
    // event Propose(address indexed proposer, uint256 indexed proposal);
    // event Sign(address indexed signer, uint256 indexed proposal);
    // event Execute(uint256 indexed proposal);

    // error NoArrayParity();
    // error NotSigner();
    // error Signed();
    // error InsufficientSigs();
    // error ExecuteFailed();

    uint8 m;  
    uint8 n;
    uint256 groupCounter;
    address[] allGroups;
    address multisig;
    address[] members;
    address founder;

    // mapping(address => bool) public signer;
    // mapping(uint256 => Proposal) public proposals;
    // mapping(uint256 => mapping(address => bool)) public signed;

    // struct Proposal {
    //     address[] targets;
    //     uint256[] values;
    //     bytes[] payloads;
    //     uint8 sigs;
    // }

    function generateMultisig(
        //address multisig_, 
        //address founder_, 
        address[] memory members_, 
        //uint8 m_, 
        uint8 n_ 
    ) public {
        Multisig ms = new Multisig(members_ , n_);
        allGroups.push(address(ms));
    }

    // constructor(
    //     address multisig_, 
    //     //address founder_, 
    //     address[] memory members_, 
    //     //uint8 m_, 
    //     uint8 n_ 
    // ) 
    // public 
    // {
    //     multisig = multisig_;
    //     members = members_;
    //     n = n_;
    //     // cannot realistically overflow on human timescales
    //     // unchecked {
    //     //     for (uint256 i; i < signers_.length; i++) {
    //     //         signer[signers_[i]] = true;
    //     //     }
    //     // }        
    // }

    // function sign(uint256 proposal) public virtual {
    //     if (!signer[msg.sender]) revert NotSigner();
    //     if (signed[proposal][msg.sender]) revert Signed();
        
    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         proposals[proposal].sigs++;
    //     }

    //     signed[proposal][msg.sender] = true;

    //     emit Sign(msg.sender, proposal);
    // }

    // function execute(uint256 proposal) public virtual {
    //     Proposal storage prop = proposals[proposal];

    //     if (prop.sigs < sigsRequired) revert InsufficientSigs();

    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         for (uint256 i; i < prop.targets.length; i++) {
    //             (bool success, ) = prop.targets[i].call{value: prop.values[i]}(prop.payloads[i]);

    //             if (!success) revert ExecuteFailed();
    //         }
    //     }

    //     delete proposals[proposal];

    //     emit Execute(proposal);
    // }

    // function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
    //     results = new bytes[](data.length);
        
    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         for (uint256 i = 0; i < data.length; i++) {
    //             (bool success, bytes memory result) = address(this).delegatecall(data[i]);

    //             if (!success) {
    //                 if (result.length < 68) revert();
                    
    //                 assembly {
    //                     result := add(result, 0x04)
    //                 }
                    
    //                 revert(abi.decode(result, (string)));
    //             }
    //             results[i] = result;
    //         }
    //     }
    // }
}