import { expect, use } from 'chai'
import { utils, constants, Wallet } from 'ethers'
import { loadFixture, MockProvider, solidity } from 'ethereum-waffle'
import { MockDai } from '../build/types/MockDai'
import { MockDaiFactory } from '../build/types/MockDaiFactory'
import { Split } from '../build/types/Split'
import { SplitFactory } from '../build/types/SplitFactory'

use(solidity)

const parseEther = (value: string) => utils.parseEther(value)
const fromBigNumber = (value: utils.BigNumber) => value.toString()
const parseToken = (value) => utils.bigNumberify(value).mul(utils.parseEther('1'))

describe('Split Contract', () => {
  let owner: Wallet
  let accountOne: Wallet
  let accountTwo: Wallet
  let token: MockDai
  let split: Split
  let initialSupply: utils.BigNumber

  beforeEach(async () => {
    initialSupply = parseToken('1000')
    // get mock provider
    const provider = new MockProvider();
    // get mock wallets
    [owner, accountOne, accountTwo] = await provider.getWallets()
    //console.log(owner.address, accountOne.address, accountTwo.address)
    // deploy token contract using factory
    token = await new MockDaiFactory(owner).deploy()
    // mint 1000 tokens to owners
    await token.mint(owner.address, initialSupply)
    // deploy split contract with paramaters
    split = await new SplitFactory(owner).deploy(
      accountOne.address, accountTwo.address, '900000000000000000')
  })

  describe('split', () => {
    it('split between two accounts', async () => {
      await token.approve(split.address, parseEther('100'))
      // split 100 DAI
      await split.split(token.address, parseEther('100'))
      // check values
      expect(await token.balanceOf(accountOne.address))
        .to.eq(parseToken('90'))
      expect(await token.balanceOf(accountTwo.address))
        .to.eq(parseToken('10'))
      // await expect(registry.initialize(trustToken.address)).to.be.revertedWith('Already initialized')
    })
  })
})