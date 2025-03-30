// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SnekModule = buildModule("SnekModule", (m) => {
  const snek = m.contract("SnakeEggNFT", [],{});

  return { snek };
});

export default SnekModule;
