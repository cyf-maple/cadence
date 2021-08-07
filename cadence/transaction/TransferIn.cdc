import YLink_NFT from 0xf8d6e0586b0a20c7

transaction {
	let Mint: &YLink_NFT.Minter?
	prepare(acct: AuthAccount) {
	if acct.borrow<&YLink_NFT.Collection>(from: /storage/YLink_NFTCollection) == nil {
		let collection <- YLink_NFT.createEmptyCollection() as! @YLink_NFT.Collection
		acct.save(<-collection, to: /storage/YLink_NFTCollection)
		acct.link<&{YLink_NFT.YLink_NFTCollectionPublic}>(/public/YLink_NFTCollection, target: /storage/YLink_NFTCollection)
	}
	self.Mint = acct.borrow<&YLink_NFT.Minter>(from: /storage/YLink_NFTMinter)
	}
	execute {
		let account = getAccount(0x01cf0e2f2f715450)
		if self.Mint != nil {
			let Capa = account.getCapability<&{YLink_NFT.YLink_NFTCollectionPublic}>(/public/YLink_NFTCollection)
			let ublic = Capa.borrow()!
			self.Mint!.mintSong(recipient: ublic, tokenId: 2)
		}
	}
	// verify that the account has been initialized
	post {
	}
}
 