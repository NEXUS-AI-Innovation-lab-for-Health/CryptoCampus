

import { Web3 } from 'web3';

// Configuration de la connexion à Ganache
const GANACHE_URL = process.env.BLOCKCHAIN_RPC || 'http://ganache:8545';
const web3 = new Web3(GANACHE_URL);

/**
 * Récupère tous les comptes Ganache et leurs soldes
 */
export async function getAllAccounts() {
  try {
    const accounts = await web3.eth.getAccounts();
    const accountsWithBalance = [];

    for (let i = 0; i < accounts.length; i++) {
      const balanceWei = await web3.eth.getBalance(accounts[i]);
      const balanceEth = web3.utils.fromWei(balanceWei, 'ether');
      
      accountsWithBalance.push({
        index: i,
        address: accounts[i],
        balanceWei: balanceWei.toString(),
        balanceEth: balanceEth.toString()
      });
    }

    return accountsWithBalance;
  } catch (error) {
    console.error('Erreur lors de la récupération des comptes:', error);
    throw error;
  }
}

/**
 * Envoie de l'Ether d'un compte à un autre
 * @param {string} fromAddress - Adresse de l'expéditeur
 * @param {string} toAddress - Adresse du destinataire
 * @param {number} amountEth - Montant en ETH à envoyer
 */
export async function sendTransaction(fromAddress, toAddress, amountEth) {
  try {
    const amountWei = web3.utils.toWei(amountEth.toString(), 'ether');
    
    // Récupération du solde avant la transaction
    const balanceBeforeFrom = await web3.eth.getBalance(fromAddress);
    const balanceBeforeTo = await web3.eth.getBalance(toAddress);

    // Envoi de la transaction
    const transaction = await web3.eth.sendTransaction({
      from: fromAddress,
      to: toAddress,
      value: amountWei,
      gas: 21000 // Gas standard pour une transaction simple
    });

    // Récupération du solde après la transaction
    const balanceAfterFrom = await web3.eth.getBalance(fromAddress);
    const balanceAfterTo = await web3.eth.getBalance(toAddress);

    return {
      success: true,
      transactionHash: transaction.transactionHash,
      blockNumber: Number(transaction.blockNumber),
      gasUsed: transaction.gasUsed.toString(),
      from: {
        address: fromAddress,
        balanceBefore: web3.utils.fromWei(balanceBeforeFrom, 'ether'),
        balanceAfter: web3.utils.fromWei(balanceAfterFrom, 'ether')
      },
      to: {
        address: toAddress,
        balanceBefore: web3.utils.fromWei(balanceBeforeTo, 'ether'),
        balanceAfter: web3.utils.fromWei(balanceAfterTo, 'ether')
      },
      amount: amountEth
    };
  } catch (error) {
    console.error('Erreur lors de la transaction:', error);
    throw error;
  }
}

/**
 * Récupère le solde d'un compte spécifique
 * @param {string} address - Adresse du compte
 */
export async function getBalance(address) {
  try {
    const balanceWei = await web3.eth.getBalance(address);
    const balanceEth = web3.utils.fromWei(balanceWei, 'ether');
    
    return {
      address,
      balanceWei: balanceWei.toString(),
      balanceEth: balanceEth.toString()
    };
  } catch (error) {
    console.error('Erreur lors de la récupération du solde:', error);
    throw error;
  }
}

/**
 * Récupère les détails d'une transaction
 * @param {string} txHash - Hash de la transaction
 */
export async function getTransactionDetails(txHash) {
  try {
    const transaction = await web3.eth.getTransaction(txHash);
    const receipt = await web3.eth.getTransactionReceipt(txHash);
    
    return {
      hash: transaction.hash,
      from: transaction.from,
      to: transaction.to,
      value: web3.utils.fromWei(transaction.value, 'ether'),
      gas: transaction.gas.toString(),
      gasPrice: web3.utils.fromWei(transaction.gasPrice, 'gwei'),
      blockNumber: Number(transaction.blockNumber),
      status: receipt.status ? 'Success' : 'Failed',
      gasUsed: receipt.gasUsed.toString()
    };
  } catch (error) {
    console.error('Erreur lors de la récupération des détails:', error);
    throw error;
  }
}

/**
 * Exemple d'utilisation
 */
export async function exampleUsage() {
  console.log('\n=== Récupération des comptes Ganache ===');
  const accounts = await getAllAccounts();
  accounts.forEach(acc => {
    console.log(`Compte ${acc.index}: ${acc.address}`);
    console.log(`  Solde: ${acc.balanceEth} ETH\n`);
  });

  console.log('\n=== Transaction de l\'utilisateur 1 vers l\'utilisateur 2 ===');
  const user1 = accounts[0].address;
  const user2 = accounts[1].address;
  
  console.log(`Envoi de 50 ETH de ${user1} vers ${user2}`);
  
  const txResult = await sendTransaction(user1, user2, 50);
  
  console.log('\n📊 Résultat de la transaction:');
  console.log(`  ✅ Hash: ${txResult.transactionHash}`);
  console.log(`  📦 Block: ${txResult.blockNumber}`);
  console.log(`  ⛽ Gas utilisé: ${txResult.gasUsed}`);
  console.log(`\n  👤 Expéditeur (${txResult.from.address}):`);
  console.log(`     Avant: ${txResult.from.balanceBefore} ETH`);
  console.log(`     Après: ${txResult.from.balanceAfter} ETH`);
  console.log(`\n  👤 Destinataire (${txResult.to.address}):`);
  console.log(`     Avant: ${txResult.to.balanceBefore} ETH`);
  console.log(`     Après: ${txResult.to.balanceAfter} ETH`);
  
  return txResult;
}
