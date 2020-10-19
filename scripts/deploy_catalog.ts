/**
 * ts-node scripts/deploy_catalog.ts "{private_key}" "{network}"
 */
import { ethers, providers, utils } from 'ethers'
import { MockCatalogFactory } from '../build/types/MockCatalogFactory'
import { MockDaiFactory } from '../build/types/MockDaiFactory'

const parseEther = (value: string) => utils.parseEther(value)

async function deployCatalog () {
  const txnArgs = { gasLimit: 4_500_000, gasPrice: 5_000_000_000 }
  const provider = new providers.InfuraProvider(process.argv[3], '81447a33c1cd4eb09efb1e8c388fb28e')
  const wallet = new ethers.Wallet(process.argv[2], provider)

  const dai = await (await new MockDaiFactory(wallet).deploy(txnArgs)).deployed()
  const catalog = await (await new MockCatalogFactory(wallet).deploy(txnArgs)).deployed()

  console.log('catalog address: ', catalog.address)
  console.log('mock dai address: ', dai.address)

  await catalog.setDai(dai.address)
  console.log('mock dai address set')

  await dai.mint(wallet.address, parseEther('1000'))
  console.log('minted 1000 dai')
}

deployCatalog().catch(console.error)
