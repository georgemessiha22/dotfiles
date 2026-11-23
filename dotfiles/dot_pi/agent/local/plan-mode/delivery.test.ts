import assert from "node:assert/strict";
import { deliveriesForPlanChoice } from "./utils.ts";

/** Mirrors pi-agent-core PendingMessageQueue in one-at-a-time mode. */
function firstFollowUp(texts: string[]): string | undefined {
	return texts[0];
}

const notes = "comments on small holes\n- both achievements need user_subscribed";
const steps = "1. ☐ Redraw §4.1";

const refine = deliveriesForPlanChoice("Refine the plan", {
	planSteps: steps,
	refinement: notes,
});
const refineFollowUps = refine.filter((item) => item.kind === "followUp").map((item) => item.text);
assert.equal(
	refineFollowUps.length,
	1,
	"followUpMode one-at-a-time delivers only the first follow-up, so refine must not queue the plan card ahead of the notes",
);
const delivered = firstFollowUp(refineFollowUps);
assert.ok(delivered?.includes(notes), "the editor text must be in the message the agent actually receives");
assert.match(delivered ?? "", /Do not execute/);
assert.equal(refine.some((item) => item.kind === "custom"), false);

const empty = deliveriesForPlanChoice("Refine the plan", { planSteps: steps, refinement: "  " });
assert.deepEqual(empty, []);

const execute = deliveriesForPlanChoice("Execute the plan (track progress)", {
	planSteps: steps,
	executeMessage: "Execute the plan.\n\nRemaining steps:\n1. Redraw §4.1",
});
const executeFollowUps = execute.filter((item) => item.kind === "followUp");
assert.equal(executeFollowUps.length, 1);
assert.match(executeFollowUps[0]?.text ?? "", /Execute the plan/);
assert.equal(execute.some((item) => item.kind === "custom"), false);

assert.deepEqual(deliveriesForPlanChoice("Stay in plan mode", { planSteps: steps }), []);

console.log("delivery.test.ts ok");
