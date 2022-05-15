/** @format */

// scripts/deploy.js
const PROXY = 'deployed address of MNFT'
async function main() {
  const Cntrct = await ethers.getContractFactory('MNFT1')
  await upgrades.upgradeProxy(PROXY, Cntrct)
  console.log('Contract upgraded:')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
