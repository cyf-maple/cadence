import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract YLink_NFT: NonFungibleToken{

	// 上链歌曲总数
	pub var totalSupply: UInt64

	// 路径
	pub let YLinkMusicianCollectionStoragePath: StoragePath
	pub let YLinkMusicianCollectionPublicPath: PublicPath
	pub let MinterStoragePath: StoragePath
	pub let MinterPrivatePath: PrivatePath

	// 事件，用于反馈给前端
	// 合约初始化
	pub event ContractInitialized()
	// 提现音乐，歌曲id和从哪个地址提现
	pub event Withdraw(id: UInt64, from: Address?)
	// 接受音乐，歌曲id和存入哪个地址
	pub event Deposit(id: UInt64, to: Address?)
	// 铸造新的音乐NFT
	pub event Minted(id :UInt64)

	// 获取歌曲的内容
	pub var MintedToken: [UInt64]

	// 歌曲
	pub resource NFT: NonFungibleToken.INFT {
		// 歌曲的唯一ID
		pub let id: UInt64

		// 初始化
		init(tokenId: UInt64) {
			self.id = tokenId

			// 铸造事件
			emit Minted(id: tokenId)
		}

		// 签名
		pub fun sign(): @YLink_NFT.SongSignature {
			return <- create SongSignature(tokenId: self.id)
		}

		destroy() {
		}
	}

	// 签名
	pub resource SongSignature: NonFungibleToken.INFT{
		// 签名的ID
		pub let id: UInt64

		// 初始化
		init(tokenId: UInt64) {
			self.id = tokenId
		}

		// 销毁签名
		destroy() {
		}
	}

	// 公共接口
	pub resource interface YLink_NFTCollectionPublic{
		// 接收NFT
		pub fun deposit(token: @NonFungibleToken.NFT)
		// 获得所有的NFT ID号
		pub fun getIDs(): [UInt64]
	}

	// 音链钱包
	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, YLink_NFTCollectionPublic, NonFungibleToken.CollectionPublic{
		// 字典，记录所有的NFT
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
		
		// 提现NFT
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// 接收NFT
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @YLink_NFT.NFT

			let id: UInt64 = token.id

			// 接收并删除旧的NFT
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		// 获取拥有的NFT IDs
		pub fun getIDs(): [UInt64]{
			return self.ownedNFTs.keys
		}

		// 返回NFT，以便使用NFT签名
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		}

		// 初始化
		init () {
			self.ownedNFTs <- {}
		}

		// 析构函数
		destroy() {
			destroy self.ownedNFTs
		}
	}

	// 公共函数，创建钱包
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	// 铸造歌曲厂
	pub resource Minter {
		// 铸造歌曲NFT
		pub fun mintSong(
			recipient: &{YLink_NFT.YLink_NFTCollectionPublic},
			tokenId: UInt64) {
			pre {
				!YLink_NFT.MintedToken.contains(tokenId): "有这个ID的歌曲了"
			}

			// 将创建的NFT注入钱包
			recipient.deposit(token: <-create YLink_NFT.NFT(
				tokenId: tokenId
			))

			// 将所有歌曲数+1
			YLink_NFT.totalSupply = YLink_NFT.totalSupply + (1 as UInt64)

			// 将新的歌曲号添加进数组
			YLink_NFT.MintedToken.append(tokenId)
		}
		// 铸造新的铸造厂
		pub fun createNewMinter(): @Minter {
			return <-create Minter()
		}
	}

	// 初始化合约
	init() {
		// 赋予存储位置名字
		self.YLinkMusicianCollectionStoragePath = /storage/YLink_NFTCollection
		self.YLinkMusicianCollectionPublicPath = /public/YLink_NFTCollection
		self.MinterStoragePath = /storage/YLink_NFTMinter
		self.MinterPrivatePath = /private/YLink_NFTMinter

		// 初始化代币总数为0
		self.totalSupply = 0
		self.MintedToken = []

		// 将铸造厂装入合约创造者的存储空间
		self.account.save(<-create Minter(), to: self.MinterStoragePath)

		// 链接铸造厂和私有领域
		self.account.link<&YLink_NFT.Minter>(
			self.MinterPrivatePath,
			target: self.MinterStoragePath
		) ?? panic("Could not get a capability to the admin")

		emit ContractInitialized()
	}

}
 