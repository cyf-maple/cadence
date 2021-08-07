import YLink_NFT from 0xf8d6e0586b0a20c7

transaction {
	prepare(acct: AuthAccount) {
		if acct.borrow<&YLink_NFT.Collection>(from: /storage/YLink_NFTCollection) == nil {
			let collection <- YLink_NFT.createEmptyCollection() as! @YLink_NFT.Collection
			acct.save(<-collection, to: /storage/YLink_NFTCollection)
			acct.link<&{YLink_NFT.YLink_NFTCollectionPublic}>(/public/YLink_NFTCollection, target: /storage/YLink_NFTCollection)
		}
	}
	execute {
		
	}
	// verify that the account has been initialized
	post {

	}
}
 