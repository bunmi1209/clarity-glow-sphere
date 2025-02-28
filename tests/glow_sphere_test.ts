// [Previous imports and existing tests remain unchanged...]

Clarinet.test({
    name: "Cannot like a record twice",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_1')!;
        
        // Create routine and record first
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
        
        // Like the record
        let likeBlock = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'like-record',
                [types.uint(1)],
                user.address
            )
        ]);
        
        // Try to like again
        let secondLikeBlock = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'like-record',
                [types.uint(1)],
                user.address
            )
        ]);
        
        secondLikeBlock.receipts[0].result.expectErr().expectUint(105);
    }
});

// [Additional tests for input validation and error cases...]
