import { Clarinet, Tx, Chain, Account, types } from '@hirosystems/clarinet-sdk';
import { expect } from 'vitest';

const contractName = 'Tokenized-Blood-Donation-Program';

Clarinet.test({
  name: "Ensure that contract deploys successfully",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    // Test basic contract deployment
    const deployer = accounts.get('deployer')!;
    
    // Basic smoke test to ensure contract is deployed
    let block = chain.mineBlock([]);
    expect(block.receipts).toHaveLength(0);
    expect(block.height).toBeGreaterThan(0);
  },
});

Clarinet.test({
  name: "Can register donor with valid blood type",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall(contractName, "register-donor", [types.ascii("O+")], wallet1.address),
    ]);
    
    expect(block.receipts).toHaveLength(1);
    expect(block.receipts[0].result).toStrictEqual(types.ok(types.bool(true)));
  },
});

Clarinet.test({
  name: "Can register hospital",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall(contractName, "register-hospital", [
        types.ascii("Test Hospital"),
        types.ascii("123 Main St")
      ], wallet1.address),
    ]);
    
    expect(block.receipts).toHaveLength(1);
    expect(block.receipts[0].result).toStrictEqual(types.ok(types.bool(true)));
  },
});

Clarinet.test({
  name: "Can add blood inventory after hospital verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const hospital = accounts.get('wallet_1')!;
    
    // Register and verify hospital
    let block1 = chain.mineBlock([
      Tx.contractCall(contractName, "register-hospital", [
        types.ascii("Test Hospital"),
        types.ascii("123 Main St")
      ], hospital.address),
    ]);
    
    let block2 = chain.mineBlock([
      Tx.contractCall(contractName, "verify-hospital", [
        types.principal(hospital.address)
      ], deployer.address),
    ]);
    
    // Add blood inventory
    let block3 = chain.mineBlock([
      Tx.contractCall(contractName, "add-blood-inventory", [
        types.ascii("O+"),
        types.uint(5),
        types.uint(1000),
        types.ascii("BATCH001")
      ], hospital.address),
    ]);
    
    expect(block3.receipts).toHaveLength(1);
    expect(block3.receipts[0].result).toStrictEqual(types.ok(types.uint(1)));
  },
});
