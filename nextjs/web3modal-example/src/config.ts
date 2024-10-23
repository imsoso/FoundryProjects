// src/config.ts
import { createWeb3Modal, defaultWagmiConfig } from "@web3modal/wagmi";
import { mainnet, arbitrum } from "viem/chains";
import { reconnect } from "@wagmi/core";

const projectId = "5929872502ea934675cf06383d4a031d"; // 替换为你的项目 ID

const metadata = {
  name: "Web3Modal",
  description: "Web3Modal Example",
  url: "https://foundry-projects.vercel.app/", // 这里的origin必须与你的域名和子域名匹配
  icons: ["https://avatars.githubusercontent.com/u/37784886"],
};

const chains = [mainnet, arbitrum] as const;

export const config = defaultWagmiConfig({
  chains,
  projectId,
  metadata,
});
reconnect(config);

export const modal = createWeb3Modal({
  wagmiConfig: config,
  projectId,
});
