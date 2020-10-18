import { expect, use } from 'chai'
import { utils, constants, Wallet } from 'ethers'
import { loadFixture, MockProvider, solidity } from 'ethereum-waffle'
import { wait, getContract } from './utils'
import { MockDai } from '../build/types/MockDai'
import { MockDaiFactory } from '../build/types/MockDaiFactory'
import { MockCatalog } from '../build/types/MockCatalog'
import { MockCatalogFactory } from '../build/types/MockCatalogFactory'
import { ArtistToken } from '../build/types/ArtistToken'
import { Distributor } from '../build/types/Distributor'
import { ArtistPool } from '../build/types/ArtistPool'
import { Split } from '../build/types/Split'

use(solidity)

const parseEther = (value: string) => utils.parseEther(value)
const fromBigNumber = (value: utils.BigNumber) => value.toString()
const parseToken = (value) => utils.bigNumberify(value).mul(utils.parseEther('1'))

describe('Catalog Contract', () => {
  let owner: Wallet
  let accountOne: Wallet
  let accountTwo: Wallet
  let artistOne: Wallet
  let artistTwo: Wallet
  let dai: MockDai
  let catalog: MockCatalog
  let freeDai: utils.BigNumber
  let contractAt: Function

  beforeEach(async () => {
    freeDai = parseToken('1000')
    // get mock provider
    const provider = new MockProvider();
    // get mock wallets
    [owner, accountOne, accountTwo, artistOne, artistTwo] = await provider.getWallets()
    // deploy dai contract using factory
    dai = await new MockDaiFactory(owner).deploy()
    // mint 1000 dai to all accounts
    await dai.mint(owner.address, freeDai)
    await dai.mint(accountOne.address, freeDai)
    await dai.mint(accountTwo.address, freeDai)
    await dai.mint(artistOne.address, freeDai)
    await dai.mint(artistTwo.address, freeDai)
    // deploy catalog contract
    catalog = await new MockCatalogFactory(owner).deploy()
    await catalog.setDai(dai.address)
    contractAt = getContract(owner)
  })

  describe('Register & Deploy Contracts', () => {
    let asArtistOne: MockCatalog
    let artistToken: ArtistToken
    let distributor: Distributor
    let pool: ArtistPool
    let split: Split

    beforeEach(async () => {
      const asArtistOne = await catalog.connect(artistOne)
      await asArtistOne.register()
      let artistContracts = await catalog.artists(artistOne.address)
      artistToken = contractAt('ArtistToken', artistContracts.token)
      distributor = contractAt('Distributor', artistContracts.distributor)
      pool = contractAt('ArtistPool', artistContracts.pool)
      split = contractAt('Split', artistContracts.split)
    })

    it('artist deploys contracts', async () => {
      const asArtistOne = await catalog.connect(artistOne)
      expect(artistToken.address).not.eq(0)
      expect(distributor.address).not.eq(0)
      expect(pool.address).not.eq(0)
      expect(split.address).not.eq(0)
    })

    it('distributor owns supply', async () => {
      expect(await artistToken.balanceOf(distributor.address)).to.eq(parseEther('100000'))
    })

    it('cannot register twice', async () => {
      const asArtistOne = await catalog.connect(artistOne)
      await expect(asArtistOne.register()).to.be.revertedWith('already registered')
    })

    describe('split', () => {
      it('split with reward', async () => {
        const daiAccountOne = await dai.connect(accountOne)
        await daiAccountOne.approve(catalog.address, parseEther('100'))
        const asAccountOne = await catalog.connect(accountOne)
        await asAccountOne.split(artistOne.address, parseEther('100'))
        // check balances
        expect(await artistToken.balanceOf(accountOne.address)).to.eq(parseEther('100'))
        expect(await artistToken.balanceOf(distributor.address)).to.eq(parseEther('99900'))
        expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('900'))
        expect(await dai.balanceOf(artistOne.address)).to.eq(parseEther('1090'))
        expect(await dai.balanceOf(pool.address)).to.eq(parseEther('10'))
      })
    })
  })
})