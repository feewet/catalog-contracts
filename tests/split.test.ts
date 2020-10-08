import { expect } from 'chai'
import { utils, constants, Wallet, } from 'ethers'
import { loadFixture, MockProvider } from 'ethereum-waffle'
import { MockDai } from '../build/types/MockDai'
import { MockDaiFactory } from '../build/types/MockDaiFactory'
import { Split } from '../build/types/Split'
import { SplitFactory } from '../build/types/SplitFactory'

const parseEther = (value: string) => utils.parseEther(value)

describe('Split Contract', () => {
  let owner: Wallet
  let accountOne: Wallet
  let accountTwo: Wallet
  let token: MockDai
  let split: Split
  let initialSupply: utils.BigNumber

  beforeEach(async () => {
    initialSupply = parseEther('1000')
    // get mock provider
    const provider = new MockProvider()
    // get mock wallets
    const [owner, accountOne, accountTwo] = provider.getWallets()
    // deploy token contract using factory
    token = await new MockDaiFactory(owner).deploy()

    // mint 1000 tokens to owners
    await token.mint(owner.address, '90000000000000000000')
    // deploy split contract with paramaters
    split = await new SplitFactory(owner).deploy(
      accountOne.address, accountTwo.address, '100000000000000000000')
  })

  describe('split', () => {
    it('split between two accounts', async () => {
      let account = token.connect(owner)
      await split.split(token.address, parseEther('100'))
      await expect(token.balanceOf(accountOne.address)).to.eq(parseEther('90'))
    })
  })
})