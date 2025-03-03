Clarinet.test({
    name: "Cannot create routine with empty product list",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'create-routine',
                [
                    types.ascii("Test Routine"),
                    types.ascii("Test Description"),
                    types.list([]),
                    types.bool(true)
                ],
                deployer.address
            )
        ]);
        
        block.receipts[0].result.expectErr().expectUint(108);
    }
});

Clarinet.test({
    name: "Cannot like own record",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
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
        
        // Try to like own record
        let likeBlock = chain.mineBlock([
            Tx.contractCall(
                'glow-sphere',
                'like-record',
                [types.uint(1)],
                deployer.address
            )
        ]);
        
        likeBlock.receipts[0].result.expectErr().expectUint(107);
    }
});
