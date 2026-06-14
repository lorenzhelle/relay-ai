import { loadOrCreateChannelId, generateCode } from "./src/config.js";
import { registerPairingCode } from "./src/supabase.js";
import { subscribeToCaptures, sendToIos } from "./src/realtime.js";
import { AgentSdkChannel } from "./src/input-channel.js";
import { runAgentLoop } from "./src/agent.js";

const channelId = loadOrCreateChannelId();
const pairingCode = generateCode();

const channel = new AgentSdkChannel();

await registerPairingCode(channelId, pairingCode);
subscribeToCaptures(channelId, channel);

console.error(`[relay-agent] ready · pairing: ${pairingCode}`);

await runAgentLoop({ channel, sendToIos });
