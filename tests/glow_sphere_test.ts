import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new public skincare routine",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const routineName = "Morning Routine";
        const description = "My daily morning skincare routine";
        const products = ["Cleanser", "Toner", "Moisturizer"];
        const isPublic = true;

        let block = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'create-routine',
                [
                    types.ascii(routineName),
                    types.ascii(description),
                    types.list(products.map(p => types.ascii(p))),
                    types.bool(isPublic)
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
        assertEquals(routine['is-public'], isPublic);
        assertEquals(routine['likes'], '0');
    }
});

Clarinet.test({
    name: "Can follow another user",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user1 = accounts.get('wallet_1')!;
        const user2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'follow-user',
                [types.principal(user2.address)],
                user1.address
            )
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify following status
        let isFollowing = chain.callReadOnlyFn(
            'glow-sphere',
            'is-following',
            [
                types.principal(user1.address),
                types.principal(user2.address)
            ],
            user1.address
        );
        
        isFollowing.result.expectBool(true);
    }
});

Clarinet.test({
    name: "Can like a routine",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_1')!;
        
        // First create a routine
        let block = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'create-routine',
                [
                    types.ascii("Test Routine"),
                    types.ascii("Test Description"),
                    types.list([types.ascii("Product 1")]),
                    types.bool(true)
                ],
                deployer.address
            )
        ]);
        
        // Like the routine
        let likeBlock = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'like-routine',
                [types.uint(1)],
                user.address
            )
        ]);
        
        likeBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify like status
        let hasLiked = chain.callReadOnlyFn(
            'glow-sphere',
            'has-liked-routine',
            [
                types.principal(user.address),
                types.uint(1)
            ],
            user.address
        );
        
        hasLiked.result.expectBool(true);
    }
});
