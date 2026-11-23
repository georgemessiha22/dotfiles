/**
 * Print Pi's xAI OAuth access token as JSON on stdout.
 * Refreshes through Pi's AuthStorage lock when the stored token is near expiry.
 * Never log the token. Errors go to stderr only.
 */
import { AuthStorage } from "/usr/lib/node_modules/pi/packages/coding-agent/dist/core/auth-storage.js";
import { xaiOAuth } from "/usr/lib/node_modules/pi/packages/ai/dist/auth/oauth/xai.js";

const MINIMUM_VALIDITY_MS = 5 * 60 * 1000;

const storage = AuthStorage.create();
const current = await storage.read("xai");
if (!current || current.type !== "oauth" || !current.access || !current.refresh) {
	console.error("Pi has no xAI OAuth login. Run /login in Pi and choose xAI.");
	process.exit(2);
}

const needsRefresh = (credential) =>
	!credential || credential.type !== "oauth" || Date.now() + MINIMUM_VALIDITY_MS >= credential.expires;

let credential = current;
if (needsRefresh(credential)) {
	credential = await storage.modify("xai", async (stored) => {
		if (!needsRefresh(stored)) return undefined;
		if (!stored || stored.type !== "oauth") {
			throw new Error("xAI OAuth credential disappeared during refresh");
		}
		return xaiOAuth.refresh(stored);
	});
}

if (!credential || credential.type !== "oauth" || !credential.access) {
	console.error("Failed to resolve Pi xAI OAuth access token");
	process.exit(1);
}

process.stdout.write(
	JSON.stringify({
		expires: credential.expires,
	}) + "\n",
);
// Token on line 2 so a truncated log of line 1 does not include it.
process.stdout.write(credential.access);
