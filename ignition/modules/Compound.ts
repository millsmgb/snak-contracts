// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CompoundModule = buildModule("CompoundModule", (m) => {
  const compound = m.contract("CompoundingStakableERC20Token", ["Snak", "SNAK", 1000000, 10000],{});

  return { compound };
});

export default CompoundModule;
