import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new skincare routine",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const routineName = "Morning Routine";
        const description = "My daily morning skincare routine";
        const products = ["Cleanser", "Toner", "Moisturizer"];

        let block = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'create-routine',
                [
                    types.ascii(routineName),
                    types.ascii(description),
                    types.list(products.map(p => types.ascii(p)))
                ],
                deployer.address
            )
        ]);

        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify routine details
        let getRoutine = chain.callReadOnlyFn(
            'glow-sphere',
            'get-routine',
            [types.uint(1)],
            deployer.address
        );
        
        const routine = getRoutine.result.expectSome().expectTuple();
        assertEquals(routine['name'], routineName);
        assertEquals(routine['description'], description);
    }
});

Clarinet.test({
    name: "Can add progress record to existing routine",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // First create a routine
        let block = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'create-routine',
                [
                    types.ascii("Test Routine"),
                    types.ascii("Test Description"),
                    types.list([types.ascii("Product 1")])
                ],
                deployer.address
            )
        ]);
        
        const routineId = 1;
        const note = "Skin feeling great today!";
        const photoHash = "QmHash123";
        
        // Add progress record
        let progressBlock = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'add-progress-record',
                [
                    types.uint(routineId),
                    types.ascii(note),
                    types.ascii(photoHash)
                ],
                deployer.address
            )
        ]);
        
        progressBlock.receipts[0].result.expectOk().expectUint(1);
        
        // Verify progress record
        let getRecord = chain.callReadOnlyFn(
            'glow-sphere',
            'get-progress-record',
            [types.uint(1)],
            deployer.address
        );
        
        const record = getRecord.result.expectSome().expectTuple();
        assertEquals(record['note'], note);
        assertEquals(record['photo-hash'], photoHash);
    }
});