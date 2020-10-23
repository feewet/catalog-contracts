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

use(solidity)

const parseEther = (value: string) => utils.parseEther(value)
const fromBigNumber = (value: utils.BigNumber) => value.toString()
const parseToken = (value) => utils.bigNumberify(value).mul(utils.parseEther('1'))
const toBigNumber = (value: string) => utils.bigNumberify(value)
const MAX_UINT = constants.MaxUint256

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

    beforeEach(async () => {
      const asArtistOne = await catalog.connect(artistOne)
      await asArtistOne.register()
      let artistContracts = await catalog.artists(artistOne.address)
      artistToken = await contractAt('ArtistToken', artistContracts.token)
      distributor = await contractAt('Distributor', artistContracts.distributor)
      pool = await contractAt('ArtistPool', artistContracts.pool)
    })

    it('artist deploys contracts', async () => {
      const asArtistOne = await catalog.connect(artistOne)
      expect(artistToken.address).not.eq(0)
      expect(distributor.address).not.eq(0)
      expect(pool.address).not.eq(0)
    })

    it('distributor owns supply', async () => {
      expect(await artistToken.balanceOf(distributor.address)).to.eq(parseEther('100000'))
    })

    it('cannot register twice', async () => {
      const asArtistOne = await catalog.connect(artistOne)
      await expect(asArtistOne.register()).to.be.revertedWith('already registered')
    })

    describe('split', () => {
      let daiAccountOne: MockDai
      let daiAccountTwo: MockDai
      let catalogAccountOne: MockCatalog
      let catalogAccountTwo: MockCatalog
      let artistTokenAccountOne: ArtistToken
      let artistTokenAccountTwo: ArtistToken
      let poolAccountOne: ArtistPool
      let poolAccountTwo: ArtistPool

      beforeEach(async () => {
        // setup account one
        daiAccountOne = await dai.connect(accountOne)
        await daiAccountOne.approve(catalog.address, MAX_UINT)
        catalogAccountOne = await catalog.connect(accountOne)
        poolAccountOne = await pool.connect(accountOne)
        artistTokenAccountOne = await artistToken.connect(accountOne)
        await artistTokenAccountOne.approve(pool.address, MAX_UINT)

        // setup account two
        daiAccountTwo = await dai.connect(accountTwo)
        await daiAccountTwo.approve(catalog.address, MAX_UINT)
        catalogAccountTwo = await catalog.connect(accountTwo)
        poolAccountTwo = await pool.connect(accountTwo)
        artistTokenAccountTwo = await artistToken.connect(accountTwo)
        await artistTokenAccountTwo.approve(pool.address, MAX_UINT)
      })

      it('first split with no stakers', async () => {
        await catalogAccountOne.split(artistOne.address, parseEther('100'))
        expect(await artistToken.balanceOf(accountOne.address)).to.eq(toBigNumber('26622776601683793319000'))
        expect(await artistToken.balanceOf(distributor.address)).to.eq(toBigNumber('73377223398316206681000'))
        expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('900'))
        expect(await dai.balanceOf(artistOne.address)).to.eq(parseEther('1100'))
        expect(await dai.balanceOf(pool.address)).to.eq(parseEther('0'))
      })

      it('second split with one staker claiming', async () => {
        await catalogAccountOne.split(artistOne.address, parseEther('100'))
        await poolAccountOne.stake(parseEther('100'))
        await catalogAccountTwo.split(artistOne.address, parseEther('100'))
        expect(await artistToken.balanceOf(accountTwo.address)).to.eq(toBigNumber('16622776601683793319000'))
        expect(await artistToken.balanceOf(distributor.address)).to.eq(toBigNumber('56754446796632413362000'))
        expect(await artistToken.balanceOf(pool.address)).to.eq(parseEther('100'))
        expect(await dai.balanceOf(accountTwo.address)).to.eq(parseEther('900'))
        expect(await dai.balanceOf(artistOne.address)).to.eq(parseEther('1190'))
        expect(await dai.balanceOf(pool.address)).to.eq(parseEther('10'))
        await poolAccountOne.claim()
        expect(await dai.balanceOf(pool.address)).to.eq(parseEther('10'))
        expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('9'))
      })
      it('claim with two stakers and claims', async () => {
        await poolAccountOne.stake(parseEther('100'))
        await catalogAccountTwo.split(artistOne.address, parseEther('10'))
        await poolAccountTwo.stake(parseEther('100'))
        await catalogAccountOne.split(artistOne.address, parseEther('10'))
        await catalogAccountTwo.split(artistOne.address, parseEther('10'))
        console.log(fromBigNumber(await dai.balanceOf(pool.address)))
        console.log(fromBigNumber(await dai.balanceOf(accountOne.address)))
        console.log(fromBigNumber(await dai.balanceOf(accountTwo.address)))
        console.log(fromBigNumber(await pool.pending(accountOne.address)))
        console.log(fromBigNumber(await pool.pending(accountTwo.address)))
        await poolAccountOne.claim()
        await poolAccountTwo.claim()
        console.log(fromBigNumber(await dai.balanceOf(pool.address)))
        console.log(fromBigNumber(await dai.balanceOf(accountOne.address)))
        console.log(fromBigNumber(await dai.balanceOf(accountTwo.address)))
        expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('890'))
        expect(await dai.balanceOf(accountTwo.address)).to.eq(parseEther('980'))
      })
    })
  })
})