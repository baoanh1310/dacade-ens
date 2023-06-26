import React, { useEffect, useState } from 'react';
import './styles/App.css';
import { networks } from './utils/networks';
import {ethers} from "ethers";
import contractAbi from './utils/contractABI.json';

// Constants
const tld = '.dacade';
const CONTRACT_ADDRESS = '0xE8327642Ce5614236dB56f493a74feeB7D857d4D';

const App = () => {

	const [currentAccount, setCurrentAccount] = useState('');
	const [domain, setDomain] = useState('');
	const [record, setRecord] = useState('');
	const [network, setNetwork] = useState('');
	const [editing, setEditing] = useState(false);
  	const [loading, setLoading] = useState(false);
	const [mints, setMints] = useState([]);

	const connectWallet = async () => {
		try {
		  const { ethereum } = window;
	
		  if (!ethereum) {
			alert("Get MetaMask -> https://metamask.io/");
			return;
		  }
	
		  const accounts = await ethereum.request({ method: "eth_requestAccounts" });
		
		  setCurrentAccount(accounts[0]);
		} catch (error) {
		}
	}

	const switchNetwork = async () => {
		if (window.ethereum) {
		  try {
			await window.ethereum.request({
			  	method: 'wallet_switchEthereumChain',
			  	params: [{ chainId: '0xaef3' }],
			});
		  } catch (error) {
			if (error.code === 4902) {
				try {
					await window.ethereum.request({
						method: 'wallet_addEthereumChain',
						params: [
							{	
								chainId: '0xaef3',
								chainName: 'Alfajores',
								rpcUrls: ['https://alfajores-forno.celo-testnet.org/'],
								nativeCurrency: {
									name: "CELO",
									symbol: "CELO",
									decimals: 18
								},
								blockExplorerUrls: ["https://alfajores.celoscan.io/"]
							},
						],
					});
				} catch (error) {
					console.log(error);
				}
			}
		  	console.log(error);
		}
	  } else {
		alert('MetaMask is not installed. Please install it to use this app: https://metamask.io/download.html');
	  } 
	}
  
	const checkIfWalletIsConnected = async () => {
		const { ethereum } = window;

		if (!ethereum) {
			console.log('Make sure you have metamask!');
			return;
		} else {
			console.log('We have the ethereum object', ethereum);
		}

		const accounts = await ethereum.request({ method: 'eth_accounts' });

		if (accounts.length !== 0) {
			const account = accounts[0];
			setCurrentAccount(account);
		} else {
			console.log('No authorized account found');
		}

		const chainId = await ethereum.request({ method: 'eth_chainId' });
		setNetwork(networks[chainId]);
	
		ethereum.on('chainChanged', handleChainChanged);
		
		function handleChainChanged(_chainId) {
		  window.location.reload();
		}
	};
	
	const renderNotConnectedContainer = () => (
		<div className="connect-wallet-container">
			<img src="https://media.tenor.com/UnFx-k_lSckAAAAM/amalie-steiness.gif" alt="Loading gif" />
			<button onClick={connectWallet} className="cta-button connect-wallet-button">
				Connect Wallet
			</button>
		</div>
	);

	useEffect(() => {
		checkIfWalletIsConnected();
	}, [])

	const renderInputForm = () =>{
		if (network !== 'Celo Alfajores Testnet') {
			return (
				<div className="connect-wallet-container">
					<p>Please connect to Celo Alfajores Testnet</p>
					<button className='cta-button mint-button' onClick={switchNetwork}>Click here to switch</button>
				</div>
			);
		}
		return (
			<div className="form-container">
				<div className="first-row">
					<input
					type="text"
					value={domain}
					placeholder='domain'
					onChange={e => setDomain(e.target.value)}
					disabled={editing}
					/>
					<p className='tld'> {tld} </p>
				</div>
	  
				<input
					type="text"
					value={record}
					placeholder='whats your dacade power?'
					onChange={e => setRecord(e.target.value)}
				/>
				{editing ? (
					<div className="button-container">
						<button className='cta-button mint-button' disabled={loading} onClick={updateDomain}>
							Set record
						</button>
						<button className='cta-button mint-button' onClick={() => {setEditing(false)}}>
							Cancel
						</button>  
					</div>
				) : (
					<button className='cta-button mint-button' disabled={loading} onClick={mintDomain}>
						Mint
					</button>  
				)}
			</div>
		);
  	}

	const mintDomain = async () => {
		if (!domain) { return }
		if (domain.length < 3) {
			alert('Domain must be at least 3 characters long');
			return;
		}
		const price = domain.length === 3 ? '0.5' : domain.length === 4 ? '0.3' : '0.1';
		try {
			const { ethereum } = window;
			if (ethereum) {
				const provider = new ethers.providers.Web3Provider(ethereum);
				const signer = provider.getSigner();
				const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);
			
				let tx = await contract.register(domain, {value: ethers.utils.parseEther(price)});
				const receipt = await tx.wait();
			
				if (receipt.status === 1) {
					tx = await contract.setRecord(domain, record);
					await tx.wait();

					setTimeout(() => {
						fetchMints();
					}, 2000);

					setRecord('');
					setDomain('');
				} else {
					alert("Transaction failed! Please try again");
				}
			}
		} catch(error) {
			console.log(error);
		}
	}

	const updateDomain = async () => {
		if (!record || !domain) { return }
		setLoading(true);
		try {
			const { ethereum } = window;
			if (ethereum) {
				const provider = new ethers.providers.Web3Provider(ethereum);
				const signer = provider.getSigner();
				const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);
		
				let tx = await contract.setRecord(domain, record);
				await tx.wait();
		
				fetchMints();
				setRecord('');
				setDomain('');
			}
		} catch(error) {
			console.log(error);
		}
		setLoading(false);
	}

	const fetchMints = async () => {
		try {
			const { ethereum } = window;
			if (ethereum) {
				const provider = new ethers.providers.Web3Provider(ethereum);
				const signer = provider.getSigner();
				const contract = new ethers.Contract(CONTRACT_ADDRESS, contractAbi.abi, signer);
				
				const names = await contract.getAllNames();
				
				const mintRecords = await Promise.all(names.map(async (name) => {
					const mintRecord = await contract.records(name);
					const owner = await contract.domains(name);
					return {
						id: names.indexOf(name),
						name: name,
						record: mintRecord,
						owner: owner,
					};
				}));
				setMints(mintRecords);
			}
		} catch(error){
			console.log(error);
		}
	}

	const renderMints = () => {
		if (currentAccount && mints.length > 0) {
			return (
				<div className="mint-container">
					<p className="subtitle"> Recently minted domains!</p>
					<div className="mint-list">
					{ mints.map((mint, index) => {
						console.log("mint: ", mint);
						if (mint.owner.toLowerCase() === currentAccount.toLowerCase()) {
							return (
								<div className="mint-item" key={index}>
									<div className='mint-row'>
										<button className="edit-button" onClick={() => editRecord(mint.name)}>
											<img className="edit-icon" src="https://img.icons8.com/metro/26/000000/pencil.png" alt="Edit button" />
										</button>
									</div>
									<div className='mint-row'>
										<p className="underlined">{' '}{mint.name}{tld}{' '}</p>
									</div>
									<div className='mint-row'>
										<p> {mint.record} </p>
									</div>
							</div>)
						} else {
							return (
								<div></div>
							)
						}
					})}
					</div>
				</div>
			);
		}
	};

	const editRecord = (name) => {
		setEditing(true);
		setDomain(name);
	}

	useEffect(() => {
		if (network === 'Celo Alfajores Testnet') {
		  	fetchMints();
		}
		console.log("network: ", network)
	}, [currentAccount, network]);

  	return (
		<div className="App">
			<div className="container">

				<div className="header-container">
					<header>
						<div className="left">
						<p className="title">Dacade Name Service</p>
						</div>
						<div className="right">
						{ currentAccount ? <p> Wallet: {currentAccount.slice(0, 6)}...{currentAccount.slice(-4)} </p> : <p> Not connected </p> }
						</div>
					</header>
				</div>

				{!currentAccount && renderNotConnectedContainer()}
				{currentAccount && renderInputForm()}
				{mints && renderMints()}

			</div>
		</div>
	);
}

export default App;
