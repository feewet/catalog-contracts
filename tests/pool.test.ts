import { expect, use } from 'chai'
import { utils, constants, Wallet } from 'ethers'
import { loadFixture, MockProvider, solidity } from 'ethereum-waffle'
import { MockDai } from '../build/types/MockDai'
import { MockDaiFactory } from '../build/types/MockDaiFactory'
import { ArtistPool } from '../build/types/ArtistPool'
import { ArtistPoolFactory } from '../build/types/ArtistPoolFactory'
import { ArtistToken } from '../build/types/ArtistToken'
import { ArtistTokenFactory } from '../build/types/ArtistTokenFactory'

use(solidity)

const parseEther = (value: string) => utils.parseEther(value)
const fromBigNumber = (value: utils.BigNumber) => value.toString()
const parseToken = (value) => utils.bigNumberify(value).mul(utils.parseEther('1'))

describe('Staking Contract', () => {
  let owner: Wallet
  let accountOne: Wallet
  let accountTwo: Wallet
  let dai: MockDai
  let pool: ArtistPool
  let token: ArtistToken

  beforeEach(async () => {
    const freeDai = parseToken('1000')
    // get mock provider
    const provider = new MockProvider();
    // get mock wallets
    [owner, accountOne, accountTwo] = await provider.getWallets()
    // deploy contracts using factory
    dai = await new MockDaiFactory(owner).deploy()
    token = await new ArtistTokenFactory(owner).deploy()
    pool = await new ArtistPoolFactory(owner).deploy(token.address, dai.address)
    // mint tokens
    await token.mint(accountOne.address, freeDai)
    await token.mint(accountTwo.address, freeDai)
    await dai.mint(owner.address, freeDai);
  })

  // pool drained
  it('cannot distribute to empty pool', async () => {
      
  })

  describe('one staker', () => {
    let poolAccountOne: ArtistPool

    beforeEach(async () => {
      let tokenAccountOne = await token.connect(accountOne)
      await tokenAccountOne.approve(pool.address, parseEther('100'))
      poolAccountOne = await pool.connect(accountOne)
      await poolAccountOne.stake(parseEther('100'))
    })

    it('can view stakes', async () => {
      expect(await pool.stakes(accountOne.address)).to.eq(parseEther('100'))
    })

    it('no rewards yet', async () => {
      expect(await pool.pending(accountOne.address)).to.eq(0)
    })

    it('staked tokens are owned by pool', async () => {
      expect(await token.balanceOf(accountOne.address)).to.eq(parseEther('900'))
      expect(await token.balanceOf(pool.address)).to.eq(parseEther('100'))
    })

    it('unstake', async () => {
      expect(await pool.pending(accountOne.address)).to.eq(0)
    })

    describe('distribute', () => {
      let poolOwner: ArtistPool
      let daiOwner: MockDai

      beforeEach(async () => {
        daiOwner = await dai.connect(owner)
        await daiOwner.approve(pool.address, parseEther('100'))
        poolOwner = await pool.connect(owner)
        await poolOwner.distribute(parseEther('100'))
      })

      it('pending rewards', async () => {
        expect(await pool.pending(accountOne.address)).to.eq(parseEther('100'))
      })

      it('public stake', async () => {
        expect(await pool.pending(accountOne.address)).to.eq(parseEther('100'))
      })

      it('rewards tokens owned by pool', async () => {
        expect(await dai.balanceOf(pool.address)).to.eq(parseEther('100'))
      })

      it('claim rewards', async () => {
        await poolAccountOne.claim()
        expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('100'))
      })

      describe('withdraw stake', () => {

        beforeEach(async () => {
          await poolAccountOne.unstake(parseEther('50'))
        })

        it('pool balances correct after withdrawing some stake', async () => {
          expect(await token.balanceOf(pool.address)).to.eq(parseEther('50'))
          expect(await dai.balanceOf(pool.address)).to.eq(parseEther('0'))
        })

        it('withdraws half with full reward', async () => {
          expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('100'))
        })

        it('withdraws remainder with zero reward', async () => {
          await poolAccountOne.unstake(parseEther('50'))
          expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('100'))
        })

        it('cannot withdraw more stake than staked amount', async () => {
          await expect(poolAccountOne.unstake(parseEther('100')))
            .to.be.revertedWith('insufficient stake')
        })

        it('cannot withdraw if no stake', async () => {
          await poolAccountOne.unstake(parseEther('50'))
          await expect(poolAccountOne.unstake(parseEther('100')))
            .to.be.revertedWith('no stake')
        })

        it('withdraws reward after second distribution', async () => {
          await daiOwner.approve(pool.address, parseEther('100'))
          await poolOwner.distribute(parseEther('100'))
          await poolAccountOne.unstake(parseEther('50'))
          expect(await dai.balanceOf(accountOne.address)).to.eq(parseEther('200'))
        })
      })
    })
  })
})